import CarPlay
import Combine
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?
    private var nowPlayingTemplate: CPNowPlayingTemplate?
    private var cancellables = Set<AnyCancellable>()

    private let library = LibraryService.shared
    private let player = PlayerService.shared

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeLibraryTemplate(), animated: true, completion: nil)
        observePlayer()
        player.onChapterChange = { [weak self] _, _ in
            self?.presentNowPlayingIfNeeded()
        }
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        nowPlayingTemplate = nil
        cancellables.removeAll()
    }

    private func makeLibraryTemplate() -> CPListTemplate {
        let items: [CPListItem] = library.books.map { book in
            let item = CPListItem(text: book.title,
                                  detailText: "\(book.author) · \(book.totalDurationMinutes) min")
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                self?.showChapters(for: book)
                completion()
            }
            return item
        }
        let section = CPListSection(items: items)
        return CPListTemplate(title: "DrivePod", sections: [section])
    }

    private func showChapters(for book: Book) {
        let items: [CPListItem] = book.chapters.map { chapter in
            let item = CPListItem(text: "\(chapter.number). \(chapter.title)",
                                  detailText: "\(chapter.estimatedDurationMinutes) min · \(chapter.keyTakeaway)")
            item.handler = { [weak self] _, completion in
                self?.player.play(book: book, chapter: chapter)
                self?.presentNowPlayingIfNeeded()
                completion()
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: book.title, sections: [section])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func presentNowPlayingIfNeeded() {
        guard interfaceController != nil else { return }
        if nowPlayingTemplate == nil {
            let template = CPNowPlayingTemplate.shared
            template.add(self)
            nowPlayingTemplate = template
        }
        guard let nowPlaying = nowPlayingTemplate else { return }
        if interfaceController?.topTemplate !== nowPlaying {
            interfaceController?.pushTemplate(nowPlaying, animated: true, completion: nil)
        }
    }

    private func observePlayer() {
        player.$isPlaying
            .sink { [weak self] _ in self?.refreshNowPlayingButtons() }
            .store(in: &cancellables)
    }

    private func refreshNowPlayingButtons() {
        guard let nowPlaying = nowPlayingTemplate else { return }

        let playPause = CPNowPlayingPlayPauseButton { [weak self] _ in
            self?.player.togglePlayPause()
        }
        let next = CPNowPlayingNextTrackButton { [weak self] _ in
            self?.player.skipToNextChapter()
        }
        let previous = CPNowPlayingPreviousTrackButton { [weak self] _ in
            self?.player.skipToPreviousChapter()
        }
        nowPlaying.updateNowPlayingButtons([previous, playPause, next])
    }
}

extension CarPlaySceneDelegate: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
}
