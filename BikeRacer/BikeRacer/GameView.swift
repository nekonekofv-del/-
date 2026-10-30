import SwiftUI

// MARK: - Game State
enum GameState {
    case ready
    case playing
    case gameOver
}

// MARK: - Item Type
enum ItemType: String, CaseIterable {
    case speed = "⭐"
    case shield = "🛡️"
    case magnet = "🧲"

    var color: Color {
        switch self {
        case .speed: return .yellow
        case .shield: return .blue
        case .magnet: return .red
        }
    }
}

// MARK: - Game View
struct GameView: View {
    @StateObject private var gameManager = GameManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameManager.gameState {
            case .ready:
                ReadyView(gameManager: gameManager)
            case .playing:
                PlayingView(gameManager: gameManager)
            case .gameOver:
                GameOverView(gameManager: gameManager)
            }
        }
    }
}

// MARK: - Ready View
struct ReadyView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("🚴‍♂️")
                .font(.system(size: 100))

            Text("Bike Racer")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                Text("左右スワイプ: レーン変更")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                Text("上スワイプ: ジャンプ")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                Text("タップ: ブースト")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                gameManager.startGame()
            }) {
                Text("START")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(30)
            }

            Spacer()
        }
    }
}

// MARK: - Playing View
struct PlayingView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with scrolling buildings
                BackgroundView(gameManager: gameManager, size: geometry.size)

                // Road
                RoadView(gameManager: gameManager, size: geometry.size)

                // Player bike with effects
                PlayerBikeView(gameManager: gameManager, size: geometry.size)

                // Obstacles
                ForEach(gameManager.obstacles) { obstacle in
                    ObstacleView(obstacle: obstacle, gameManager: gameManager, size: geometry.size)
                }

                // Coins
                ForEach(gameManager.coins) { coin in
                    CoinView(coin: coin, gameManager: gameManager, size: geometry.size)
                }

                // Items
                ForEach(gameManager.items) { item in
                    ItemView(item: item, gameManager: gameManager, size: geometry.size)
                }

                // Particles
                ForEach(gameManager.particles) { particle in
                    ParticleView(particle: particle, size: geometry.size)
                }

                // HUD
                HUDView(gameManager: gameManager)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        if abs(horizontal) > abs(vertical) {
                            // Horizontal swipe
                            if horizontal < -50 {
                                gameManager.moveLeft()
                            } else if horizontal > 50 {
                                gameManager.moveRight()
                            }
                        } else {
                            // Vertical swipe
                            if vertical < -50 {
                                gameManager.jump()
                            }
                        }
                    }
            )
            .onTapGesture {
                gameManager.boost()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Background View (Scrolling buildings)
struct BackgroundView: View {
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        Canvas { context, size in
            // Sky gradient
            let skyGradient = Gradient(colors: [.black, .purple.opacity(0.3), .black])
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .linearGradient(skyGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height))
            )

            // Buildings
            let buildingWidth: CGFloat = 60
            let buildingSpacing: CGFloat = 20
            let scrollOffset = CGFloat(gameManager.distanceTraveled * 0.3).truncatingRemainder(dividingBy: buildingWidth + buildingSpacing)

            for i in -1..<Int(size.width / (buildingWidth + buildingSpacing)) + 2 {
                let x = CGFloat(i) * (buildingWidth + buildingSpacing) - scrollOffset
                let height = CGFloat.random(in: 100...300)
                let y = size.height - height

                // Building
                context.fill(
                    Path(CGRect(x: x, y: y, width: buildingWidth, height: height)),
                    with: .color(.gray.opacity(0.3))
                )

                // Windows
                for row in 0..<Int(height / 40) {
                    for col in 0..<2 {
                        let windowX = x + 10 + CGFloat(col) * 25
                        let windowY = y + 10 + CGFloat(row) * 40

                        if Bool.random() {
                            context.fill(
                                Path(CGRect(x: windowX, y: windowY, width: 15, height: 20)),
                                with: .color(.yellow.opacity(0.5))
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Road View
struct RoadView: View {
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        Canvas { context, size in
            let roadWidth = size.width * 0.6
            let roadX = (size.width - roadWidth) / 2

            // Road
            context.fill(
                Path(CGRect(x: roadX, y: 0, width: roadWidth, height: size.height)),
                with: .color(.gray)
            )

            // Lane lines (dashed)
            let laneWidth = roadWidth / 3
            let dashHeight: CGFloat = 30
            let gapHeight: CGFloat = 20
            let scrollOffset = CGFloat(gameManager.distanceTraveled * 0.5).truncatingRemainder(dividingBy: dashHeight + gapHeight)

            for i in 0..<2 {
                let lineX = roadX + laneWidth * CGFloat(i + 1)

                var y: CGFloat = -scrollOffset
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: lineX - 2, y: y, width: 4, height: dashHeight)),
                        with: .color(.white)
                    )
                    y += dashHeight + gapHeight
                }
            }

            // Road side lines
            context.fill(
                Path(CGRect(x: roadX - 3, y: 0, width: 6, height: size.height)),
                with: .color(.white)
            )

            context.fill(
                Path(CGRect(x: roadX + roadWidth - 3, y: 0, width: 6, height: size.height)),
                with: .color(.white)
            )
        }
    }
}

// MARK: - Player Bike View
struct PlayerBikeView: View {
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        let roadWidth = size.width * 0.6
        let laneWidth = roadWidth / 3
        let roadX = (size.width - roadWidth) / 2
        let bikeX = roadX + laneWidth * CGFloat(gameManager.playerLane) + laneWidth / 2
        let bikeY = size.height * 0.8 - gameManager.jumpHeight

        ZStack {
            // Shield effect
            if gameManager.hasShield {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .position(x: bikeX, y: bikeY)
            }

            // Speed lines
            if gameManager.isBoosting {
                ForEach(0..<3) { i in
                    Rectangle()
                        .fill(Color.yellow.opacity(0.5))
                        .frame(width: 4, height: 30)
                        .position(x: bikeX - 20 + CGFloat(i) * 20, y: bikeY + 40)
                }
            }

            // Bike
            Text("🚴‍♂️")
                .font(.system(size: 50))
                .position(x: bikeX, y: bikeY)
                .rotationEffect(.degrees(gameManager.isJumping ? -10 : 0))
        }
    }
}

