//
//  EstateDetailViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class EstateDetailViewController: BaseViewController {
    private let estateID: String
    
    // MARK: - ViewModel
    private let viewModel = EstateDetailViewModel()

    
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
    
    // MARK: - ViewModel Binding
    override func bind() {
        let input = EstateDetailViewModel.Input(
            viewDidLoad: .just((estateID))
        )
        
        let output = viewModel.transform(input: input)
        
        /// - 로딩 상태 처리
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    print("🔄 Loading estate detail...")
                } else {
                    print("✅ Estate detail loading finished")
                }
            })
            .disposed(by: viewModel.disposeBag)
        
        /// - 매물 상세 정보 처리
        output.estateDetail
            .drive(onNext: { [weak self] detail in
                guard let detail else { return }
                print(detail)
            })
            .disposed(by: viewModel.disposeBag)
        
        /// - 에러 처리
        output.error
            .drive(onNext: { [weak self] error in
                self?.showAlert(for: error)
            })
            .disposed(by: viewModel.disposeBag)
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
