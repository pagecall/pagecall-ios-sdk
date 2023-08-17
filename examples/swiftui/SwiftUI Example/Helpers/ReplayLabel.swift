//
//  ReplayButton.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/24.
//

import SwiftUI

struct ReplayLabel: View {
    var body: some View {
        Text("Replay")
            .font(Font.custom("Pretendard", size: 14).weight(.medium))
            .foregroundColor(Color(red: 0.07, green: 0.38, blue: 1))
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.98, green: 0.98, blue: 0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.07, green: 0.38, blue: 1), lineWidth: 1)
                    )
            )
    }
}

struct ReplayButton_Previews: PreviewProvider {
    static var previews: some View {
        ReplayLabel()
    }
}
