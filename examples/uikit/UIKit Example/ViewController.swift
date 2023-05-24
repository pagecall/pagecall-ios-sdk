import UIKit
import PagecallCore

class ViewController: UIViewController {
    override func viewDidLoad() {
        let headerView = UIView()
        headerView.backgroundColor = .green
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80)
        ])

        let pagecallView = PagecallWebView()
        view.addSubview(pagecallView)
        pagecallView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pagecallView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagecallView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagecallView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            pagecallView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        _ = pagecallView.load(roomId: "646d7c3526bcac71fe8c393b", mode: .meet)
    }
}
