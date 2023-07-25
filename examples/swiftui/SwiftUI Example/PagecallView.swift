//
//  PagecallView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import PagecallCore

struct PagecallView: View {
    @Binding var isShowingPagecallView: Bool

    let roomId: String
    let accessToken: String
    let mode: PagecallMode
    let queryItems: [URLQueryItem]?

    @State private var isLoading = true
    @State private var isShowingLoading = true

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?, isShowingPagecallView: Binding<Bool>) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.mode = mode
        self.queryItems = queryItems
        self._isShowingPagecallView = isShowingPagecallView

        UINavigationBar.appearance().barTintColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().backgroundColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().tintColor = .white
    }

    private var backButton: some View {
        Button(action: {
            isShowingPagecallView = false
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // top view to cover the safe area
                GeometryReader { geo in
                    Color(red: 0.22, green: 0.25, blue: 0.32)
                        .frame(height: geo.safeAreaInsets.top, alignment: .top)
                        .ignoresSafeArea()
                }

                Pagecall(
                    roomId: roomId,
                    accessToken: accessToken,
                    queryItems: queryItems,
                    mode: mode,
                    onLoad: { () in
                        isLoading = false
                    },
                    onTerminate: { _ in
                        isLoading = false
                    }
                )

                Loading(isLoading: $isLoading, isShowingLoading: $isShowingLoading)
            }
        }
        .navigationBarHidden(isShowingLoading)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
    }
}

struct PagecallView_Previews: PreviewProvider {
    @State static var isShowingPagecallView = true
    static var previews: some View {
        PagecallView(roomId: "d", accessToken: "d", mode: .replay, queryItems: nil, isShowingPagecallView: $isShowingPagecallView)
    }
}
