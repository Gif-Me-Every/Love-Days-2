import SwiftUI
import WidgetKit
import UserNotifications

struct Memory: Identifiable, Codable, Hashable {
    var id = UUID()
    var filename: String
    var caption: String = ""
    var date: Date = Date()
}
struct LoveNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var date: Date = Date()
}
struct Item: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done = false
}
struct Letter: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var body: String
    var unlock: Date? = nil
}
struct Countdown: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
}

enum Seeds {
    static func items(_ a: [String]) -> [Item] { a.map { Item(text: $0) } }
    static let ideas = items(["Picnic in the park 🧺", "Cook a new recipe together 🍝", "Movie marathon night 🍿", "Stargazing ✨", "Sunset walk 🌅", "Build a blanket fort 🏰", "Try a new restaurant 🍣", "Board game night 🎲", "Take silly photos 📸", "Bake cookies 🍪", "Go on a random road trip 🚗", "Dance in the kitchen 💃"])
    static let coupons = items(["1 free massage 💆", "You pick the movie 🎬", "Breakfast in bed 🥞", "1 free hug, anytime 🤗", "Date night, my treat 💸", "No chores today 🧹"])
    static let bucket = items(["Take a road trip 🚗", "Go to a concert 🎤", "Watch a sunrise together 🌄", "Learn something new together 📚"])
    static let reasons = items(["Your smile 😊", "The way you laugh", "You make me better", "You're my best friend"])
}

struct AppState: Codable {
    var startDate: Date? = nil
    var name1 = ""
    var name2 = ""
    var memories: [Memory] = []
    var notes: [LoveNote] = []
    var ideas = Seeds.ideas
    var coupons = Seeds.coupons
    var bucket = Seeds.bucket
    var reasons = Seeds.reasons
    var songs: [Item] = []
    var letters: [Letter] = []
    var countdowns: [Countdown] = []
    var counters: [String: Int] = [:]
    var notify = false
    var lock = false

    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func g<T: Decodable>(_ k: CodingKeys, _ def: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? def }
        startDate = try? c.decode(Date.self, forKey: .startDate)
        name1 = g(.name1, ""); name2 = g(.name2, "")
        memories = g(.memories, []); notes = g(.notes, [])
        ideas = g(.ideas, Seeds.ideas); coupons = g(.coupons, Seeds.coupons)
        bucket = g(.bucket, Seeds.bucket); reasons = g(.reasons, Seeds.reasons)
        songs = g(.songs, []); letters = g(.letters, []); countdowns = g(.countdowns, [])
        counters = g(.counters, [:]); notify = g(.notify, false); lock = g(.lock, false)
    }
}

final class LoveStore: ObservableObject {
    @Published var state: AppState { didSet { save() } }
    @Published var locked = false

    static let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let file = dir.appendingPathComponent("state.json")

    init() {
        if let data = try? Data(contentsOf: Self.file),
           let s = try? JSONDecoder().decode(AppState.self, from: data) { state = s } else { state = AppState() }
        locked = state.lock
        sync()
        reschedule()
    }

    func save() {
        if let d = try? JSONEncoder().encode(state) { try? d.write(to: Self.file) }
        sync()
    }

    func sync() {
        let d = Palette.defaults
        if let s = state.startDate { d.set(s.timeIntervalSince1970, forKey: "start") } else { d.removeObject(forKey: "start") }
        d.set(state.name1, forKey: "n1"); d.set(state.name2, forKey: "n2")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reschedule() { Notifier.schedule(state) }

    func addPhoto(_ data: Data) {
        guard let img = UIImage(data: data), let jpg = img.jpegData(compressionQuality: 0.8) else { return }
        let name = UUID().uuidString + ".jpg"
        try? jpg.write(to: Self.dir.appendingPathComponent(name))
        state.memories.insert(Memory(filename: name), at: 0)
    }
    func image(for m: Memory) -> UIImage? { UIImage(contentsOfFile: Self.dir.appendingPathComponent(m.filename).path) }
    func delete(id: UUID) {
        if let m = state.memories.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: Self.dir.appendingPathComponent(m.filename))
            state.memories.removeAll { $0.id == id }
        }
    }
}

enum Notifier {
    static func schedule(_ s: AppState) {
        let c = UNUserNotificationCenter.current()
        c.removeAllPendingNotificationRequests()
        guard s.notify, let start = s.startDate else { return }
        c.requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok else { return }
            let cal = Calendar.current
            let t = Together(start: start)
            func add(_ id: String, _ title: String, _ body: String, _ date: Date) {
                var comps = cal.dateComponents([.year, .month, .day], from: date)
                comps.hour = 9
                guard let fire = cal.date(from: comps), fire > Date() else { return }
                let content = UNMutableNotificationContent()
                content.title = title; content.body = body; content.sound = .default
                c.add(UNNotificationRequest(identifier: id, content: content,
                      trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            }
            for n in 1...30 {
                let d = cal.date(byAdding: .month, value: n, to: cal.startOfDay(for: start)) ?? start
                add("m\(n)", n % 12 == 0 ? "Happy \(n / 12)-year anniversary! 🎉" : "Happy \(n)-month anniversary 💕", "Another month of us ❤️", d)
            }
            for n in [50, 100, 200, 300, 365, 500, 730, 1000, 1500, 2000] {
                add("d\(n)", "\(n) days together! 🥳", "Look how far we've come 💖", t.date(afterDays: n))
            }
            for cd in s.countdowns { add("c\(cd.id)", cd.title, "Today's the day! 🎉", cd.date) }
        }
    }
}

let loveQuotes = [
    "You're my favorite notification. 💌", "Every day with you is my new favorite day.",
    "Home is wherever you are. 🏡", "I love you more than yesterday, less than tomorrow.",
    "You're the best thing that ever happened to me. 💕", "My heart is yours, always.",
    "Life is better with you in it. ✨", "You make ordinary days feel magical.",
    "Thank you for being you. 🌹", "Forever isn't long enough with you. ♾️",
    "You're my person. 🫶", "Still falling for you every single day."
]
var quoteOfTheDay: String {
    let d = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    return loveQuotes[d % loveQuotes.count]
}