// MARK: - Obstacle View
struct ObstacleView: View {
    let obstacle: Obstacle
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        let roadWidth = size.width * 0.6
        let laneWidth = roadWidth / 3
        let roadX = (size.width - roadWidth) / 2
        let obstacleX = roadX + laneWidth * CGFloat(obstacle.lane) + laneWidth / 2
        let obstacleY = size.height * obstacle.yPosition

        Text(obstacle.type.emoji)
            .font(.system(size: 40))
            .position(x: obstacleX, y: obstacleY)
    }
}

// MARK: - Coin View
struct CoinView: View {
    let coin: Coin
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        let roadWidth = size.width * 0.6
        let laneWidth = roadWidth / 3
        let roadX = (size.width - roadWidth) / 2

        // Magnet attraction
        let coinX: CGFloat
        if gameManager.hasMagnet {
            let bikeX = roadX + laneWidth * CGFloat(gameManager.playerLane) + laneWidth / 2
            coinX = coin.xPosition.map { $0 } ?? (roadX + laneWidth * CGFloat(coin.lane) + laneWidth / 2)
        } else {
            coinX = roadX + laneWidth * CGFloat(coin.lane) + laneWidth / 2
        }

        let coinY = size.height * coin.yPosition

        Text("🪙")
            .font(.system(size: 30))
            .position(x: coinX, y: coinY)
            .scaleEffect(coin.isCollected ? 1.5 : 1.0)
            .opacity(coin.isCollected ? 0 : 1)
    }
}

// MARK: - Item View
struct ItemView: View {
    let item: Item
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        let roadWidth = size.width * 0.6
        let laneWidth = roadWidth / 3
        let roadX = (size.width - roadWidth) / 2
        let itemX = roadX + laneWidth * CGFloat(item.lane) + laneWidth / 2
        let itemY = size.height * item.yPosition

        Text(item.type.rawValue)
            .font(.system(size: 35))
            .position(x: itemX, y: itemY)
            .background(
                Circle()
                    .fill(item.type.color.opacity(0.3))
                    .frame(width: 50, height: 50)
            )
    }
}

// MARK: - Particle View
struct ParticleView: View {
    let particle: Particle
    let size: CGSize

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .opacity(particle.opacity)
    }
}

