// FontAwesome.swift
//
// Copyright (c) 2014-present FontAwesome.swift contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Adapted for macOS by @hataewon
// Added trimming of transparent pixels and centering the image if the background color is clear.

import Cocoa
import CoreText

// MARK: - Public

/// A FontAwesome extension to UIFont.
public extension NSFont {

  /// Get a UIFont object of FontAwesome.
  ///
  /// - parameter ofSize: The preferred font size.
  /// - returns: A UIFont object of FontAwesome.
  public class func fontAwesome(ofSize fontSize: CGFloat) -> NSFont? {
    let name = "FontAwesome"
    let fontMembers = NSFontManager.shared.availableMembers(ofFontFamily: name) ?? []
    if fontMembers.isEmpty {
      do {
        try FontLoader.loadFont(name)
      } catch {
        return nil
      }
    }

    return NSFont(name: name, size: fontSize)
  }
}

/// A FontAwesome extension to String.
public extension String {

  /// Get a FontAwesome icon string with the given icon name.
  ///
  /// - parameter name: The preferred icon name.
  /// - returns: A string that will appear as icon with FontAwesome.
  public static func fontAwesomeIcon(name: FontAwesome) -> String {
    return name.rawValue.substring(to: name.rawValue.characters.index(name.rawValue.startIndex, offsetBy: 1))
  }

  /// Get a FontAwesome icon string with the given CSS icon code. Icon code can be found here: http://fontawesome.io/icons/
  ///
  /// - parameter code: The preferred icon name.
  /// - returns: A string that will appear as icon with FontAwesome.
  public static func fontAwesomeIcon(code: String) -> String? {

    guard let name = self.fontAwesome(code: code) else {
      return nil
    }

    return self.fontAwesomeIcon(name: name)
  }

  /// Get a FontAwesome icon with the given CSS icon code. Icon code can be found here: http://fontawesome.io/icons/
  ///
  /// - parameter code: The preferred icon name.
  /// - returns: An internal corresponding FontAwesome code.
  public static func fontAwesome(code: String) -> FontAwesome? {

    guard let raw = FontAwesomeIcons[code], let icon = FontAwesome(rawValue: raw) else {
      return nil
    }

    return icon
  }
}

/// A FontAwesome extension to UIImage.
public extension NSImage {

  public static func fontAwesomeIcon(name: FontAwesome,
                                     textColor: NSColor,
                                     dimension: CGFloat,
                                     backgroundColor: NSColor = NSColor.clear) -> NSImage
  {
    return fontAwesomeIcon(name: name,
                           textColor: textColor,
                           size: CGSize(width: dimension, height: dimension),
                           backgroundColor: backgroundColor)
  }
  
  public static func fontAwesomeIcon(code: String,
                                     textColor: NSColor,
                                     dimension: CGFloat,
                                     backgroundColor: NSColor = NSColor.clear) -> NSImage?
  {
    guard let name = String.fontAwesome(code: code) else { return nil }
    return fontAwesomeIcon(name: name, textColor: textColor, dimension: dimension, backgroundColor: backgroundColor)
  }

  /// Get a FontAwesome image with the given icon name, text color, size and an optional background color.
  ///
  /// - parameter name: The preferred icon name.
  /// - parameter textColor: The text color.
  /// - parameter size: The image size.
  /// - parameter backgroundColor: The background color (optional).
  /// - returns: A string that will appear as icon with FontAwesome
  public static func fontAwesomeIcon(name: FontAwesome,
                                     textColor: NSColor,
                                     size: CGSize,
                                     backgroundColor: NSColor = NSColor.clear) -> NSImage
  {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = NSTextAlignment.center

    // Taken from FontAwesome.io's Fixed Width Icon CSS
    let fontAspectRatio: CGFloat = 1.28571429

    let attributedString: NSAttributedString
    let fontSize = min(size.width / fontAspectRatio, size.height)
    if let font = NSFont.fontAwesome(ofSize: fontSize) {
      attributedString = NSAttributedString(string: String.fontAwesomeIcon(name: name),
          attributes: [NSAttributedStringKey.font: font,
                       NSAttributedStringKey.foregroundColor: textColor,
                       NSAttributedStringKey.backgroundColor: backgroundColor,
                       NSAttributedStringKey.paragraphStyle: paragraph])

    } else {
      attributedString = NSAttributedString(string: "?",
          attributes: [NSAttributedStringKey.foregroundColor: textColor,
                       NSAttributedStringKey.backgroundColor: backgroundColor,
                       NSAttributedStringKey.paragraphStyle: paragraph])
    }

    let image = NSImage(size: size)

    image.lockFocus()
    attributedString.draw(in: CGRect(x: 0, y: (size.height - fontSize) / 2, width: size.width, height: size.height))
    image.unlockFocus()

    let trimmedImage = image.trimming()!
    let trimmedSize = trimmedImage.size

    let result = NSImage(size: size)
    result.lockFocus()
    trimmedImage.draw(at: CGPoint(x: (size.width - trimmedSize.width) / 2, y: (size.height - trimmedSize.height) / 2),
                      from: .zero,
                      operation: .copy,
                      fraction:1)
    result.unlockFocus()

    return result
  }

  /// Get a FontAwesome image with the given icon css code, text color, size and an optional background color.
  ///
  /// - parameter code: The preferred icon css code.
  /// - parameter textColor: The text color.
  /// - parameter size: The image size.
  /// - parameter backgroundColor: The background color (optional).
  /// - returns: A string that will appear as icon with FontAwesome
  public static func fontAwesomeIcon(code: String,
                                     textColor: NSColor,
                                     size: CGSize,
                                     backgroundColor: NSColor = NSColor.clear) -> NSImage?
  {
    guard let name = String.fontAwesome(code: code) else { return nil }
    return fontAwesomeIcon(name: name, textColor: textColor, size: size, backgroundColor: backgroundColor)
  }
}

// MARK: - Private

private class FontLoader {
  class func loadFont(_ name: String) throws {
    let bundle = Bundle(for: FontLoader.self)
    let fontURL = bundle.url(forResource: name, withExtension: "otf")!

    guard
        let data = try? Data(contentsOf: fontURL),
        let provider = CGDataProvider(data: data as CFData),
        let font = CGFont(provider)
        else { return }

    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterGraphicsFont(font, &error) {
      let errorDescription: CFString = CFErrorCopyDescription(error!.takeUnretainedValue())
      guard let nsError = error?.takeUnretainedValue() as AnyObject as? NSError else { return }
      
      throw NSError(domain: "CocoaFontAwesome", code: 0, userInfo: [
        "name": NSExceptionName.internalInconsistencyException,
        "reason": errorDescription as String,
        NSUnderlyingErrorKey: nsError,
      ])
    }
  }
}
