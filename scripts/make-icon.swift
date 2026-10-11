#!/usr/bin/env swift
// Generates the app icon set: swift scripts/make-icon.swift
import Cocoa

let outDir = "Macright/Assets.xcassets/AppIcon.appiconset"
let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background: macOS icon grid (824 pt squircle) with a blue gradient.
let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824),
                        xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor.black.setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(red: 0.30, green: 0.58, blue: 1.0, alpha: 1),
           ending: NSColor(red: 0.10, green: 0.22, blue: 0.72, alpha: 1))!.draw(in: tile, angle: -90)

// Mouse body.
let body = NSBezierPath(roundedRect: NSRect(x: 342, y: 232, width: 340, height: 560),
                        xRadius: 170, yRadius: 170)
NSColor.white.setFill()
body.fill()

// Right button pressed (accent color), clipped to the body.
NSGraphicsContext.saveGraphicsState()
body.addClip()
NSColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 512, y: 540, width: 200, height: 270)).fill()
NSGraphicsContext.restoreGraphicsState()

// Button dividers.
let lines = NSBezierPath()
lines.move(to: NSPoint(x: 512, y: 540)); lines.line(to: NSPoint(x: 512, y: 792))
lines.move(to: NSPoint(x: 342, y: 540)); lines.line(to: NSPoint(x: 682, y: 540))
lines.lineWidth = 16
NSColor(red: 0.10, green: 0.22, blue: 0.72, alpha: 1).setStroke()
lines.stroke()

// Click ripples next to the right button.
NSColor.white.withAlphaComponent(0.9).setStroke()
for (i, r) in [CGFloat(60), 110].enumerated() {
    let arc = NSBezierPath()
    arc.appendArc(withCenter: NSPoint(x: 640, y: 700), radius: 110 + r, startAngle: -5, endAngle: 60)
    arc.lineWidth = 18 - CGFloat(i) * 4
    arc.lineCapStyle = .round
    arc.stroke()
}
NSGraphicsContext.restoreGraphicsState()

try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let master = rep.representation(using: .png, properties: [:])!
try master.write(to: URL(fileURLWithPath: "\(outDir)/icon_1024.png"))

// Required macOS slots: point size @1x/@2x.
let slots: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                           (256, 1), (256, 2), (512, 1), (512, 2)]
var images: [[String: String]] = []
for (pt, scale) in slots {
    let px = pt * scale
    let name = "icon_\(px).png"
    let target = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: target)
    NSGraphicsContext.current?.imageInterpolation = .high
    rep.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    try target.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    images.append(["idiom": "mac", "size": "\(pt)x\(pt)", "scale": "\(scale)x", "filename": name])
}
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))
try "{\"info\":{\"version\":1,\"author\":\"xcode\"}}"
    .write(toFile: "Macright/Assets.xcassets/Contents.json", atomically: true, encoding: .utf8)
print("icon written")
