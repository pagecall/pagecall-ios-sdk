//
//  PagecallView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import PagecallCore

@available(iOS 15.0, *)
struct RoomView: View {
    @Binding var isShowingPagecallView: Bool

    private let roomId: String
    private let accessToken: String
    private let mode: PagecallMode
    private let queryItems: [URLQueryItem]?

    @State private var isLoading = true
    @State private var isSendingMessage = false
    @State private var newMessage: String?

    @StateObject private var pagecallWebViewWrapper = PagecallWebViewWrapper()

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

                PagecallBridge(pagecallWebViewWrapper: pagecallWebViewWrapper)
                    .onAppear {
                        pagecallWebViewWrapper.setHandlers(
                            onLoad: {
                                self.isLoading = false
                            },
                            onTerminate: { _ in
                                self.isLoading = false
                            },
                            onReceive: { newMessage in
                                self.newMessage = newMessage
                            }
                        )
                        pagecallWebViewWrapper.enter(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
                    }

                if let newMessage = newMessage {
                    VStack {
                        Spacer()
                        Message(newMessage: newMessage)
                            .padding(.bottom, 24)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.newMessage = nil
                        }
                    }
                }

                if isSendingMessage {
                    SendMessage(onReturn: { messageToSend in
                        if let messageToSend = messageToSend {
                            pagecallWebViewWrapper.sendMessage(messageToSend, nil)
                        }
                        self.isSendingMessage = false
                    })
                }

                if isLoading {
                    Loading()
                }
            }
        }
        .navigationBarHidden(isLoading)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: sendMessageButton)
    }
}

struct RoomView_Previews: PreviewProvider {
    @State static var isShowingPagecallView = true
    static var previews: some View {
        if #available(iOS 15.0, *) {
            RoomView(roomId: "d", accessToken: "d", mode: .replay, queryItems: nil, isShowingPagecallView: $isShowingPagecallView)
        } else {
            // Fallback on earlier versions
        }
    }
}
