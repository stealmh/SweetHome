//
//  ImageCache.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // 메모리 제한 설정 (50MB)
        cache.totalCostLimit = 50 * 1024 * 1024
        cache.countLimit = 100
    }
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // 대략적인 메모리 사용량
        cache.setObject(image, forKey: NSString(string: key), cost: cost)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
