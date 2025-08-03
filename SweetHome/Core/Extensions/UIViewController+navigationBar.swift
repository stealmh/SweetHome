//
//  UIViewController+navigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import UIKit
import SnapKit

extension UIViewController {
    func setupNavigationBar(title: String? = nil) {
        navigationItem.hidesBackButton = true
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = SHColor.Brand.deepWood
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
        
        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
        
        if let title = title {
            let v = UILabel()
            v.text = title
            v.setFont(.pretendard(.semiBold), size: .body1)
            v.textColor = SHColor.Brand.deepWood
            v.textAlignment = .center
            navigationItem.titleView = v
        } else {
            navigationItem.titleView = nil
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
