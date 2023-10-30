import Foundation

typealias JSON = [ String: Any ]

func gets () -> JSON? {
    return try? JSONSerialization.jsonObject(with: ABI_honsole_v3_bin_get()) as? JSON
}

func puts ( _ msg: JSON ) {
    return try! ABI_honsole_v3_bin_put(JSONSerialization.data(withJSONObject: msg))
}

func expr ( _ op: String, _ str: String ) -> String? {
    switch op {
    case "HonsoleEnsureMacro":
        let pfx = "#ensure("
        let sfx = ")"
        let src = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard str.hasPrefix(pfx) else { break }
        guard src.hasSuffix(sfx) else { break }
        let raw = src.dropFirst(pfx.count).dropLast(sfx.count).trimmingCharacters(in: .whitespacesAndNewlines)
        let arg = [ raw, raw.debugDescription ].joined(separator: ", ")
        let ret = "try ENSURE( " + arg + " )"
        return ret
    default:
        break
    }
    return nil
}

func doit ( _ msg: JSON ) {
    if let _ = msg["getCapability"] {
        puts(["getCapabilityResult":["capability": ["protocolVersion":7]]])
        return
    }
    if let exp = msg["expandFreestandingMacro"] as? JSON {
        let mac = exp["macro"]    as! JSON
        let stx = exp["syntax"]   as! JSON
        let key = mac["typeName"] as! String
        let str = stx["source"]   as! String
        let ret = expr( key, str )
        puts([
            "expandMacroResult": [
              "expandedSource": ret as Any,
              "diagnostics": []
            ]
        ])
        return
    }
    fatalError()
}

@main
struct HonsoleMacrosPlugin {
    static func main () {
        while let msg = gets() {
            doit(msg);
        }
    }
}
