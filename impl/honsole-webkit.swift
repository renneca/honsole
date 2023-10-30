import WebKit
import SwiftUI

let WebKitVer = Bundle(for: WKWebView.self).infoDictionary?["CFBundleVersion"] as! String

var H5UX = WebKitDelegate()
var H5FW:  WKContentRuleList!
var VIEW:  WKWebView!

func JSON ( _ data: Data ) -> Any? {
    return try? JSONSerialization.jsonObject(with: data, options: .json5Allowed)
}

@MainActor
func JS ( _ op: String, _ od: Any ) async {
    VIEW.callAsyncJavaScript("honsole[op](op,od)", arguments: [ "op": op, "od": od ], in: nil, in: .page)
}

@MainActor
func JSinit ( _ str: String ) async throws {
    try await VIEW.evaluateJavaScript(str)
}

@MainActor
func H5init () async -> ( Any?, String? ) {
    IDLE();
    UI.WEBKIT = "WebKit/" + WebKitVer
    return ( NSNull(), nil )
}

func HonsoleHandle ( _ op: String, _ od: [Any] ) async -> ( Any?, String? ) {
    switch op {
    case "H5init":
        return await H5init()
    default:
        do {
            return ( try await HonsoleServer(op, od) ?? NSNull(), nil )
        } catch {
            return ( nil, error.info )
        }
    }
}

@MainActor
func H5boot () async {
    H5FW = try! await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: HONSOLE, encodedContentRuleList: FIREWALL)!
}

class HonsoleWKWebView: WKWebView {
    override
    func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        menu.items.removeAll { item in
            item.identifier?.rawValue == "WKMenuItemIdentifierReload"
        }
        super.willOpenMenu(menu, with: event)
    }
    override
    func mouseDragged(with event: NSEvent) {
        if let window {
            if let body = window.contentView?.safeAreaRect {
                let force = event.locationInWindow.y > body.height
                if force {
                    window.performDrag(with: event)
                    return
                }
            }
        }
        super.mouseDragged(with: event)
    }
}

struct WebKitView: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        let conf = WKWebViewConfiguration()
        let ctrl = WKUserContentController()
        let data = WKWebsiteDataStore.nonPersistent()
        let boot = WKUserScript(source: H5INIT, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .page)
        ctrl.add(H5FW)
        ctrl.addScriptMessageHandler(H5UX, contentWorld: .page, name: HONSOLE)
        ctrl.addUserScript(boot)
        conf.userContentController = ctrl
        conf.websiteDataStore      = data
        conf.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let view = HonsoleWKWebView(frame: .zero, configuration: conf)
        view.uiDelegate         = H5UX
        view.navigationDelegate = H5UX
        view.allowsLinkPreview  = false
        view.isInspectable      = true
        view.setValue(false, forKey: "drawsBackground")
        view.loadHTMLString(H5HTML, baseURL: URL(string: H5ROOT))
        VIEW = view
        return view
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {
        return
    }
}

struct H5MainView: View {
    @State
    var boot = false
    var body: some View {
        if boot {
            WebKitView()
        } else {
            Spacer().task {
                await H5boot()
                boot = true
            }
        }
    }
}

class WebKitDelegate: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandlerWithReply {
    @MainActor
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        do {
            let body = #ensure( message.body as? [Any]  )
            let op   = #ensure( body.first   as? String )
            return await HonsoleHandle(op, body)
        } catch {
            return ( nil, ERR(error.info) )
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        return navigationAction.request.url?.absoluteString == H5ROOT ? .allow : .cancel
    }
}

let H5ROOT = "honsole:root"
let H5HTML =
"""
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body></body>
</html>
"""
let H5INIT =
"""
window.webkit.messageHandlers.honsole.postMessage(["H5init"])
"""
let FIREWALL =
"""
[{ "trigger": { "url-filter": ".*" }, "action": { "type": "block" } }]
"""
