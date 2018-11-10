# TVAlert

[![CI Status](https://img.shields.io/travis/adrum/tvalert.svg?style=flat)](https://img.shields.io/travis/adrum/tvalert)
[![Version](https://img.shields.io/cocoapods/v/TVAlert.svg?style=flat)](http://cocoapods.org/pods/TVAlert)
[![License](https://img.shields.io/cocoapods/l/TVAlert.svg?style=flat)](http://cocoapods.org/pods/TVAlert)
[![Platform](https://img.shields.io/cocoapods/p/TVAlert.svg?style=flat)](http://cocoapods.org/pods/TVAlert)

## Usage

TVAlert's usage is the same as `UIAlertController`. Just replace `UI` with `TV` on both `UIAlertController` and `UIAlertAction` 

```swift
let alertController = TVAlertController(title: "Title", message: "Message", preferredStyle: .alert)

alertController.style = style

let OKAction = TVAlertAction(title: "OK", style: .default) { (action) in
// ...
}
alertController.addAction(OKAction)

let cancelAction = TVAlertAction(title: "Cancel", style: .cancel) { (action) in
// ...
}
alertController.addAction(cancelAction)


self.present(alertController, animated: true) {
// ...
}
```

## Requirements

## Installation

TVAlert is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TVAlert"
```

## Author

Austin Drummond, adrummond7@gmail.com

## License

TVAlert is available under the MIT license. See the LICENSE file for more info.
