//
//  Message.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/26.
//

import SwiftUI

struct Message: View {
    @Binding var newMessage : String
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15).opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 42)
                .padding(.horizontal, 16)
            
            Text(newMessage)
                .font(
                    Font.custom("Pretendard", size: 14)
                        .weight(.medium)
                )
                .cornerRadius(6)
                .foregroundColor(.white)
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct Message_Previews: PreviewProvider {
    @State static var text = "hi"
    static var previews: some View {
        Message(newMessage: $text)
    }
}
