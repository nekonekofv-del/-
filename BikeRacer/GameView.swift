import SwiftUI

// MARK: - Game State
enum GameState {
    case ready
    case playing
    case gameOver
}

// MARK: - Game View
struct GameView: View {
    @StateObject private var gameManager = GameManager()

    var body: some View {
        ZStack {
            // Background
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

            Text("タップでスタート!")
                .font(.system(size: 20))
                .foregroundColor(.gray)

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
                // Road
                RoadView(gameManager: gameManager, size: geometry.size)

                // Player bike
                PlayerBikeView(gameManager: gameManager, size: geometry.size)

                // Obstacles
                ForEach(gameManager.obstacles) { obstacle in
                    ObstacleView(obstacle: obstacle, gameManager: gameManager, size: geometry.size)
                }

                // Coins
                ForEach(gameManager.coins) { coin in
                    CoinView(coin: coin, gameManager: gameManager, size: geometry.size)
                }

                // HUD
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Score: \(gameManager.score)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Speed: \(Int(gameManager.speed)) km/h")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            gameManager.moveLeft()
                        } else if value.translation.width > 50 {
                            gameManager.moveRight()
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

// MARK: - Road View
struct RoadView: View {
    @ObservedObject var gameManager: GameManager
    let size: CGSize

    var body: some View {
        Canvas { context, size in
            // Road background
            let roadWidth = size.width * 0.6
            let roadX = (size.width - roadWidth) / 2

            context.fill(
                Path(CGRect(x: roadX, y: 0, width: roadWidth, height: size.height)),
                with: .color(.gray)
            )

            // Lane lines
            let laneWidth = roadWidth / 3
            for i in 0..<2 {
                let lineX = roadX + laneWidth * CGFloat(i + 1)
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: lineX, y: 0))
                        path.addLine(to: CGPoint(x: lineX, y: size.height))
                    },
                    with: .color(.white),
                    lineWidth: 4
                )
            }

            // Road side lines
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: roadX, y: 0))
                    path.addLine(to: CGPoint(x: roadX, y: size.height))
                },
                with: .color(.white),
                lineWidth: 6
            )

            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: roadX + roadWidth, y: 0))
                    path.addLine(to: CGPoint(x: roadX + roadWidth, y: size.height))
                },
                with: .color(.white),
                lineWidth: 6
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
        let bikeY = size.height * 0.8

        Text("🚴‍♂️")
            .font(.system(size: 50))
            .position(x: bikeX, y: bikeY)
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
        let coinX = roadX + laneWidth * CGFloat(coin.lane) + laneWidth / 2
        let coinY = size.height * coin.yPosition

        Text("🪙")
            .font(.system(size: 30))
            .position(x: coinX, y: coinY)
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
    @Published var playerLane: Int = 1  // 0, 1, 2
    @Published var obstacles: [Obstacle] = []
    @Published var coins: [Coin] = []
    @Published var score: Int = 0
    @Published var speed: Double = 20.0
    @Published var bestScore: Int = 0

    private var gameTimer: Timer?
    private var obstacleTimer: Timer?
    private var coinTimer: Timer?

    func startGame() {
        gameState = .playing
        playerLane = 1
        obstacles = []
        coins = []
        score = 0
        speed = 20.0

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

    func boost() {
        speed += 5
        if speed > 60 {
            speed = 60
        }
    }

    private func startTimers() {
        // Game loop
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateGame()
        }

        // Spawn obstacles
        obstacleTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            self.spawnObstacle()
        }

        // Spawn coins
        coinTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            self.spawnCoin()
        }
    }

    private func stopTimers() {
        gameTimer?.invalidate()
        obstacleTimer?.invalidate()
        coinTimer?.invalidate()
    }

    private func updateGame() {
        // Move obstacles
        for i in obstacles.indices {
            obstacles[i].yPosition += speed * 0.0002
        }

        // Move coins
        for i in coins.indices {
            coins[i].yPosition += speed * 0.0002
        }

        // Remove off-screen items
        obstacles.removeAll { $0.yPosition > 1.2 }
        coins.removeAll { $0.yPosition > 1.2 }

        // Check collisions
        checkCollisions()

        // Increase score
        score += Int(speed * 0.1)

        // Increase difficulty
        if speed < 60 {
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

    private func checkCollisions() {
        let playerY: Double = 0.8

        // Check obstacle collision
        for obstacle in obstacles {
            if obstacle.lane == playerLane &&
               abs(obstacle.yPosition - playerY) < 0.05 {
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
            }
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
}
