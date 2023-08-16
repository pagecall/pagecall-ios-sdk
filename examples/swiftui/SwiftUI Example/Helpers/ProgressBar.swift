//
//  ProgressBar.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI

struct ProgressBar: View {
    var progress: Double
    private var barColor: Color

    public init(progress: Double, color: Color) {
        self.progress = progress
        self.barColor = color
    }

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                Image("Pencil")
                    .resizable()
                    .frame(width: 56, height: 58)
                    // need -10 offset because of the original image shape
                    .offset(x: min(geo.size.width, geo.size.width * progress) - 10, y: 0)
                    .animation(.linear, value: progress)
                    .padding(.bottom, -5)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.82, green: 0.84, blue: 0.86))
                        .frame(height: 2)

                    Rectangle()
                        .fill(barColor)
                        .frame(width: min(geo.size.width, geo.size.width * progress), height: 2)
                        .animation(.linear, value: progress)
                }
                .cornerRadius(45.0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(progress: 0.25, color: Color(red: 0.07, green: 0.38, blue: 1))
    }
}
