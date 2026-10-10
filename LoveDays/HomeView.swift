import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: LoveStore
    @State private var beat = false
    @State private var showSettings = false
    @State private var burst = 0

    var body: some View {
        let start = store.state.startDate ?? Date()
        let t = Together(start: start)
        let title = (store.state.name1.isEmpty || store.state.name2.isEmpty)
            ? "Our Love Story" : "\(store.state.name1) ❤️ \(store.state.name2)"

        ZStack {
            LoveBackground()
            FloatingHearts()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill").foregroundColor(Palette.accent)
                        }
                    }
                    Text(title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.accent)

                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 250))
                            .foregroundStyle(LinearGradient(colors: [Palette.accent, .red.opacity(0.8)],
                                                            startPoint: .top, endPoint: .bottom))
                            .shadow(color: Palette.accent.opacity(0.5), radius: 14)
                        VStack(spacing: 0) {
                            Text("\(t.days)")
                                .font(.system(size: 62, weight: .heavy, design: .rounded))
                            Text(t.days == 1 ? "day" : "days")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .offset(y: -8)
                    }
                    .scaleEffect(beat ? 1.05 : 0.97)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: beat)
                    .onTapGesture { burst += 1; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }

                    Text("together since \(start.formatted(date: .long, time: .omitted))")
                        .font(.subheadline).foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        chip("\(t.years)", "years")
                        chip("\(t.months)", "months")
                        chip("\(t.dayPart)", "days")
                    }

                    HStack(spacing: 10) {
                        chip("\(t.weeks)", "weeks")
                        chip("\(t.hours)", "hours")
                        chip("\(t.totalMonths)", "total months")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next up: \(t.nextLabel)").font(.headline).foregroundColor(Palette.accent)
                        ProgressView(value: t.progressToNext).tint(Palette.accent)
                        Text(t.daysUntilNext == 0 ? "Today! 🎉" : "in \(t.daysUntilNext) day\(t.daysUntilNext == 1 ? "" : "s")")
                            .font(.subheadline).foregroundColor(.secondary)
                    }.loveCard()

                    if !store.state.memories.isEmpty {
                        let m = store.state.memories[(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % store.state.memories.count]
                        if let img = store.image(for: m) {
                            VStack(spacing: 8) {
                                Text("Memory of the day 📸").font(.headline).foregroundColor(Palette.accent)
                                Image(uiImage: img).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 14))
                                if !m.caption.isEmpty { Text(m.caption).font(.caption) }
                            }.loveCard()
                        }
                    }

                    Text(quoteOfTheDay)
                        .font(.system(.body, design: .serif).italic())
                        .multilineTextAlignment(.center)
                        .loveCard()

                    ShareLink(item: "We've been together \(t.days) days 💕") {
                        Label("Share our days", systemImage: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(Palette.accent, in: Capsule())
                    }
                }
                .padding()
            }
        }
        .overlay { if burst > 0 { BurstOnce().id(burst).allowsHitTesting(false) } }
        .onAppear {
            beat = true
            if t.days > 0 && (t.dayPart == 0 || [50, 100, 200, 365, 500, 1000].contains(t.days)) { burst += 1 }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    func chip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(Palette.accent)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
    }
}
