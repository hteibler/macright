import Cocoa

/// Template image of a mouse whose right button is pressed.
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let body = NSBezierPath(roundedRect: NSRect(x: 4, y: 1.5, width: 10, height: 15),
                                    xRadius: 5, yRadius: 5)
            body.lineWidth = 1.4
            NSColor.black.setStroke()
            body.stroke()

            // Right button, filled.
            NSGraphicsContext.saveGraphicsState()
            body.addClip()
            NSBezierPath(rect: NSRect(x: 9, y: 9.5, width: 6, height: 8)).fill()
            NSGraphicsContext.restoreGraphicsState()

            // Divider between the buttons.
            let divider = NSBezierPath()
            divider.move(to: NSPoint(x: 9, y: 9.5))
            divider.line(to: NSPoint(x: 9, y: 16))
            divider.move(to: NSPoint(x: 4, y: 9.5))
            divider.line(to: NSPoint(x: 14, y: 9.5))
            divider.lineWidth = 1.2
            divider.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
