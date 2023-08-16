//
//  PagecallView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI
import PagecallCore

struct RoomView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var isSendingMessage = false
    @State private var visibleMessage: String?
    @State var isLoadingShown = true

    @StateObject private var pagecallWebViewModel: PagecallWebViewModel

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?) {
        self._pagecallWebViewModel = StateObject(wrappedValue: PagecallWebViewModel(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems))

        UINavigationBar.appearance().barTintColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().backgroundColor = UIColor(Color(red: 0.22, green: 0.25, blue: 0.32))
        UINavigationBar.appearance().tintColor = .white
    }

    private var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
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

                UIViewRenderer(view: pagecallWebViewModel.view)

                if let newMessage = visibleMessage {
                    VStack {
                        Spacer()
                        Message(newMessage: newMessage)
                            .padding(.bottom, 24)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.visibleMessage = nil
                        }
                    }
                }

                if isSendingMessage {
                    SendMessage(onReturn: { messageToSend in
                        if let messageToSend = messageToSend {
                            pagecallWebViewModel.sendMessage(messageToSend)
                        }
                        self.isSendingMessage = false
                    })
                }

                if isLoadingShown {
                    Loading(progress: pagecallWebViewModel.state == .loading ? 0 : 1)
                }
            }
        }
        .onChange(of: pagecallWebViewModel.newMessage, perform: { newMessage in
            self.visibleMessage = newMessage
        })
        .onChange(of: pagecallWebViewModel.state) { state in
            switch state {
            case .loading:
                isLoadingShown = true
            case .loaded:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoadingShown = false
                }
            case .terminated:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoadingShown = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: sendMessageButton)
    }
}

struct RoomView_Previews: PreviewProvider {
    @State static var isShowingRoomView = true
    static var previews: some View {
        RoomView(roomId: "temp", accessToken: "temp", mode: .replay, queryItems: nil)
    }
}
