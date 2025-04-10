import WebKit

struct ErrorEvent: Codable {
    let name: String
    let message: String?
}

extension String {
    var javaScriptString: String {
        var safeString  = self

        safeString      = safeString.replacingOccurrences(of: "\\", with: "\\\\")
        safeString      = safeString.replacingOccurrences(of: "\"", with: "\\\"")
        safeString      = safeString.replacingOccurrences(of: "\'", with: "\\\'")
        safeString      = safeString.replacingOccurrences(of: "\n", with: "\\n")
        safeString      = safeString.replacingOccurrences(of: "\r", with: "\\r")
        safeString      = safeString.replacingOccurrences(of: "\t", with: "\\t")

        safeString      = safeString.replacingOccurrences(of: "\u{0085}", with: "\\u{0085}")
        safeString      = safeString.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
        safeString      = safeString.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")

        return safeString
    }
}

class WebViewEmitter {
    private func rawEmit(eventName: String) {
        self.rawEmit(eventName: eventName, message: nil)
    }

    private func rawEmit(eventName: String, message: String?) {
        self.rawEmit(eventName: eventName, message: message, eventId: nil)
    }

    private func rawEmit(eventName: String, message: String?, eventId: String?) {
        let args = [eventName, message, eventId].compactMap { $0 }
        let script = "PN.e(\(args.map { arg in "'\(arg)'" }.joined(separator: ",")))"
        runScript(script)
    }

    func emit(eventName: BridgeEvent) {
        self.rawEmit(eventName: eventName.rawValue)
    }

    func emit(eventName: BridgeEvent, message: String) {
        self.rawEmit(eventName: eventName.rawValue, message: message)
    }

    private var eventIdToCallback = [String: (Error?, String?) -> Void]()

    func emit(eventName: BridgeEvent, json: [String: Any]) {
        self.jsonEmit(eventName: eventName.rawValue, json: json, callback: nil)

    }
    func request(eventName: BridgeRequest, json: [String: Any], callback: @escaping ((Error?, String?) -> Void)) {
        self.jsonEmit(eventName: eventName.rawValue, json: json, callback: callback)
    }

    private func jsonEmit(eventName: String, json: [String: Any], callback: ((Error?, String?) -> Void)?) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json), let stringifiedJson = String(data: jsonData, encoding: .utf8) else {
            callback?(PagecallError.other(message: "Failed to stringify"), nil)
            return
        }
        if let callback = callback {
            let eventId = UUID().uuidString
            eventIdToCallback[eventId] = callback
            self.rawEmit(eventName: eventName, message: stringifiedJson, eventId: eventId)
        } else {
            self.rawEmit(eventName: eventName, message: stringifiedJson)
        }
    }

    func resolve(eventId: String, error: String?, result: String?) {
        if let callback = eventIdToCallback[eventId] {
            eventIdToCallback.removeValue(forKey: eventId)
            if let errorMessage = error {
                callback(PagecallError.other(message: errorMessage), nil)
            } else {
                callback(nil, result)
            }
        } else {
            print("[WebViewEmitter] Event not found (id: \(eventId)")
        }
    }

    func emit(eventName: BridgeEvent, data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            self.emit(eventName: eventName, message: string)
        }
    }

    func error(_ error: Error) {
        if let error = error as? PagecallError {
            self.error(name: "HandlediOSSDKError", message: error.message)
        } else {
            self.error(name: "UnexpectediOSSDKError", message: error.localizedDescription)
        }
    }

    func error(name: String, message: String?) {
        guard let data = try? JSONEncoder().encode(ErrorEvent(name: name, message: message?.javaScriptString)) else { return }
        self.emit(eventName: .error, data: data)
    }

    func log(name: String, message: String?) {
        guard let data = try? JSONEncoder().encode(ErrorEvent(name: name, message: message?.javaScriptString)) else { return }
        self.emit(eventName: .log, data: data)
    }

    func response(requestId: String, data: Data?) {
        let script: String = {
            if let data = data, let string = String(data: data, encoding: .utf8) {
                return "PN.r('\(requestId)', '\(string)')"
            } else {
                return "PN.r('\(requestId)')"
            }
        }()
        runScript(script)
    }

    func response(requestId: String, errorMessage: String) {
        runScript("PN.t('\(requestId)','\(errorMessage.javaScriptString)')")
    }

    func runScript(_ script: String) {
        delegate?.runScript(script)
    }

    weak var delegate: ScriptDelegate?
}

public protocol ScriptDelegate: AnyObject {
    func runScript(_ script: String)
}
