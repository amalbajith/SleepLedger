//
//  HistoryTrendsChart.swift
//  SleepLedger
//
//  Neon-styled line chart for sleep trends
//

import SwiftUI

struct HistoryTrendsChart: View {
    let sessions: [SleepSession]
    
    private var dataPoints: [Double] {
        sessions.reversed().compactMap { $0.durationInHours }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geometry in
                ZStack {
                    // Grid Lines
                    VStack {
                        Divider().background(Color.white.opacity(0.05))
                        Spacer()
                        Divider().background(Color.white.opacity(0.05))
                        Spacer()
                        Divider().background(Color.white.opacity(0.05))
                    }
                    
                    if dataPoints.count > 1 {
                        // The Line and Gradient
                        chartPath(in: geometry.size)
                            .fill(
                                LinearGradient(
                                    colors: [Color.sleepPrimary.opacity(0.3), Color.sleepPrimary.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        chartPath(in: geometry.size, isClosed: false)
                            .stroke(
                                Color.sleepPrimary,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .shadow(color: Color.sleepPrimary.opacity(0.6), radius: 6)
                        
                        // Data Points
                        ForEach(0..<dataPoints.count, id: \.self) { index in
                            let point = getPoint(for: index, in: geometry.size)
                            Circle()
                                .fill(Color.sleepBackground)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .position(point)
                        }
                    } else if dataPoints.count == 1 {
                        // Single point
                        let point = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        Circle()
                            .fill(Color.sleepPrimary)
                            .frame(width: 10, height: 10)
                            .position(point)
                    }
                }
            }
            .frame(height: 140)
            
            // X-Axis Labels
            HStack {
                ForEach(0..<min(sessions.count, 7), id: \.self) { index in
                    let day = sessions.reversed()[index].startTime.formatted(.dateTime.weekday(.abbreviated))
                    Text(day)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func getPoint(for index: Int, in size: CGSize) -> CGPoint {
        let x = CGFloat(index) * (size.width / CGFloat(max(1, dataPoints.count - 1)))
        let maxY = dataPoints.max() ?? 12.0
        let minY = 0.0
        let range = maxY - minY
        let y = size.height - (CGFloat((dataPoints[index] - minY) / range) * size.height)
        return CGPoint(x: x, y: y)
    }
    
    private func chartPath(in size: CGSize, isClosed: Bool = true) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }
        
        let points = (0..<dataPoints.count).map { getPoint(for: $0, in: size) }
        
        path.move(to: points[0])
        
        for i in 1..<points.count {
            let midPoint = CGPoint(x: (points[i-1].x + points[i].x) / 2, y: (points[i-1].y + points[i].y) / 2)
            path.addQuadCurve(to: midPoint, control: points[i-1])
            path.addLine(to: points[i])
        }
        
        if isClosed {
            path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
            path.addLine(to: CGPoint(x: points.first!.x, y: size.height))
            path.closeSubpath()
        }
        
        return path
    }
}
