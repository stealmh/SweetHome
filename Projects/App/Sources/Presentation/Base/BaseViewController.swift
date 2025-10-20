//
//  BaseViewController.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import RxSwift
import RxCocoa

class BaseViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
    }
    
// MARK: - Setup Methods
    func setupUI() { view.backgroundColor = .white }
    func setupConstraints() {}
    func bind() {}
    
    // MARK: - Error Handling
    func showAlert(for error: SHError) {
        guard error.displayType == .toast else { return }
        
        let alert = UIAlertController(title: "오류", message: error.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
