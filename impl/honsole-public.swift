import Foundation

var I = FileHandle.standardInput
var O = FileHandle.standardOutput
var E = FileHandle.standardError

fileprivate 
let EoF = NSError( domain: NSPOSIXErrorDomain, code: Int(EPIPE) )
let iSZ = 8

func ABI_honsole_v3_mem2int ( _ mem: Data ) -> Int {
    return mem.withUnsafeBytes { ptr in
        ptr.load(as: Int.self)
    }
}

func ABI_honsole_v3_int2mem ( _ i64: Int ) -> Data {
    var mem = Data(count: iSZ)
    mem.withUnsafeMutableBytes { ptr in
        ptr.storeBytes(of: i64, as: Int.self)
    }
    return mem
}

func ABI_honsole_v3_bin_get ( ) throws -> Data {
    let bin = try ABI_honsole_v3_bin_eat(iSZ)
    let len =     ABI_honsole_v3_mem2int(bin)
    return    try ABI_honsole_v3_bin_eat(len)
}

func ABI_honsole_v3_bin_put ( _ bin: Data ) throws {
    let cnt = bin.count
    let pfx = ABI_honsole_v3_int2mem(cnt)
    try       ABI_honsole_v3_bin_out(pfx)
    try       ABI_honsole_v3_bin_out(bin)
}

func ABI_honsole_v3_bin_eat ( _ len: Int ) throws -> Data {
    guard     len != 0                         else { return Data() }
    guard let bin = try I.read(upToCount: len) else { throw EoF }
    guard     bin.count                == len  else { throw EoF }
    return    bin
}

func ABI_honsole_v3_bin_out ( _ bin: Data ) throws {
    try O.write(contentsOf: bin)
}
