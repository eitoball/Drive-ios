// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS)
  import UIKit.UIImage
  typealias Image = UIImage
#elseif os(OSX)
  import AppKit.NSImage
  typealias Image = NSImage
#endif

enum Asset: String {
  case Dot = "Dot"
  case Header = "Header"
  case Back = "Back"
  case Center = "Center"
  case Console = "Console"
  case Github = "Github"
  case Home = "Home"
  case More = "More"
  case Record = "Record"
  case Resize = "Resize"
  case Upload = "Upload"
  case SafecastBoxed = "SafecastBoxed"
  case SafecastLettersBig = "SafecastLettersBig"
  case SafecastLettersSmall = "SafecastLettersSmall"
  case Separator = "Separator"

  var image: Image {
    return Image(asset: self)
  }
}

extension Image {
  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
