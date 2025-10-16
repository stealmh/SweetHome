//
//  UIImage+.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import UIKit
import ImageIO

extension UIImage {
    /// 이미 메모리에 로드된 이미지를 정사각형으로 리사이징
    /// - Parameter size: 목표 크기 (정사각형)
    /// - Returns: 리사이징된 이미지
    func resized(to size: Int) -> UIImage? {
        let _convert_Int_To_Size = CGSize(width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(_convert_Int_To_Size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: _convert_Int_To_Size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 이미지 데이터를 다운샘플링
    /// 원본을 메모리에 로드하지 않고 지정한 크기로 decode
    /// - Parameters:
    ///   - data: 원본 이미지 데이터
    ///   - targetSize: 목표 크기 (긴 쪽 기준으로 비율 유지)
    /// - Returns: 다운샘플링된 이미지
    static func downsample(from data: Data, to targetSize: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 목표 파일 크기에 맞춰 압축
    /// 압축률을 점진적으로 낮춰가며 목표 크기에 도달
    /// - Parameter maxSizeBytes: 최대 파일 크기 (기본값: 1MB)
    /// - Returns: 압축된 이미지 데이터
    func adaptiveCompress(maxSizeBytes: Int = 1024 * 1024) -> Data? {
        var compression: CGFloat = 0.8
        var imageData = self.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxSizeBytes && compression > 0.1 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}
