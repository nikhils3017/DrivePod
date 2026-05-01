import Foundation

final class LibraryService: ObservableObject {
    static let shared = LibraryService()

    @Published private(set) var books: [Book] = []

    private init() {
        load()
    }

    func book(id: String) -> Book? {
        books.first { $0.id == id }
    }

    private func load() {
        let decoder = JSONDecoder()
        var loaded: [Book] = []

        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Books") {
            for url in urls {
                if let data = try? Data(contentsOf: url),
                   let book = try? decoder.decode(Book.self, from: data) {
                    loaded.append(book)
                }
            }
        }

        if loaded.isEmpty {
            loaded = LibraryService.fallbackLibrary()
        }

        books = loaded.sorted { $0.title < $1.title }
    }

    private static func fallbackLibrary() -> [Book] {
        [
            Book(
                id: "atomic-habits",
                title: "Atomic Habits",
                author: "James Clear",
                coverEmoji: "⚛️",
                category: "Self-Improvement",
                totalDurationMinutes: 22,
                summaryTagline: "Tiny changes, remarkable results.",
                chapters: [
                    Chapter(
                        id: "ah-1",
                        number: 1,
                        title: "The Surprising Power of Atomic Habits",
                        estimatedDurationMinutes: 4,
                        keyTakeaway: "Habits are the compound interest of self-improvement.",
                        summary: "Small habits make a big difference over time. Improving by just 1 percent each day compounds to a thirty-seven-fold increase in a year. The author argues that we systematically overestimate the impact of single defining moments and underestimate the value of small daily improvements. Habits are like compound interest: their effects multiply as you repeat them. Success is the product of daily habits, not once-in-a-lifetime transformations. Focus on your trajectory, not your current results."
                    ),
                    Chapter(
                        id: "ah-2",
                        number: 2,
                        title: "How Your Habits Shape Your Identity",
                        estimatedDurationMinutes: 4,
                        keyTakeaway: "Lasting change comes from changing who you believe you are.",
                        summary: "There are three layers of behavior change: outcomes, processes, and identity. Most people try to change outcomes first, but lasting change comes from identity-based habits. Instead of saying I want to read more, say I am a reader. Every action you take is a vote for the type of person you wish to become. The most practical way to change who you are is to change what you do, repeatedly. Your habits shape your identity, and your identity shapes your habits."
                    ),
                    Chapter(
                        id: "ah-3",
                        number: 3,
                        title: "The Four Laws of Behavior Change",
                        estimatedDurationMinutes: 5,
                        keyTakeaway: "Make it obvious, attractive, easy, and satisfying.",
                        summary: "Every habit follows a four-step loop: cue, craving, response, and reward. To build a good habit, make the cue obvious, the craving attractive, the response easy, and the reward satisfying. To break a bad habit, invert each law. These laws are a comprehensive framework that you can apply to nearly every habit you wish to change. The chapter sets up the rest of the book, which dives deeply into each law with practical strategies."
                    ),
                    Chapter(
                        id: "ah-4",
                        number: 4,
                        title: "Make It Obvious",
                        estimatedDurationMinutes: 4,
                        keyTakeaway: "Design your environment so good habits are visible and easy to start.",
                        summary: "Behavior is downstream of awareness. Use implementation intentions: I will do X at time Y in location Z. Stack new habits onto existing ones using the formula: After current habit, I will new habit. Design your environment to make cues for good habits obvious and cues for bad habits invisible. Context becomes the cue, so each context should be associated with a single use. You don't have to be the victim of your environment, you can be the architect of it."
                    ),
                    Chapter(
                        id: "ah-5",
                        number: 5,
                        title: "Make It Easy and Stick With It",
                        estimatedDurationMinutes: 5,
                        keyTakeaway: "Reduce friction for good habits and use the two-minute rule.",
                        summary: "The most effective form of learning is practice, not planning. Focus on taking action, not being in motion. The two-minute rule states: when you start a new habit, it should take less than two minutes to do. Master the art of showing up first, then optimize. Use a habit tracker to make progress visible and never miss twice. Motion creates the illusion of progress, but action creates real change. Build systems that make the desired behavior the path of least resistance."
                    )
                ]
            )
        ]
    }
}
