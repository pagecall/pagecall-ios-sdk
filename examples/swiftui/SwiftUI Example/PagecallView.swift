//
//  PagecallView.swift
//  SwiftUI Example
//
//  Created by 최성혁 on 2023/07/25.
//

import SwiftUI

struct PagecallView: View {
    let roomId: String
    let accessToken: String
    let queryItems: [URLQueryItem]?
    
    @State private var isLoading = true
    
    init(roomId: String, accessToken: String, queryItems: [URLQueryItem]?) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.queryItems = queryItems
    }
    
    var body: some View {
        ZStack {
            Pagecall(
                roomId: roomId,
                accessToken: accessToken,
                queryItems: queryItems,
                mode: .meet,
                onLoad: { () in
                    isLoading = false
                },
                onTerminate:{ _ in
                    isLoading = false
                }
            )
            
            Loading(isLoading: $isLoading)
        }
    }
}

struct PagecallView_Previews: PreviewProvider {
    static var previews: some View {
        PagecallView(roomId: "d", accessToken: "d", queryItems: nil)
    }
}
