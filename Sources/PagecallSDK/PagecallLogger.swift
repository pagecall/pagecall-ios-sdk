#if canImport(Sentry)
import Sentry
#endif

public class PagecallLogger {
    public static let shared = PagecallLogger()
    private init() {
        #if canImport(Sentry)
        SentrySDK.start { options in
            options.dsn = "https://c437933ec2d74283869a5a643c2521c1@o68827.ingest.sentry.io/4505045679210496"
            options.debug = false
            options.tracesSampleRate = 0
        }
        #endif
    }

    public func disable() {
        #if canImport(Sentry)
        SentrySDK.close()
        #endif
    }

    public func setRoomId(_ roomId: String) {
        print("[PagecallLogger] set roomId", roomId)
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            scope.setTag(value: roomId, key: "roomId")
        }
        #endif
    }

    func addBreadcrumb(message: String) {
        #if canImport(Sentry)
        let crumb = Breadcrumb()
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
        #endif
    }

    func capture(message: String) {
        #if canImport(Sentry)
        SentrySDK.capture(message: message)
        #endif
        print("[PagecallLogger] captured message", message)
    }

    func capture(error: Error) {
        #if canImport(Sentry)
        SentrySDK.capture(error: error)
        #endif
        print("[PagecallLogger] captured error", error)
    }
}