// MARK: - HUD View
struct HUDView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Score: \(gameManager.score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Speed: \(Int(gameManager.speed)) km/h")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)

                    // Active items
                    HStack {
                        if gameManager.hasShield {
                            Text("🛡️")
                                .font(.system(size: 20))
                        }
                        if gameManager.hasMagnet {
                            Text("🧲")
                                .font(.system(size: 20))
                        }
                        if gameManager.isBoosting {
                            Text("⭐")
                                .font(.system(size: 20))
                        }
                    }
                }

                Spacer()

                Button(action: {
                    gameManager.pauseGame()
                }) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("💥")
                .font(.system(size: 80))

            Text("Game Over")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.red)

            Text("Score: \(gameManager.score)")
                .font(.system(size: 30))
                .foregroundColor(.white)

            Text("Best: \(gameManager.bestScore)")
                .font(.system(size: 20))
                .foregroundColor(.yellow)

            Spacer()

            Button(action: {
                gameManager.restartGame()
            }) {
                Text("RETRY")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(30)
            }

            Spacer()
        }
    }
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var gameState: GameState = .ready
    @Published var playerLane: Int = 1
    @Published var obstacles: [Obstacle] = []
    @Published var coins: [Coin] = []
    @Published var items: [Item] = []
    @Published var particles: [Particle] = []
    @Published var score: Int = 0
    @Published var speed: Double = 20.0
    @Published var bestScore: Int = 0
    @Published var distanceTraveled: Double = 0

    // Player states
    @Published var isJumping: Bool = false
    @Published var jumpHeight: CGFloat = 0
    @Published var hasShield: Bool = false
    @Published var hasMagnet: Bool = false
    @Published var isBoosting: Bool = false

    private var gameTimer: Timer?
    private var obstacleTimer: Timer?
    private var coinTimer: Timer?
    private var itemTimer: Timer?
    private var jumpTimer: Timer?
    private var shieldTimer: Timer?
    private var magnetTimer: Timer?
    private var boostTimer: Timer?

    func startGame() {
        gameState = .playing
        playerLane = 1
        obstacles = []
        coins = []
        items = []
        particles = []
        score = 0
        speed = 20.0
        distanceTraveled = 0
        isJumping = false
        jumpHeight = 0
        hasShield = false
        hasMagnet = false
        isBoosting = false

        startTimers()
    }

    func pauseGame() {
        stopTimers()
        gameState = .ready
    }

    func restartGame() {
        startGame()
    }

    func moveLeft() {
        if playerLane > 0 {
            playerLane -= 1
        }
    }

    func moveRight() {
        if playerLane < 2 {
            playerLane += 1
        }
    }

    func jump() {
        guard !isJumping else { return }

        isJumping = true

        // Jump animation
        withAnimation(.easeOut(duration: 0.3)) {
            jumpHeight = 100
        }

        jumpTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            withAnimation(.easeIn(duration: 0.3)) {
                self.jumpHeight = 0
            }

            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                self.isJumping = false
            }
        }
    }

    func boost() {
        isBoosting = true
        speed += 10

        boostTimer?.invalidate()
        boostTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            self.isBoosting = false
            self.speed = max(20, self.speed - 10)
        }
    }

    private func startTimers() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateGame()
        }

        obstacleTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            self.spawnObstacle()
        }

        coinTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            self.spawnCoin()
        }

        itemTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.spawnItem()
        }
    }

    private func stopTimers() {
        gameTimer?.invalidate()
        obstacleTimer?.invalidate()
        coinTimer?.invalidate()
        itemTimer?.invalidate()
        jumpTimer?.invalidate()
        shieldTimer?.invalidate()
        magnetTimer?.invalidate()
        boostTimer?.invalidate()
    }

    private func updateGame() {
        let moveSpeed = speed * 0.0002

        // Move obstacles
        for i in obstacles.indices {
            obstacles[i].yPosition += moveSpeed
        }

        // Move coins
        for i in coins.indices {
            coins[i].yPosition += moveSpeed

            // Magnet attraction
            if hasMagnet {
                let playerY: Double = 0.8
                if abs(coins[i].yPosition - playerY) < 0.2 {
                    coins[i].xPosition = getPlayerX()
                }
            }
        }

        // Move items
        for i in items.indices {
            items[i].yPosition += moveSpeed
        }

        // Update particles
        for i in particles.indices.reversed() {
            particles[i].y += particles[i].vy
            particles[i].x += particles[i].vx
            particles[i].opacity -= 0.02

            if particles[i].opacity <= 0 {
                particles.remove(at: i)
            }
        }

        // Remove off-screen items
        obstacles.removeAll { $0.yPosition > 1.2 }
        coins.removeAll { $0.yPosition > 1.2 }
        items.removeAll { $0.yPosition > 1.2 }

        // Check collisions
        checkCollisions()

        // Update score and distance
        score += Int(speed * 0.1)
        distanceTraveled += speed * 0.001

        // Increase difficulty
        if speed < 60 && !isBoosting {
            speed += 0.01
        }
    }

    private func spawnObstacle() {
        let lane = Int.random(in: 0..<3)
        let types: [ObstacleType] = [.car, .bus, .pedestrian]
        let type = types.randomElement()!

        obstacles.append(Obstacle(lane: lane, yPosition: -0.1, type: type))
    }

    private func spawnCoin() {
        let lane = Int.random(in: 0..<3)
        coins.append(Coin(lane: lane, yPosition: -0.1))
    }

    private func spawnItem() {
        let lane = Int.random(in: 0..<3)
        let type = ItemType.allCases.randomElement()!
        items.append(Item(lane: lane, yPosition: -0.1, type: type))
    }

    private func getPlayerX() -> CGFloat {
        // This is a simplified version
        return 0
    }

    private func checkCollisions() {
        let playerY: Double = 0.8

        // Check obstacle collision
        for obstacle in obstacles {
            if obstacle.lane == playerLane &&
               abs(obstacle.yPosition - playerY) < 0.05 {

                // Check if jumping over
                if isJumping && jumpHeight > 50 {
                    continue
                }

                // Check shield
                if hasShield {
                    hasShield = false
                    spawnParticles(at: getPlayerPosition(), color: .blue)
                    continue
                }

                gameOver()
                return
            }
        }

        // Check coin collection
        for i in coins.indices.reversed() {
            if coins[i].lane == playerLane &&
               abs(coins[i].yPosition - playerY) < 0.05 {
                coins.remove(at: i)
                score += 100
                spawnParticles(at: getPlayerPosition(), color: .yellow)
            }
        }

        // Check item collection
        for i in items.indices.reversed() {
            if items[i].lane == playerLane &&
               abs(items[i].yPosition - playerY) < 0.05 {

                activateItem(items[i].type)
                items.remove(at: i)
                spawnParticles(at: getPlayerPosition(), color: items[i].type.color)
            }
        }
    }

    private func activateItem(_ type: ItemType) {
        switch type {
        case .speed:
            boost()
        case .shield:
            hasShield = true
            shieldTimer?.invalidate()
            shieldTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.hasShield = false
            }
        case .magnet:
            hasMagnet = true
            magnetTimer?.invalidate()
            magnetTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.hasMagnet = false
            }
        }
    }

    private func getPlayerPosition() -> CGPoint {
        // Simplified - in real app would calculate actual position
        return CGPoint(x: 200, y: 400)
    }

    private func spawnParticles(at position: CGPoint, color: Color) {
        for _ in 0..<10 {
            particles.append(Particle(
                x: position.x,
                y: position.y,
                vx: CGFloat.random(in: -5...5),
                vy: CGFloat.random(in: -10...0),
                size: CGFloat.random(in: 5...15),
                color: color,
                opacity: 1.0
            ))
        }
    }

    private func gameOver() {
        stopTimers()

        if score > bestScore {
            bestScore = score
        }

        gameState = .gameOver
    }
}

// MARK: - Models
struct Obstacle: Identifiable {
    let id = UUID()
    let lane: Int
    var yPosition: Double
    let type: ObstacleType
}

enum ObstacleType {
    case car, bus, pedestrian

    var emoji: String {
        switch self {
        case .car: return "🚗"
        case .bus: return "🚌"
        case .pedestrian: return "🚶"
        }
    }
}

struct Coin: Identifiable {
    let id = UUID()
    let lane: Int
    var yPosition: Double
    var xPosition: CGFloat? = nil
    var isCollected: Bool = false
}

struct Item: Identifiable {
    let id = UUID()
    let lane: Int
    var yPosition: Double
    let type: ItemType
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}
