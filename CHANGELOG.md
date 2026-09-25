# Changelog

## 2.0.0

- Replace the Yoga fork with the official `react/yoga` 3.2.1 Swift package.
- Require Swift 6 and enable C++ interoperability for the library. Clients must enable C++ interoperability in their targets.
- Configure containers with `Flex` initializer options and `yoga...` modifiers, and direct children with `flex...` modifiers. The public API no longer requires constructing a style object.
- Expose Yoga's flexbox properties through these modifiers, including edge spacing, positioning, dimensions, display, overflow, box sizing, and aspect ratio.
- Measure SwiftUI children through Yoga's measure callbacks, including baseline alignment.
- Release Yoga nodes and configuration with the layout cache, and recalculate placement for the actual bounds.
- Correct percentage usage to Yoga's 0–100 scale.
- Add DocC guides, generated API documentation, and Swift Package Index hosting configuration.
- Declare tvOS 16+ and visionOS 1+ support, and display Swift Package Index compatibility badges.
