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
}
