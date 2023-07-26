//
//  SendMessage.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/26.
//

import SwiftUI
import PagecallCore

enum FocusField {
  case message
}

struct SendMessage: View {
    private let pagecallWebView: PagecallWebView
    @Binding var isSendingMessage: Bool
    @Binding var message: String
    @Binding var newMessage: String
    
    init( pagecallWebView: PagecallWebView, isSendingMessage: Binding<Bool>, message: Binding<String>, sentMessage: Binding<String>) {
        self.pagecallWebView = pagecallWebView
        self._isSendingMessage = isSendingMessage
        self._message = message
        self._newMessage = sentMessage
    }
    
    var body: some View {
        if isSendingMessage {
            VStack {
                Rectangle()
                    .foregroundColor(.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.07, green: 0.38, blue: 1), lineWidth: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .padding(.horizontal, 16)

                    TextField("", text: $message) {
                        if message != "" {
                            pagecallWebView.sendMessage(message: message) { error in
                                if let error {
                                    message = ""
                                    isSendingMessage = false
                                } else {
                                    message = ""
                                    isSendingMessage = false
                                }
                            }
                        }
                    }
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                        .padding(.horizontal, 16 + 13)
                        .padding(.vertical, 11)
                }
            }
        }
    }
}

struct SendMessage_Previews: PreviewProvider {
    @State static var isSendingMessage = true
    @State static var text = ""
    
    static var previews: some View {
        SendMessage(pagecallWebView: PagecallWebView(), isSendingMessage: $isSendingMessage, message: $text, sentMessage: $text)
    }
}
