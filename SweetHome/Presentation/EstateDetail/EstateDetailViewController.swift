//
//  EstateDetailViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
import SnapKit

class EstateDetailViewController: BaseViewController {
    private let estateID: String
    
    init(_ id: String) {
        self.estateID = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        setupNavigationBar()
    }
    
    override func setupConstraints() {
    }
    
    @objc func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
}

extension EstateDetailViewController {
    func setupNavigationBar() {
        navigationItem.title = "매물 상세"
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )
        backButton.tintColor = SHColor.GrayScale.gray_15
        navigationItem.leftBarButtonItem = backButton
    }
}
