
# ImageUtils

[![Travis CI](https://img.shields.io/travis/0xxd0/ImageUtils.svg?style=flat&colorA=24292e&colorB=24292e)](https://www.travis-ci.org/0xxd0/ImageUtils)
![](https://img.shields.io/badge/CocoaPods-✘-red.svg?colorA=24292e&colorB=24292e&style=flat)
![](https://img.shields.io/badge/Carthage-✔-red.svg?colorA=24292e&colorB=24292e&style=flat)
![](https://img.shields.io/badge/SPM-✔-red.svg?colorA=24292e&colorB=24292e&style=flat)
![](https://img.shields.io/github/repo-size/0xxd0/ImageUtils.svg?colorA=24292e&colorB=24292e&style=flat)

An elegant image utils & toolbox framework in pure Swift.

- [Requirement](#requirement)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Requirement

![platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-ed523f.svg)    ![language](https://img.shields.io/github/languages/top/0xxd0/ImageUtils.svg?colorB=ed523f)  ![Swift Version](https://img.shields.io/badge/Swift-3.2%20%7C%204.0-ed523f.svg)   ![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/0xxd0/ImageUtils.svg?colorB=ed523f)

#### Required
- Xcode 9.0+
- iOS 8.0+ | macOS 10.9+ | tvOS 9.0+ | watchOS 2.0+
- Swift 3.2+

## Installation

### CocoaPods 

⚠️ Comming soon

![CocoaPods](https://img.shields.io/cocoapods/v/ImageUtils.svg)

[CocoaPods](http://cocoapods.org) CocoaPods is a dependency manager for Swift and Objective-C Cocoa projects. It has over 41 thousand libraries and is used in over 3 million apps. CocoaPods can help you scale your projects elegantly. 

#### Install Cocoapods

```bash
$ gem install cocoapods
```

#### Integrate ImageUtils

With CocoaPods, specify ImageUtils in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<#Your Target#>' do
    pod 'ImageUtils', '~> 0.0.1'
end
```

run pod install:

```bash
$ pod install
```

### Carthage

Carthage is intended to be the simplest way to add frameworks to your Cocoa application.

#### Install Carthage 

```shell
$ brew update
$ brew install carthage
```

#### Integrate ImageUtils

Add following to Cartfile:

```
github "0xxd0/ImageUtils" ~> 0.0.1
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

#### Integrate ImageUtils

```swift
// Package.swift
// swift-tools-version:3.0

let package = Package(
    name: "<#Your Target#>",
    dependencies: [
        // ···
        .Package(url: "https://github.com/0xxd0/ImageUtils.git", majorVersion: 0)
        // ···
    ]
)
```

### Manually

Download zip or clone repo and integrate into your project manually.

## Usage

Clone the project and see the **Spotlight.playgroun** for detail usage.

## License
[![license](https://img.shields.io/github/license/0xxd0/ImageUtils.svg?colorA=24292e&colorB=24292e&style=flat)](https://github.com/0xxd0/ImageUtils/blob/master/LICENSE)

This project is released under the **MIT License**.
