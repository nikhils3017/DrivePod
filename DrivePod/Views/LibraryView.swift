import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: LibraryService
    @EnvironmentObject var player: PlayerService

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(library.books) { book in
                        NavigationLink(value: book) {
                            BookCardView(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("DrivePod")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .safeAreaInset(edge: .bottom) {
                if player.currentChapter != nil {
                    MiniPlayerView()
                }
            }
        }
    }
}

struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.indigo, .purple],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                Text(book.coverEmoji)
                    .font(.system(size: 64))
            }
            .frame(height: 180)

            Text(book.title)
                .font(.headline)
                .lineLimit(2)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(book.totalChapters) chapters · \(book.totalDurationMinutes) min")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject var player: PlayerService

    var body: some View {
        HStack(spacing: 12) {
            if let book = player.currentBook {
                Text(book.coverEmoji)
                    .font(.system(size: 32))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentChapter?.title ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(player.currentBook?.title ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: player.togglePlayPause) {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 34))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
