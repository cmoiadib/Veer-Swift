import SwiftUI

struct TokenCard: View {
    let token: Token
    
    var body: some View {
        HStack(spacing: 16) {
            // Token Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                
                Image(systemName: token.typeIcon)
                    .font(.title2)
                    .foregroundStyle(token.typeColor)
            }
            
            // Token Info
            VStack(alignment: .leading, spacing: 4) {
                Text(token.tokenName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let description = token.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Text(token.earnedDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Token Value
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(token.displayValue)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(token.typeColor)
                
                Text(token.tokenType.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct TokenSummaryCard: View {
    let totalValue: Double
    let tokenCount: Int
    
    private var displayValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: totalValue)) ?? "0"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Tokens")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(tokenCount) tokens earned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "star.circle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
            }
            
            // Total Value Display
            HStack {
                Text(displayValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text("Active")
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

struct TokenTypeSection: View {
    let title: String
    let tokens: [Token]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(tokens.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            // Tokens List
            LazyVStack(spacing: 8) {
                ForEach(tokens) { token in
                    TokenCard(token: token)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            TokenSummaryCard(totalValue: 495.75, tokenCount: 5)
            
            TokenCard(token: Token(
                id: UUID(),
                userId: "sample",
                tokenName: "Style Points",
                tokenValue: 150.00,
                tokenType: "style",
                description: "Earned from outfit combinations",
                earnedDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ))
            
            TokenCard(token: Token(
                id: UUID(),
                userId: "sample",
                tokenName: "Photo Rewards",
                tokenValue: 75.50,
                tokenType: "photo",
                description: "Rewards from photo uploads",
                earnedDate: Date().addingTimeInterval(-3600),
                createdAt: Date(),
                updatedAt: Date()
            ))
        }
        .padding()
    }
    .background(.ultraThinMaterial)
}