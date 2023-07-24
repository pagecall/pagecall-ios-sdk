import SwiftUI
import PagecallCore

struct Background<Content: View>: View {
    private var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        Color(red: 0.98, green: 0.98, blue: 0.98)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .overlay(content)
    }
}

struct ContentView: View {
    @State private var roomId: String = ""
    @State private var accessToken: String = ""
    @State private var query: String = ""

    var body: some View {
        Background {
            VStack {
                VStack(alignment: .leading) {
                    Image("Pagecall Logo")
                        .resizable()
                        .frame(width: 128, height: 28)
                        .padding(.vertical, 44)

                    VStack(alignment: .leading, spacing: 20) {
                        LabelAndTextFieldView(text: $roomId, label: "Room ID")

                        LabelAndTextFieldView(text: $accessToken, label: "Access Token")

                        LabelAndTextFieldView(text: $query, label: "Query (Only for debug)")
                    }
                }
                .padding(.bottom, 44)

                HStack(spacing: 12) {
                    ReplayButton()
                    EnterButton()
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }.onTapGesture {
                self.endEditing() // dismiss keyboard when touched around
            }
    }

    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
