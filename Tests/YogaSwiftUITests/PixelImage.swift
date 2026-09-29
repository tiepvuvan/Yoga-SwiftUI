import CoreGraphics
import XCTest

/// Normalizes renderer output to RGBA bytes on both macOS and iOS.
struct PixelImage {
    struct Pixel {
        let redComponent: Double
        let blueComponent: Double
        let alphaComponent: Double
    }
    let width: Int
    let height: Int
    private let bytes: [UInt8]

    init(_ source: CGImage?) throws {
        let image = try XCTUnwrap(source)
        width = image.width
        height = image.height
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.setBlendMode(.copy)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let data = try XCTUnwrap(context.data)
        bytes = Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4))
    }

    func colorAt(x: Int, y: Int) -> Pixel? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let offset = (y * width + x) * 4
        return Pixel(redComponent: Double(bytes[offset]) / 255,
                     blueComponent: Double(bytes[offset + 2]) / 255,
                     alphaComponent: Double(bytes[offset + 3]) / 255)
    }
}
