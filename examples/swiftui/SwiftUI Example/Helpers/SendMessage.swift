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
    private let onReturn: (String?) -> Void
    @FocusState private var focus: Bool
    @State private var messageToSend: String?

    init(onReturn: @escaping (String?) -> Void) {
        self.onReturn = onReturn
    }

    var body: some View {
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

                TextField("", text: Binding(
                    get: { self.messageToSend ?? "" },
                    set: { self.messageToSend = $0.isEmpty ? nil : $0 }
                )) {
                    onReturn(messageToSend)
                    self.messageToSend = nil
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
            onReturn(nil)
        }
    }

    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

struct SendMessage_Previews: PreviewProvider {
    static var previews: some View {
        SendMessage(onReturn: { messageToSend in print(messageToSend ?? "messageToSend") })
    }
}
