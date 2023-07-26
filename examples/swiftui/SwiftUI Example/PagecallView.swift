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
    let pagecallWebView = PagecallWebView()
    let queryItems: [URLQueryItem]?

    @State private var isLoading = true
    @State private var isShowingLoading = true
    @State private var isSendingMessage = false
    @State private var message = ""
    @State private var newMessage = ""

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?, isShowingPagecallView: Binding<Bool>) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.mode = mode
        self.queryItems = queryItems
        self._isShowingPagecallView = isShowingPagecallView
        if #available(iOS 16.4, *) {
            pagecallWebView.isInspectable = true
        }
        
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
                    mode: mode,
                    onLoad: { () in
                        isLoading = false
                    },
                    onTerminate: { _ in
                        isLoading = false
                    },
                    onReceive: { receivedMessage in
                        newMessage = receivedMessage
                    }
                )
                
                if !isSendingMessage && newMessage != "" {
                    Message(newMessage: $newMessage)
                }
                
                SendMessage(pagecallWebView: pagecallWebView, isSendingMessage: $isSendingMessage, message: $message)

                Loading(isLoading: $isLoading, isShowingLoading: $isShowingLoading)
            }
        }
        .navigationBarHidden(isShowingLoading)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: sendMessageButton)
    }
}

struct PagecallView_Previews: PreviewProvider {
    @State static var isShowingPagecallView = true
    static var previews: some View {
        PagecallView(roomId: "d", accessToken: "d", mode: .replay, queryItems: nil, isShowingPagecallView: $isShowingPagecallView)
    }
}
