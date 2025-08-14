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
    private let detailNavigationBar = EstateDetailNavigationBar()
    
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
        view.addSubviews(detailNavigationBar)
    }
    
    override func setupConstraints() {
        detailNavigationBar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
    }
    
    // MARK: - ViewModel Binding
    override func bind() {
        let input = EstateDetailViewModel.Input(
            viewDidLoad: .just((estateID)),
            favoriteButtonTapped: detailNavigationBar.favoriteButton.rx.tap.asObservable(),
            backButtonTapped: detailNavigationBar.backButton.rx.tap.asObservable()
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
            .disposed(by: disposeBag)
        /// - 매물 상세 정보 처리
        output.estateDetail
            .drive(onNext: { [weak self] detail in
                guard let detail else { return }
                self?.detailNavigationBar.configure(detail)
            })
            .disposed(by: disposeBag)
        /// - 뒤로가기 버튼 눌렀을 때
        output.backButtonTappedResult
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        /// - 에러 처리
        output.error
            .drive(onNext: { [weak self] error in
                self?.showAlert(for: error)
            })
            .disposed(by: disposeBag)
    }
}

extension EstateDetailViewController {
}
