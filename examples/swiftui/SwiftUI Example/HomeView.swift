import SwiftUI
import PagecallCore
import Combine

@available(iOS 15.0, *)
struct HomeView: View {
    let pagecallWebView: PagecallWebView
    
    @State private var roomId: String = ""
    @State private var accessToken: String = ""
    @State private var query: String = ""
    @State private var isAlertOn: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var mode = PagecallMode.meet

    @State private var isShowingPagecallView = false
    
    init(pagecallWebView: PagecallWebView) {
        self.pagecallWebView = pagecallWebView
    }

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
                        ReplayButton(onTap: onReplayButtonTap)
                        EnterButton(onTap: onEnterButtonTap)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                VStack {
                    Alert(isAlertOn: $isAlertOn)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 32)
                .padding(.bottom, keyboardHeight == 0 ? 40 : keyboardHeight)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onReceive(Publishers.keyboardHeight) {
                    self.keyboardHeight = $0
                }

                NavigationLink(
                    destination: PagecallView(pagecallWebView: pagecallWebView, roomId: roomId, accessToken: accessToken, mode: mode, queryItems: parseQueryItems(), isShowingPagecallView: $isShowingPagecallView),
                    isActive: $isShowingPagecallView,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .onTapGesture {
                self.endEditing() // dismiss keyboard when touched around
            }
        }
    }

    private func endEditing() {
        UIApplication.shared.endEditing()
    }

    private func onReplayButtonTap() {
        if roomId == "" || accessToken == "" {
            isAlertOn = true
        } else {
            mode = .replay
            isAlertOn = false
            isShowingPagecallView = true
        }
    }

    private func onEnterButtonTap() {
        if roomId == "" || accessToken == "" {
            isAlertOn = true
        } else {
            mode = .meet
            isAlertOn = false
            isShowingPagecallView = true
        }
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
            HomeView(pagecallWebView: PagecallWebView())
        } else {
            // Fallback on earlier versions
        }
    }
}
