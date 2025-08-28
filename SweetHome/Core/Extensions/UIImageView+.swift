//
//  UIImageView+.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import Kingfisher

enum DefaultImageType {
    case estate
    case profile
    
    var image: UIImage? {
        switch self {
        case .estate:
            return SHAsset.Default.defaultEstate
        case .profile:
            return SHAsset.Default.defaultImage
        }
    }
}

extension UIImageView {
    
    /// 인증 헤더가 포함된 이미지 로딩
    func setAuthenticatedImage(
        with url: URL?,
        defaultImageType: DefaultImageType = .estate,
        completion: (() -> Void)? = nil
    ) {
        let defaultImage = defaultImageType.image
        
        guard let url else {
            self.image = defaultImage
            completion?()
            return
        }
        
        guard let accessToken = AuthTokenManager.shared.accessToken else {
            self.image = defaultImage
            completion?()
            return
        }
        
        /// - modifier 생성
        let modifier = AnyModifier { request in
            var req = request
            req.setValue(accessToken, forHTTPHeaderField: "Authorization")
            req.setValue(AuthTokenManager.shared.sesacKey, forHTTPHeaderField: "SeSACKey")
            return req
        }
        
        /// - option 설정
        let options: KingfisherOptionsInfo = [
            .requestModifier(modifier),
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ]
        
        self.kf.setImage(with: url, placeholder: defaultImage, options: options) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageResult):
                    completion?()
                case .failure(let error):
                    print("❌ Kingfisher 이미지 로딩 실패: \(error.localizedDescription)")
                    completion?()
                }
            }
        }
    }
    
    /// 상대경로를 완전한 URL로 변환하여 인증된 이미지 로딩
    func setAuthenticatedImage(
        with relativePath: String?,
        defaultImageType: DefaultImageType = .estate
    ) {
        var url: URL?
        
        if let path = relativePath {
            url = URL(string: APIConstants.baseURL + "/v1" + path)
            setAuthenticatedImage(with: url, defaultImageType: defaultImageType)
        } else {
            setAuthenticatedImage(with: url, defaultImageType: defaultImageType)
        }
    }
    
    /// 상대경로를 완전한 URL로 변환하여 인증된 이미지 로딩 (completion 지원)
    func setAuthenticatedImage(
        with relativePath: String?,
        defaultImageType: DefaultImageType = .estate,
        completion: (() -> Void)? = nil) {
        guard let relativePath else {
            completion?()
            return 
        }
        let url = URL(string: APIConstants.baseURL + "/v1" + relativePath)
        setAuthenticatedImage(with: url, defaultImageType: defaultImageType, completion: completion)
    }
}
