# Yoga-SwiftUI
Yoga-SwiftUI is a powerful layout library for SwiftUI which brings Facebook's Yoga flexbox implementation to SwiftUI. It offers a simple API to apply flexbox-based layout in your SwiftUI apps.

## Features
- Support for iOS (16+), macOS (13+), watchOS (9+) using SwiftUI [custom layout](https://developer.apple.com/documentation/swiftui/composing_custom_layouts_with_swiftui).
- A thin wrapper around Yoga, a cross-platform layout library from Facebook, bringing flexbox to SwiftUI
- Nesting of Flex views within one another to build complex layouts
- Full compatibility with Figma's auto layout, empowering Figma plugin creators to generate flexbox code. It supports all properties including row gap and column gap in flexbox.
- Supports a wide array of layout customization like justifyContent, alignItems, alignSelf, flexDirection, flexWrap, flexGrow, flexShrink and more

## Usage
You can easily create a Flex container and add child views to it.

```
Flex(direction: .row, justifyContent: .center, alignItems: .center) {
    Text("Hello")
    Text("World")
}
```

In the above example, we create a Flex container with a row direction and center alignment for both axis. Inside it, we add two Text views.

Flex can be easily nested within one another to create complex layouts:

```
Flex {
    Flex(direction: .row) {
        Text("Row 1 Item 1")
        Text("Row 1 Item 2")
    }
    Flex(direction: .row) {
        Text("Row 2 Item 1")
        Text("Row 2 Item 2")
    }
}
```
In the above example, we have nested two Flex containers each with a row direction inside another Flex container.

The library also provides a set of modifiers to customize the layout of the SwiftUI views:

```
Text("Hello World")
    .flexGrow(1)
    .flexShrink(0)
    .justifyContent(.center)
    .alignItems(.flexStart)
    .alignSelf(.flexEnd)
    .flexDirection(.row)
    .flexWrap(.wrap)
```

In the above example, we use the modifiers provided by the library to customize the layout of a Text view.

## Installation
Yoga-SwiftUI is available as a Swift Package Manager package. You can add it to your project from Xcode's "Swift Packages" option in the File menu.

```
.package(url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git", from: "1.0.0")
```

## Contributing
Contributions to Yoga-SwiftUI are welcomed. If you encounter any problem or have any suggestions, please open an issue or send a pull request.

## License
Yoga-SwiftUI is open source software, available under the MIT license.
