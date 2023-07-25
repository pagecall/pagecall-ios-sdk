//
//  Loading.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import Combine

struct Loading: View {
    @Binding var isLoading: Bool
    @State private var progress = 0.25
    @State private var isViewVisible = true

    var body: some View {
        if isViewVisible {
            Background {
                ZStack {
                    ProgressBar(initialProgress: $progress, color: Color(red: 0.07, green: 0.38, blue: 1))
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
            .onReceive(Just(isLoading)) { loading in
                if !loading {
                    //pencil image animation
                    progress = 1

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isViewVisible = false
                    }
                }
            }

        }
    }
}

struct Loading_Previews: PreviewProvider {
    @State static var isLoading = true

    static var previews: some View {
        Loading(isLoading: $isLoading)
    }
}
