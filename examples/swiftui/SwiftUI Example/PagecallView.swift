//
//  PagecallView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import PagecallCore

@available(iOS 15.0, *)
struct PagecallView: View {
    @Binding var isShowingPagecallView: Bool

    let roomId: String
    let accessToken: String
    let mode: PagecallMode
    let queryItems: [URLQueryItem]?

    @StateObject private var pagecallWebView = PagecallWebView()
    @StateObject private var pagecallManager = PagecallManager()

    @State private var isLoading = true
    @State private var isSendingMessage = false
    @State private var message = ""
    @State private var newMessage = ""

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

    private var sendMessageButton: some View {
        Button(action: {
            isSendingMessage = true
        }) {
            Text("sendMessage")
                .font(
                    Font.custom("Pretendard", size: 14)
                    .weight(.medium)
                )
                .foregroundColor(.white)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                GeometryReader { geo in
                    Color(red: 0.22, green: 0.25, blue: 0.32)
                        .frame(height: geo.safeAreaInsets.top, alignment: .top)
                        .ignoresSafeArea()
                }

                Pagecall(
                    pagecallWebView: pagecallWebView,
                    roomId: roomId,
                    accessToken: accessToken,
                    queryItems: queryItems,
                    mode: mode
                )

                VStack {
                    Spacer()
                    Message(newMessage: $newMessage)
                        .padding(.bottom, 24)
                }

                SendMessage(sendMessage: pagecallWebView.sendMessage, isSendingMessage: $isSendingMessage)

                Loading(isLoading: $isLoading)
            }
        }
        .navigationBarHidden(isLoading)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: sendMessageButton)
        .onAppear {
            if #available(iOS 16.4, *) {
                pagecallWebView.isInspectable = true
            }
            pagecallWebView.delegate = pagecallManager

            pagecallManager.setHandlers(
                onLoad: { () in
                    self.isLoading = false
                },
                onTerminate: {_ in
                    self.isLoading = false
                },
                onReceive: { receivedMessage in
                    self.newMessage = receivedMessage
                }
            )
        }
    }
}

struct PagecallView_Previews: PreviewProvider {
    @State static var isShowingPagecallView = true
    static var previews: some View {
        if #available(iOS 15.0, *) {
            PagecallView(roomId: "d", accessToken: "d", mode: .replay, queryItems: nil, isShowingPagecallView: $isShowingPagecallView)
        } else {
            // Fallback on earlier versions
        }
    }
}
