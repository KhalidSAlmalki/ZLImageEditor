//
//  UIScreen+safe area.swift
//  ZLImageEditor
//
//  Created by Khalid S Almalki on 5/17/22.
//

import UIKit

extension UIScreen {

    func heightOfSafeArea() -> CGFloat {
        
        guard let rootView = UIApplication.shared.windows.first(where: \.isKeyWindow) else { return 0 }
        
        return rootView.safeAreaInsets.top
        
    }

}
