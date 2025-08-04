//
//  SHIndicator.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
import SnapKit

final class SHIndicator {
    static let shared = SHIndicator()

    private var overlayView: UIView?
    private var activityIndicator: UIActivityIndicatorView?

    private init() {}

    func show() {
        guard overlayView == nil else { return }

        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first else {
            return
        }

        // Full white background overlay
        let overlay = UIView()
        overlay.backgroundColor = .white
        overlay.alpha = 0

        // Activity indicator
        let indicator = UIActivityIndicatorView(style: .large)
        if #available(iOS 13.0, *) {
            indicator.color = SHColor.Brand.brightWood
        } else {
            indicator.color = .systemBlue
        }
        indicator.startAnimating()

        // Setup hierarchy
        window.addSubview(overlay)
        overlay.addSubview(indicator)

        // Setup constraints
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Store references
        self.overlayView = overlay
        self.activityIndicator = indicator

        // Animate in
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1.0
        }
    }

    func hide() {
        guard let overlay = overlayView else { return }

        UIView.animate(withDuration: 0.3, animations: {
            overlay.alpha = 0.0
        }, completion: { _ in
            self.activityIndicator?.stopAnimating()
            overlay.removeFromSuperview()
            self.overlayView = nil
            self.activityIndicator = nil
        })
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    
    func showLoading() {
        SHIndicator.shared.show()
    }
    
    func hideLoading() {
        SHIndicator.shared.hide()
    }
}