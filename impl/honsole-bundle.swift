import Private
import SwiftUI

let PRODUCT = Bundle.main.bundleIdentifier ?? CommandLine.arguments.first ?? H5AGENT
let PID     = ProcessInfo.processInfo.processIdentifier

let MODE = Mode(rawValue: ARG("mode")) ?? .bin
let SKIN = Skin(rawValue: ARG("skin")) ?? .H5
let BLUR =            Int(ARG("blur")) ??  12

@MainActor
var UI = HonsoleUI()

@MainActor
@Observable
class HonsoleUI {
    var ABOUTS = PRODUCT
    var WINDOW = HONSOLE + " (PID:" + PID.description + ")"
    var CLIENT = H5AGENT + ": " + VERSION + "/" + REVISION.prefix(8) + "; " + TIMESTAMP
    var SERVER = "SERVER: ?"
    var WEBKIT = "WEBKIT: ?"
    var ERRC   = Color.clear
    var ERRT   = ""
}
enum Skin: String {
    case H5, OS, UI
}
enum Mode: String {
    case txt, bin
}

@discardableResult
func ERR ( _ msg: String, _ color: Color = .red.opacity(0.5) ) -> String {
    DispatchQueue.main.async {
        UI.ERRC = color
        UI.ERRT = msg
        try? E.write(contentsOf: Data( ( msg + "\n" ).utf8 ))
    }
    return msg
}

func ARG ( _ key: String ) -> String {
    let pfx = "--" + key + "="
    var ret = ""
    for arg in CommandLine.arguments {
        ret = arg.hasPrefix(pfx) ? String(arg.dropFirst(pfx.count)) : ret
    }
    return ret
}

@MainActor
func H5icon ( _ data: Data ) throws {
    NSApplication.shared.applicationIconImage = NSImage(data: data)
}

func H5skin ( _ view: NSView ) {
    if SKIN == .H5 {
        view.window?.backgroundColor = .windowBackgroundColor.withAlphaComponent(1.0/256)
    }
}

class H5Skin: NSView {
    override
    func viewDidMoveToWindow ( ) {
        if let window {
            let con = CGSDefaultConnectionForThread()
            let win = window.windowNumber
            CGSSetWindowBackgroundBlurRadius(con,win,BLUR)
            H5skin(self)
        }
    }
}

struct H5SkinView: NSViewRepresentable {
    @Environment(\.colorScheme)
    private
    var colorScheme
    func makeNSView ( context: Self.Context ) -> NSView {
        return switch SKIN {
            case .H5: H5Skin()
            case .OS: NSVisualEffectView()
            default:  NSView()
        }
    }
    func updateNSView ( _ nsView: NSView, context: Context ) {
        return H5skin(nsView)
    }
}

@main
struct HonsoleApp: App {
    @NSApplicationDelegateAdaptor
    var ctrl: MainDelegate
    var body: some Scene {
        Window(UI.WINDOW, id: UI.WINDOW) {
            ZStack {
                H5SkinView()
                H5MainView()
            }
            .toolbar {
                if UI.ERRT != "" {
                    Text(UI.ERRT)
                } else {
                    Spacer()
                }
            }
            .toolbarBackground(UI.ERRC, for: .windowToolbar)
            .ignoresSafeArea( .all, edges: ( SKIN == .H5 && UI.ERRT == "" ) ? .all : .init() )
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(UI.ABOUTS){}
            }
            CommandGroup(replacing: .help) {
                Button(UI.WINDOW){}
                Button(UI.CLIENT){}
                Button(UI.SERVER){}
                Button(UI.WEBKIT){}
                Divider()
                ForEach( REV, id: \.0 ) { mod, rev in
                    Text( rev + " " + mod )
                }
            }
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: SKIN != .H5))
    }
}

class MainDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching ( _ notification: Notification ) {
        guard sandbox_check( getpid(), nil, 0 ) != 0 else {
            fatalError("sandbox == false")
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
    }
}
