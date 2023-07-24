//
//  EnterButton.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import SwiftUI

struct EnterButton: View {
    var body: some View {
        Button(action: {

        }) {
            Text("Enter Room")
                .font(Font.custom("Pretendard", size: 14).weight(.medium))
                .foregroundColor(Color(red: 0.98, green: 0.98, blue: 0.98))
                .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.07, green: 0.38, blue: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.07, green: 0.38, blue: 1), lineWidth: 1)
                )
        )
    }
}

struct EnterButton_Previews: PreviewProvider {
    static var previews: some View {
        EnterButton()
    }
}
