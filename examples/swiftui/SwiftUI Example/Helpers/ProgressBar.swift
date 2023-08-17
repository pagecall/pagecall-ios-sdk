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
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(red: 0.82, green: 0.84, blue: 0.86))
                    .frame(height: 2)
                    .alignmentGuide(VerticalAlignment.center) { $0[.bottom] }

                let xOffset = min(geo.size.width, geo.size.width * progress)
                VStack(alignment: .trailing) {
                    Image("Pencil")
                        .resizable()
                        .frame(width: 56, height: 58)
                        .offset(x: -10, y: 5)
                        .alignmentGuide(HorizontalAlignment.trailing) { $0[.leading] }

                    Rectangle()
                        .fill(barColor)
                        .frame(height: 2)
                }
                .offset(x: 30) //necessary to match alignment because of the image size
                .frame(width: xOffset)
                .animation(.linear, value: progress)
                .alignmentGuide(VerticalAlignment.center) { $0[.bottom] }
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
