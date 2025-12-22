#if os(macOS)
import AppKit

@main
struct IconGenerator {
    static func main() {
        let size = CGSize(width: 1024, height: 1024)
        let scale: CGFloat = 1

        let image = NSImage(size: size)
        image.lockFocusFlipped(false)

        // Background rounded rect
        let bgColor = NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        let bgRect = NSRect(origin: .zero, size: size)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 220, yRadius: 220)
        bgColor.setFill()
        bgPath.fill()

        // Pixel grid size (64x64 grid scaled up)
        let px: CGFloat = size.width / 64.0

        func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: NSColor) {
            color.setFill()
            let r = NSRect(x: CGFloat(x) * px, y: CGFloat(y) * px, width: CGFloat(w) * px, height: CGFloat(h) * px)
            NSBezierPath(rect: r).fill()
        }

        // Palette
        let water = NSColor(calibratedRed: 0.22, green: 0.48, blue: 0.90, alpha: 1.0)
        let hull  = NSColor(calibratedRed: 0.13, green: 0.16, blue: 0.24, alpha: 1.0)
        let deck  = NSColor(calibratedRed: 0.75, green: 0.78, blue: 0.82, alpha: 1.0)
        let light = NSColor(calibratedRed: 0.86, green: 0.88, blue: 0.92, alpha: 1.0)

        // Water line
        rect(4, 20, 56, 3, water)

        // Hull silhouette (simple stylized battleship)
        rect(8, 17, 48, 4, hull)   // main hull
        rect(12, 15, 40, 2, hull)  // bow taper
        rect(16, 14, 32, 1, hull)

        // Deck
        rect(20, 19, 24, 2, deck)

        // Superstructure
        rect(26, 21, 6, 3, deck)
        rect(32, 22, 4, 2, deck)

        // Mast
        rect(36, 24, 1, 3, light)

        // Small details
        rect(22, 20, 2, 1, light)
        rect(24, 20, 2, 1, light)
        rect(28, 20, 2, 1, light)
        rect(30, 20, 2, 1, light)

        image.unlockFocus()

        // Export PNG
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()

        let png = rep.representation(using: .png, properties: [:])!
        let url = URL(fileURLWithPath: "AppIcon-1024.png")
        do {
            try png.write(to: url)
            print("Wrote \(url.path)")
        } catch {
            print("Failed to write icon: \(error)")
        }
    }
}
#endif
