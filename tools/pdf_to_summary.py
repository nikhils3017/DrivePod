"""Convert a book PDF into a structured chapter-by-chapter summary JSON.

The output JSON matches the schema consumed by the DrivePod iOS app
(see DrivePod/Models/Book.swift). Drop the resulting file into
DrivePod/Resources/Books/ to make it available in the library and
on CarPlay.

Usage:
    export ANTHROPIC_API_KEY=...
    python tools/pdf_to_summary.py path/to/book.pdf \\
        --book-id atomic-habits \\
        --title "Atomic Habits" \\
        --author "James Clear" \\
        --category "Self-Improvement" \\
        --emoji "⚛️" \\
        --output sample_books/atomic-habits.json
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
from pathlib import Path

import anthropic

MODEL = "claude-opus-4-7"

CHAPTER_SCHEMA = {
    "type": "object",
    "properties": {
        "id": {"type": "string"},
        "number": {"type": "integer"},
        "title": {"type": "string"},
        "estimatedDurationMinutes": {"type": "integer"},
        "keyTakeaway": {"type": "string"},
        "summary": {"type": "string"},
    },
    "required": [
        "id",
        "number",
        "title",
        "estimatedDurationMinutes",
        "keyTakeaway",
        "summary",
    ],
    "additionalProperties": False,
}

BOOK_SCHEMA = {
    "type": "object",
    "properties": {
        "id": {"type": "string"},
        "title": {"type": "string"},
        "author": {"type": "string"},
        "coverEmoji": {"type": "string"},
        "category": {"type": "string"},
        "totalDurationMinutes": {"type": "integer"},
        "summaryTagline": {"type": "string"},
        "chapters": {"type": "array", "items": CHAPTER_SCHEMA},
    },
    "required": [
        "id",
        "title",
        "author",
        "coverEmoji",
        "category",
        "totalDurationMinutes",
        "summaryTagline",
        "chapters",
    ],
    "additionalProperties": False,
}

SYSTEM_PROMPT = """You are an expert non-fiction editor creating Headway-style audio
book summaries for DrivePod, a CarPlay book-summary app.

Your job is to read the attached book PDF and produce a chapter-by-chapter
summary that preserves the structure of the original work.

Guidelines:
- Detect the book's actual chapter structure. Use the table of contents and
  in-body chapter headings; ignore front matter (title page, dedication,
  acknowledgements) and back matter (index, notes) unless the author treats
  them as substantive chapters.
- One summary entry per real chapter. Keep numbering sequential starting at 1.
- Each chapter summary must be 4-7 sentences (roughly 110-180 words). Capture
  the chapter's core argument, the evidence the author uses, and the practical
  takeaway. Do not pad. Do not invent content not in the source.
- keyTakeaway is one short sentence (under 100 chars) that a listener should
  remember after the chapter.
- estimatedDurationMinutes: assume ~150 words per minute when read aloud, and
  round to the nearest minute (minimum 2).
- totalDurationMinutes is the sum of chapter durations.
- summaryTagline: one punchy line capturing the whole book's promise.
- coverEmoji: a single emoji that evokes the book's theme.
- id and chapter ids must be url-safe lowercase slugs (kebab-case).

Return only the JSON object that matches the requested schema. Do not include
preamble, markdown, or explanations.
"""


def encode_pdf(path: Path) -> str:
    return base64.standard_b64encode(path.read_bytes()).decode("utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path, help="Path to the book PDF")
    parser.add_argument("--book-id", required=True, help="Slug used as the book id")
    parser.add_argument("--title", required=True)
    parser.add_argument("--author", required=True)
    parser.add_argument("--category", default="Non-Fiction")
    parser.add_argument("--emoji", default="📘", help="Single emoji used as the cover")
    parser.add_argument(
        "--output",
        type=Path,
        help="Output JSON path (defaults to <book-id>.json next to the PDF)",
    )
    parser.add_argument(
        "--model",
        default=MODEL,
        help=f"Anthropic model to use (default: {MODEL})",
    )
    return parser.parse_args()


def build_user_message(args: argparse.Namespace, pdf_b64: str) -> list:
    instructions = (
        f"Book metadata to use verbatim:\n"
        f"- id: {args.book_id}\n"
        f"- title: {args.title}\n"
        f"- author: {args.author}\n"
        f"- category: {args.category}\n"
        f"- coverEmoji: {args.emoji}\n\n"
        "Now read the attached PDF and emit the structured summary."
    )

    return [
        {
            "type": "document",
            "source": {
                "type": "base64",
                "media_type": "application/pdf",
                "data": pdf_b64,
            },
        },
        {"type": "text", "text": instructions},
    ]


def run(args: argparse.Namespace) -> dict:
    if not args.pdf.exists():
        sys.exit(f"PDF not found: {args.pdf}")

    pdf_b64 = encode_pdf(args.pdf)
    client = anthropic.Anthropic()

    # Stream because output for a long book can exceed the non-streaming
    # timeout window. get_final_message() reassembles the full response.
    with client.messages.stream(
        model=args.model,
        max_tokens=64000,
        thinking={"type": "adaptive"},
        output_config={
            "effort": "high",
            "format": {
                "type": "json_schema",
                "schema": BOOK_SCHEMA,
            },
        },
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": build_user_message(args, pdf_b64)}],
    ) as stream:
        for event in stream:
            if (
                event.type == "content_block_delta"
                and getattr(event.delta, "type", "") == "text_delta"
            ):
                print(event.delta.text, end="", flush=True)
        message = stream.get_final_message()
    print()

    if message.stop_reason == "refusal":
        sys.exit("Claude declined to summarize this PDF.")
    if message.stop_reason == "max_tokens":
        sys.exit("Output was truncated. Re-run with a larger max_tokens or split the PDF.")

    text = next((b.text for b in message.content if b.type == "text"), "")
    if not text:
        sys.exit("Empty response from the model.")

    book = json.loads(text)
    if "id" in book:
        book["id"] = args.book_id
    return book


def main() -> None:
    args = parse_args()
    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("ANTHROPIC_API_KEY is not set.")

    book = run(args)
    output = args.output or args.pdf.with_name(f"{args.book_id}.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(book, indent=2, ensure_ascii=False))
    print(f"\nWrote {output} ({len(book.get('chapters', []))} chapters)")


if __name__ == "__main__":
    main()
