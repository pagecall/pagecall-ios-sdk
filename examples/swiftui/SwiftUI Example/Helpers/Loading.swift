//
//  Loading.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import Combine

struct Loading: View {
    let progress: Double

    var body: some View {
        Background {
            ZStack {
                ProgressBar(progress: progress, color: Color(red: 0.07, green: 0.38, blue: 1))
                    .padding(.horizontal, 95)
                    .padding(.bottom, 100)
                    .frame(maxHeight: .infinity, alignment: .top)

                Text("Now Loading... ")
                    .font(
                        Font.custom("Pretendard", size: 14)
                            .weight(.medium)
                    )
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
            }
        }
        .ignoresSafeArea()
    }
}

struct Loading_Previews: PreviewProvider {
    static var previews: some View {
        Loading(progress: 0.25)
    }
}
