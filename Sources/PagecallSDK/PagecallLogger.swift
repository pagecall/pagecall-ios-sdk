import Sentry

public class PagecallLogger {
    public static let shared = PagecallLogger()
    private init() {
        SentrySDK.start { options in
            options.dsn = "https://c437933ec2d74283869a5a643c2521c1@o68827.ingest.sentry.io/4505045679210496"
            options.debug = false
            options.tracesSampleRate = 0
        }
    }

    public func disable() {
        SentrySDK.close()
    }

    public func setRoomId(_ roomId: String) {
        print("[PagecallLogger] set roomId", roomId)
        SentrySDK.configureScope { scope in
            scope.setTag(value: "roomId", key: roomId)
        }
    }

    func capture(message: String) {
        SentrySDK.capture(message: message)
        print("[PagecallLogger] captured message", message)
    }

    func capture(error: Error) {
        SentrySDK.capture(error: error)
        print("[PagecallLogger] captured error", error)
    }
}
