import Foundation

var TASK:  Task<(),Never>!
var EXIT = false

func HonsoleClientV1 ( _ op: String, _ str: String ) async throws {
    switch op {
    case "v1/js":
        try
        await JSinit(str)
    default:
        await JS(op, str)
    }
}

func HonsoleClientV2 ( _ op: String, _ json: [String:Any] ) async throws {
    switch op {
    case "v2/init":
        let str = #ensure( json[HONSOLE] as? String )
        await MainActor.run {
            UI.SERVER = str
        }
    case "v2/exit":
        EXIT = true
    default:
        await JS(op, json)
    }
}

func HonsoleClientV3 ( _ op: Data, _ data: Data ) async throws {
    switch op {
    case Data("v3/icon".utf8):
        try await H5icon(data)
    case Data("v3/blob".utf8):
        let key = try getb()
        let   _ = #ensure( BLOB[key] == nil )
        BLOB[key] = data
    default:
        throw Err(src: "op == unknown")
    }
}

func HonsoleClient ( _ op: Data ) async throws {
    if op.hasPrefix("v1/") {
        let oP  = #ensure( String(data: op, encoding: .utf8) )
        let str = try gets()
        return try await HonsoleClientV1(oP, str)
    }
    if op.hasPrefix("v2/") {
        let oP   = #ensure( String(data: op, encoding: .utf8) )
        let data = try getb()
        let json = #ensure( JSON(data) as? [String:Any] )!
        return try await HonsoleClientV2(oP, json)
    }
    if op.hasPrefix("v3/") {
        let data = try getb()
        return try await HonsoleClientV3(op, data)
    }
    throw Err(src: "op == unknown")
}

func HonsoleServer ( _ op: String, _ od: [Any] ) async throws -> Any? {
    switch op {
    case "v1/puts":
        let str = #ensure( od.dropFirst().first as? String )
        try puts(str)
        return nil
    default:
        throw Err(src: "op == unknown")
    }
}

func IDLE() {
    TASK = Task.detached {
        do {
            while !EXIT {
                let op = try getb()
                try await HonsoleClient(op)
            }
        }
        catch {
            ERR(error.info)
        }
    }
}

func getb () throws -> Data {
    let size = try getz()
    let data = try eatb(size)
    return data
}

func gets () throws -> String {
    let size = try getz()
    let data = try eats(size)
    return data
}

func getz () throws -> Int {
    switch MODE {
    case .txt:
        let head = try eats(16)
        let    _ = #ensure( head.hasPrefix("\n# +") )
        let    _ = #ensure( head.hasSuffix("+ #\n") )
        let size = #ensure( Int( head.suffix(12).prefix(8), radix: 16 ) )
        return size
    case .bin:
        let bin = try ABI_honsole_v3_bin_eat(iSZ)
        return        ABI_honsole_v3_mem2int(bin)
    }
}

func eats ( _ len: Int ) throws -> String {
    return #ensure( String( bytes: eatb(len), encoding: .utf8 ) )
}

func eatb ( _ len: Int ) throws -> Data {
    return try ABI_honsole_v3_bin_eat(len)
}

func puts ( _ bin: Data ) throws {
    let cnt = bin.count
    switch MODE {
    case .txt:
        let len = Data(String(format: "\n# +%08x+ #\n", cnt).utf8)
        try O.write(contentsOf: len)
        try O.write(contentsOf: bin)
    case .bin:
        try ABI_honsole_v3_bin_put(bin)
    }
}

func puts ( _ str: String ) throws {
    try puts(Data(str.utf8))
}

extension Data {
    func hasPrefix( _ pfx: String ) -> Bool {
        return starts(with: Data(pfx.utf8))
    }
}

struct Err: Error {
    let src: String
}

extension Error {
    var info: String {
        if let err = self as? Err {
            return err.src
        }
        ;  let err = self as NSError
        return err.localizedFailureReason ?? err.debugDescription
    }
}

@discardableResult
@freestanding(expression) public macro ensure     ( _: Bool ) -> Bool = #externalMacro(module: "HonsoleMacros", type: "HonsoleEnsureMacro")
@freestanding(expression) public macro ensure <T> ( _: T?   ) -> T    = #externalMacro(module: "HonsoleMacros", type: "HonsoleEnsureMacro")

func ENSURE    ( _ what: Bool, _ src: String ) throws -> Bool {
    guard     what else { throw Err(src: src) }
    return    what
}
func ENSURE<T> ( _ what: T?,   _ src: String ) throws -> T {
    guard let what else { throw Err(src: src) }
    return    what
}
