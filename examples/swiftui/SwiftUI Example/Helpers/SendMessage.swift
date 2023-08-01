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

@available(iOS 15.0, *)
struct SendMessage: View {
    private let sendMessage: (String, ((Error?) -> Void)?) -> Void
    @Binding var isSendingMessage: Bool
    @Binding var message: String
    @FocusState private var focus: Bool
    
    init(sendMessage: @escaping (String, ((Error?) -> Void)?) -> Void, isSendingMessage: Binding<Bool>, message: Binding<String>) {
        self.sendMessage = sendMessage
        self._isSendingMessage = isSendingMessage
        self._message = message
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
                            sendMessage(message) { error in
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
                    .focused($focus)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .padding(.horizontal, 16 + 13)
                    .padding(.vertical, 11)
                    .onAppear {
                        focus = true
                    }
                }
            }
            .onTapGesture {
                self.endEditing() // dismiss keyboard when touched around
                isSendingMessage = false
            }
        }
    }
    
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

struct SendMessage_Previews: PreviewProvider {
    @State static var isSendingMessage = true
    @State static var text = ""
    
    static var previews: some View {
        if #available(iOS 15.0, *) {
            SendMessage(sendMessage: {_,_ in }, isSendingMessage: $isSendingMessage, message: $text)
        } else {
            // Fallback on earlier versions
        }
    }
}
