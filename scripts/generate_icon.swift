#!/usr/bin/swift
import AppKit

let size = 1024
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Rounded rect background
let radius: CGFloat = 224
let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

// Blue-to-indigo gradient (like Safari/Arc vibes)
let gradient = NSGradient(
    colors: [
        NSColor(red: 0.18, green: 0.44, blue: 0.96, alpha: 1),
        NSColor(red: 0.38, green: 0.18, blue: 0.88, alpha: 1)
    ],
    atLocations: [0, 1],
    colorSpace: .deviceRGB
)!
gradient.draw(in: path, angle: -50)

// SF Symbol — tint white before drawing into main context
let symSize: CGFloat = 560
let symRect = NSRect(
    x: CGFloat(size) / 2 - symSize / 2,
    y: CGFloat(size) / 2 - symSize / 2,
    width: symSize,
    height: symSize
)
let cfg = NSImage.SymbolConfiguration(pointSize: symSize, weight: .medium)
if let sym = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {

    // Tint: draw symbol, then fill white over it using sourceAtop (respects alpha mask)
    let tinted = NSImage(size: NSSize(width: symSize, height: symSize))
    tinted.lockFocus()
    sym.draw(in: NSRect(x: 0, y: 0, width: symSize, height: symSize),
             from: .zero, operation: .sourceOver, fraction: 1.0)
    NSColor.white.set()
    NSRect(x: 0, y: 0, width: symSize, height: symSize).fill(using: .sourceAtop)
    tinted.unlockFocus()

    tinted.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)
}

image.unlockFocus()

// Export PNG
guard let tiff = image.tiffRepresentation,
      let bmp = NSBitmapImageRep(data: tiff),
      let png = bmp.representation(using: .png, properties: [:]) else {
    print("Failed to render image"); exit(1)
}
let outURL = FileManager.default.temporaryDirectory.appendingPathComponent("bs_icon_1024.png")
do {
    try png.write(to: outURL)
    print("Saved \(outURL.path)")
} catch {
    print("Failed to write icon: \(error)")
    exit(1)
}
