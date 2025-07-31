//
//  UIImage+.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import UIKit

extension UIImage {
    func resized(to size: Int) -> UIImage? {
        let _convert_Int_To_Size = CGSize(width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(_convert_Int_To_Size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: _convert_Int_To_Size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
