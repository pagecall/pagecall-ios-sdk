//
//  Alert.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import SwiftUI

struct Alert: View {
    @Binding var isAlertOn: Bool

    var body: some View {
        if isAlertOn {
            HStack(alignment: .center, spacing: 12) {
                Image("Circled X")
                    .resizable()
                    .frame(width: 20, height: 20)

                Text("An input value is required.")
                .font(
                    Font.custom("Pretendard", size: 14)
                        .weight(.medium)
                )
                .foregroundColor(Color(red: 0.74, green: 0.1, blue: 0.1))
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Image("X")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        isAlertOn = false
                    }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 1, green: 0.95, blue: 0.95))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .inset(by: 0.5)
                    .stroke(Color(red: 0.89, green: 0.18, blue: 0.18).opacity(0.5), lineWidth: 1)
            )
        }

    }
}

struct Alert_Previews: PreviewProvider {
    @State private static var isAlertOn = true

    static var previews: some View {
        Alert(isAlertOn: $isAlertOn)
    }
}
