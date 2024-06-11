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
        cgColor.toHex() ?? ""
      }
}

extension CGColor {
    func toHex() -> String? {
        guard let components = components else { return nil }
        
        if components.count == 2 {
            let value = components[0]
            let alpha = components[1]
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(alpha*255)), lroundf(Float(value*255)), lroundf(Float(value*255)), lroundf(Float(value*255)))
        }
        
        guard components.count == 4 else { return nil }
        
        let red   = components[0]
        let green = components[1]
        let blue  = components[2]
        let alpa  = components[3]
        
        let hexString = String(format: "#%02lX%02lX%02lX%02lX",lroundf(Float(alpa*255)), lroundf(Float(red*255)), lroundf(Float(green*255)), lroundf(Float(blue*255)))
        
        return hexString
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

