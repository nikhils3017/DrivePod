import SwiftUI

struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var player: PlayerService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Button(action: { player.play(book: book, chapter: book.chapters[0]) }) {
                    Label("Play summary", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Text("Chapters")
                    .font(.title2.bold())

                ForEach(book.chapters) { chapter in
                    ChapterRow(book: book, chapter: chapter)
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.indigo, .purple],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                    Text(book.coverEmoji).font(.system(size: 72))
                }
                .frame(width: 140, height: 200)

                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title).font(.title2.bold())
                    Text(book.author).font(.headline).foregroundStyle(.secondary)
                    Text(book.category)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.indigo.opacity(0.15), in: Capsule())
                    Text("\(book.totalChapters) chapters · \(book.totalDurationMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            Text(book.summaryTagline)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

struct ChapterRow: View {
    let book: Book
    let chapter: Chapter
    @EnvironmentObject var player: PlayerService

    private var isCurrent: Bool { player.currentChapter?.id == chapter.id }

    var body: some View {
        Button(action: { player.play(book: book, chapter: chapter) }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.indigo : Color.secondary.opacity(0.2))
                        .frame(width: 38, height: 38)
                    if isCurrent && player.isPlaying {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                    } else {
                        Text("\(chapter.number)")
                            .font(.headline)
                            .foregroundStyle(isCurrent ? .white : .primary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.title).font(.subheadline.bold())
                    Text(chapter.keyTakeaway)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("\(chapter.estimatedDurationMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "play.circle")
                    .foregroundStyle(.indigo)
            }
            .padding(12)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
