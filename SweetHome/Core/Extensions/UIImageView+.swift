//
//  UIImageView+.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    /// 인증 헤더가 포함된 이미지 로딩
    func setAuthenticatedImage(with url: URL?, completion: (() -> Void)? = nil) {
        // 기본 이미지 고정
        let defaultImage = UIImage(systemName: "house.fill")
        
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
    func setAuthenticatedImage(with relativePath: String?) {
        guard let relativePath else { return }
        let url = URL(string: APIConstants.baseURL + "/v1" + relativePath)
        setAuthenticatedImage(with: url)
    }
    
    /// 상대경로를 완전한 URL로 변환하여 인증된 이미지 로딩 (completion 지원)
    func setAuthenticatedImage(with relativePath: String?, completion: (() -> Void)? = nil) {
        guard let relativePath else { 
            completion?()
            return 
        }
        let url = URL(string: APIConstants.baseURL + relativePath)
        setAuthenticatedImage(with: url, completion: completion)
    }
}
