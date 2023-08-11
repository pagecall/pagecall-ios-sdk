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
    @Binding var isShowingRoomView: Bool

    private let roomId: String
    private let accessToken: String
    private let mode: PagecallMode
    private let queryItems: [URLQueryItem]?

    @State private var isLoading = true
    @State private var isSendingMessage = false
    @State private var newMessage: String?

    private let pagecallWebView = PagecallWebView()
    @State private var pagecallWebViewDelegate: PagecallWebViewDelegate?

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?, isShowingRoomView: Binding<Bool>) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.mode = mode
        self.queryItems = queryItems
        self._isShowingRoomView = isShowingRoomView

        UINavigationBar.appearance().barTintColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().backgroundColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().tintColor = .white
    }

    private var backButton: some View {
        Button(action: {
            isShowingRoomView = false
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

                UIViewRenderer(view: pagecallWebView)

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
                            pagecallWebView.sendMessage(message: messageToSend, completionHandler: nil)
                        }
                        self.isSendingMessage = false
                    })
                }

                if isLoading {
                    Loading()
                }
            }
        }
        .onAppear {
            pagecallWebViewDelegate = PagecallWebViewDelegate(
                onLoad: {
                    self.isLoading = false
                },
                onTerminate: { _ in
                    self.isLoading = false
                },
                onReceive: { message in
                    self.newMessage = message
                })

            pagecallWebView.delegate = pagecallWebViewDelegate

            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems ?? [])
        }
        .navigationBarHidden(isLoading)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: sendMessageButton)
    }
}

struct RoomView_Previews: PreviewProvider {
    @State static var isShowingRoomView = true
    static var previews: some View {
        if #available(iOS 15.0, *) {
            RoomView(roomId: "d", accessToken: "d", mode: .replay, queryItems: nil, isShowingRoomView: $isShowingRoomView)
        } else {
            // Fallback on earlier versions
        }
    }
}
