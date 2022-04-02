//
//  Color+String.swift
//  ZLImageEditor
//
//  Created by Khalid S Almalki on 4/2/22.
//

import UIKit

extension String {
    func colorWithHexString() -> UIColor {
  
        let scanner = Scanner(string: self.removeSpecialCharsFromString())
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        return UIColor(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
    
    func removeSpecialCharsFromString() -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return String(self.filter {okayChars.contains($0) })
    }
}

extension UIColor {
    func toHexString() -> String {
        return String(format: "#%06x", toHex())
    }
    
    func toHex() -> UInt32 {
        let rgba = toRGBAComponents()
        
        return roundToHex(rgba.r) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.b)
    }
    
    final func toRGBAComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
#if os(iOS) || os(tvOS) || os(watchOS)
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (r, g, b, a)
#elseif os(OSX)
        guard let rgbaColor = self.usingColorSpace(.deviceRGB) else {
            fatalError("Could not convert color to RGBA.")
        }
        
        rgbaColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (r, g, b, a)
#endif
    }
}

func roundToHex(_ x: CGFloat) -> UInt32 {
    guard x > 0 else { return 0 }
    let rounded: CGFloat = round(x * 255.0)
    
    return UInt32(rounded)
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

