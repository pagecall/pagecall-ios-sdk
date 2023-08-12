import SwiftUI
import PagecallCore
import Combine

@available(iOS 15.0, *)
struct HomeView: View {
    @State private var roomId: String = ""
    @State private var accessToken: String = ""
    @State private var query: String = ""
    @State private var isAlertOn: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var mode = PagecallMode.meet

    var body: some View {
        NavigationView {
            Background {
                VStack {
                    VStack(alignment: .leading) {
                        Image("Pagecall Logo")
                            .resizable()
                            .frame(width: 128, height: 28)
                            .padding(.vertical, 44)

                        VStack(alignment: .leading, spacing: 20) {
                            LabelAndTextField(text: $roomId, label: "Room ID")

                            LabelAndTextField(text: $accessToken, label: "Access Token")

                            LabelAndTextField(text: $query, label: "Query (Only for debug)")
                        }
                    }
                    .padding(.bottom, 44)

                    HStack(spacing: 12) {
                        NavigationLink(
                            destination: RoomView(roomId: roomId, accessToken: accessToken, mode: .replay, queryItems: parseQueryItems())
                        ) {
                            ReplayLabel()
                        }
                        .disabled(roomId == "" || accessToken == "")
                        .onTapGesture {
                            if roomId == "" || accessToken == "" {
                                isAlertOn = true
                            } else {
                                isAlertOn = false
                            }
                        }

                        NavigationLink(
                            destination: RoomView(roomId: roomId, accessToken: accessToken, mode: .meet, queryItems: parseQueryItems())
                        ) {
                            EnterLabel()
                        }
                        .disabled(roomId == "" || accessToken == "")
                        .onTapGesture {
                            if roomId == "" || accessToken == "" {
                                isAlertOn = true
                            } else {
                                isAlertOn = false
                            }
                        }

                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if isAlertOn {
                    VStack {
                        Alert(onClose: {
                            isAlertOn = false
                        },
                              text: "An input value is required.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 32)
                    .padding(.bottom, keyboardHeight == 0 ? 40 : keyboardHeight)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .onReceive(Publishers.keyboardHeight) {
                        self.keyboardHeight = $0
                    }
                }
            }
            .onTapGesture {
                self.endEditing() // dismiss keyboard when touched around
            }
            .background(Color(red: 0.976, green: 0.98, blue: 0.984, opacity: 1))
        }
    }

    private func endEditing() {
        UIApplication.shared.endEditing()
    }

    private func parseQueryItems() -> [URLQueryItem]? {
        if query != "" {
            return query.components(separatedBy: "&")
                .map {
                    $0.components(separatedBy: "=")
                }
                .map {
                    URLQueryItem(name: $0[0], value: $0[1])
                }
        }
        return nil
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            HomeView()
        } else {
            // Fallback on earlier versions
        }
    }
}
