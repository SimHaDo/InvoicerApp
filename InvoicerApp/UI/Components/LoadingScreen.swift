import SwiftUI

struct LoadingScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var textOpacity: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color.black,
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.8)
                ] : [
                    Color.white,
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            // Animated background particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .frame(width: CGFloat.random(in: 20...60))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: pulseScale
                    )
            }
            
            VStack(spacing: 60) {
                Spacer()
                
                // Logo with progressive animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: colorScheme == .dark ? [
                                    Color.white.opacity(0.2 * glowIntensity),
                                    Color.white.opacity(0.1 * glowIntensity),
                                    Color.clear
                                ] : [
                                    Color.black.opacity(0.1 * glowIntensity),
                                    Color.black.opacity(0.05 * glowIntensity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                    
                    // Main logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 200)
                        .scaleEffect(logoScale * breatheScale)
                        .opacity(logoOpacity)
                        .shadow(
                            color: colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2), 
                            radius: 20, x: 0, y: 0
                        )
                        .overlay(
                            // Shimmer effect on logo
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: colorScheme == .dark ? [
                                            Color.clear,
                                            Color.white.opacity(0.6),
                                            Color.clear
                                        ] : [
                                            Color.clear,
                                            Color.black.opacity(0.4),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 200)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Image("AppLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 320, height: 200)
                                )
                        )
                }
                
                Spacer()
                
                // Elegant loading text
                VStack(spacing: 0) {
                    // Main loading text with calligraphic font
                    Text("Please Wait...")
                        .font(.custom("Snell Roundhand", size: 28))
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                        .opacity(textOpacity)
                        .tracking(1.2)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startProgressiveAnimation()
        }
    }
    
    private func startProgressiveAnimation() {
        // Phase 1: Background fade in
        withAnimation(.easeInOut(duration: 1.2)) {
            backgroundOpacity = 1.0
        }
        
        // Phase 2: Logo entrance (0.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        
        // Phase 3: Glow effect (1.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                glowIntensity = 1.0
            }
        }
        
        // Phase 4: Shimmer effect (2.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 2.5)) {
                shimmerOffset = 200
            }
        }
        
        // Phase 5: Text appears (2.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                textOpacity = 1.0
            }
        }
        
        // Phase 6: Start breathing animation (3.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breatheScale = 1.05
            }
        }
        
        // Start pulse animation for background particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pulseScale = 1.15
        }
    }
}

// MARK: - Preview
struct LoadingScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreen()
    }
}
