//
//  SliderView.swift
//  brokenithm-swiftui
//
//  Created by Owen Cramer on 9/11/24.
//

import SwiftUI

struct SliderView: View {
    @Binding var lanesTouching: [UInt8]
    @Binding var connection: Listener?
    
    var airOn: Bool

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(0 ..< 16) { i in

                    Rectangle()
                        .fill(getColor(con: connection, i: i, laneSplit: false))
                        .foregroundStyle(.ultraThinMaterial)
                        .overlay {
                            if i < 15 {
                                Rectangle()
                                    .fill(getColor(con: connection, i: i, laneSplit: true))
                                    .frame(width: 5)
                                    .padding(.leading, proxy.size.width / 16)
                            }
                        }
                }
            }
        }
    }
    
    private func getColor(con: Listener?, i: Int, laneSplit: Bool) -> Color {
        guard let con = con, con.ledArray.count >= 96 else {
            return .black
        }

        let blockIndex = laneSplit ? (i * 2 + 1) : (i * 2)
        guard blockIndex < 32 else { return .black }
        let base = blockIndex * 3
        let b = Double(con.ledArray[base + 0]) / 255.0
        let r = Double(con.ledArray[base + 1]) / 255.0
        let g = Double(con.ledArray[base + 2]) / 255.0
        return Color(red: r, green: g, blue: b)
    }
    
}

#Preview {
    SliderView(lanesTouching: .constant(Array(repeating: 0, count: 32)), connection: .constant(nil), airOn: true)
}
