import SwiftUI
import PagecallCore

struct ContentView: View {
    @State var inputRoomId = ""
    @State var roomId: String?
    @State var isLoading = false

    var body: some View {
        if let roomId = roomId {
            ZStack {
                PagecallView(roomId: roomId, mode: .meet) {
                    isLoading = false
                } onTerminate: { _ in
                    self.roomId = nil
                }
                if isLoading {
                    ProgressView()
                }
            }
        } else {
            VStack {
                TextField("Room ID", text: $inputRoomId)
                Button("Enter") {
                    roomId = inputRoomId
                }
            }.padding().frame(maxWidth: 540).onAppear {
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
