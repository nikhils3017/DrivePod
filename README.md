# DrivePod

A Headway-style book-summary app focused on **CarPlay**. Drivers can browse a
library of books and listen to chapter-by-chapter summaries through their car
stereo. Summaries are produced by Claude from the original PDF and preserve the
book's chapter structure.

## How it works

```
   ┌────────────────┐    ┌────────────────────┐    ┌──────────────────────────┐
   │  Source PDF    │ →  │  tools/            │ →  │  DrivePod/Resources/     │
   │  (the book)    │    │  pdf_to_summary.py │    │  Books/<slug>.json       │
   └────────────────┘    │  (Claude)          │    └────────────┬─────────────┘
                         └────────────────────┘                 │
                                                                ▼
                                              ┌─────────────────────────────────┐
                                              │  iOS app (SwiftUI)              │
                                              │  ├── Library / Book Detail      │
                                              │  ├── AVSpeechSynthesizer player │
                                              │  └── CarPlay scene (audio app)  │
                                              └─────────────────────────────────┘
```

The Python tool ingests a PDF, asks Claude (with adaptive thinking and a strict
JSON schema) for a per-chapter summary, and writes the file the iOS app reads.
The iOS app loads bundled JSON books, displays a Headway-like library, and
exposes the same content to CarPlay through `CPListTemplate` and
`CPNowPlayingTemplate`. Playback uses `AVSpeechSynthesizer` so the app works
end-to-end without pre-recorded audio.

## Repo layout

```
DrivePod/
├── DrivePodApp.swift         # SwiftUI @main entry point (iPhone app)
├── SceneDelegate.swift       # Default UIWindowScene delegate
├── Info.plist                # Declares both the iPhone scene and CarPlay scene
├── DrivePod.entitlements     # com.apple.developer.carplay-audio
├── Models/
│   └── Book.swift            # Book + Chapter codable models
├── Services/
│   ├── LibraryService.swift  # Loads bundled book JSONs
│   └── PlayerService.swift   # AVSpeechSynthesizer + MPNowPlayingInfoCenter
├── Views/
│   ├── LibraryView.swift     # Grid of books + mini player
│   └── BookDetailView.swift  # Chapter list + play controls
├── CarPlay/
│   └── CarPlaySceneDelegate.swift   # CPListTemplate → CPNowPlayingTemplate
└── Resources/
    └── Books/                # Drop summary JSONs here (bundled into the app)

tools/
├── pdf_to_summary.py         # PDF → structured chapter summaries via Claude
└── requirements.txt

sample_books/
└── atomic-habits.json        # Example output of the pipeline
```

## Running the iOS app

The Swift sources are arranged so they drop into a fresh Xcode iOS app target.

1. **Create the project.** In Xcode, *File → New → Project → iOS App*.
   Use SwiftUI for the interface, set the deployment target to **iOS 16+**.
2. **Replace the template sources** with everything under `DrivePod/`. Add the
   `Models/`, `Services/`, `Views/`, `CarPlay/`, and `Resources/` folders as
   *Folder References* (blue) so the bundled JSON keeps its directory.
3. **Use the supplied `Info.plist` and `DrivePod.entitlements`** (set them in
   Build Settings → Packaging and Signing & Capabilities).
4. **Add the CarPlay Audio capability.** *Signing & Capabilities → + Capability
   → CarPlay → check "CarPlay Audio".* Apple gates this behind the
   `com.apple.developer.carplay-audio` entitlement, which requires an
   approved request through your Apple developer account.
5. **Add Background Mode "Audio, AirPlay, and Picture in Picture"** so playback
   continues when the screen locks (already set in `Info.plist`).
6. Build and run on a device or simulator. Without books in `Resources/Books/`,
   the app falls back to a built-in *Atomic Habits* summary so you can verify
   playback immediately.

### Testing CarPlay

Use Xcode's **CarPlay simulator**: while the app is running on the iOS
simulator, choose *I/O → External Displays → CarPlay* (or the equivalent menu
in your Xcode version). The library list appears as a `CPListTemplate`, taps
on a chapter start playback, and the now-playing screen shows transport
controls wired through `MPRemoteCommandCenter`.

## Generating summaries from PDFs

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r tools/requirements.txt
export ANTHROPIC_API_KEY=sk-...

python tools/pdf_to_summary.py path/to/book.pdf \
    --book-id atomic-habits \
    --title "Atomic Habits" \
    --author "James Clear" \
    --category "Self-Improvement" \
    --emoji "⚛️" \
    --output DrivePod/Resources/Books/atomic-habits.json
```

What the tool does:

- Sends the PDF as a `document` content block to Claude Opus 4.7.
- Uses adaptive thinking and `effort: "high"` so the model can plan around the
  book's structure before drafting.
- Constrains the response with a strict JSON schema that mirrors
  `Book` / `Chapter` in the iOS app, so the output drops into
  `DrivePod/Resources/Books/` without post-processing.
- Streams the response (`max_tokens: 64000`) to avoid SDK timeouts on long
  books.

The schema-driven prompt instructs Claude to detect the book's real chapters,
skip front and back matter, keep each summary 4–7 sentences, and compute
duration from a 150 wpm reading rate.

## Notes & limitations

- Cover art is rendered as an emoji over a gradient. Swap in real artwork by
  bundling an asset catalog and changing `BookCardView`.
- Summaries are spoken via `AVSpeechSynthesizer`. To ship a polished product,
  pre-render audio (e.g. ElevenLabs or AVSpeech offline) and replace
  `PlayerService` with `AVAudioPlayer` / `AVPlayer`.
- The `com.apple.developer.carplay-audio` entitlement requires Apple approval
  before CarPlay works on physical hardware. The Xcode CarPlay simulator works
  without it.
- Respect copyright. Only summarize PDFs you have the right to summarize.
