//
//  LabelAndTextView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import SwiftUI

struct LabelAndTextFieldView: View {
    @Binding var text: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(label).font(
                    Font.custom("Pretendard", size: 14)
                    .weight(.medium)
                )
                .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))

                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)

                TextField("", text: $text)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
            }
        }
    }
}

struct LabelAndTextFieldView_Previews: PreviewProvider {
    @State static private var text = ""

    static var previews: some View {
        LabelAndTextFieldView(text: $text, label: "Room ID")
    }
}
