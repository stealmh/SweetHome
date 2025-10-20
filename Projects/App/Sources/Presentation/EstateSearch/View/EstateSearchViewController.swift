//
//  EstateSearchViewController.swift
//  SweetHome
//
//  Created by 김민호 on 9/3/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class EstateSearchViewController: BaseViewController {
    
    private let navigationBar = SHNavigationBar()
    private let searchBar = SHSearchBar()
    private let initialSearchText: String
    private let viewModel = EstateSearchViewModel()
    
    private lazy var collectionView: UICollectionView = {
        let layout = EstateSearchCollectionViewLayout.createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private lazy var dataSource = EstateSearchDataSource(collectionView: collectionView)
    private var searchResults: [Estate] = []
    
    
    private let searchQuerySubject = PublishSubject<String>()
    
    init(searchText: String) {
        self.initialSearchText = searchText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        searchBar.setText(initialSearchText)
        searchQuerySubject.onNext(initialSearchText)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func setupUI() {
        view.addSubviews(navigationBar, searchBar, collectionView)
    }
    
    override func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func bind() {
        let input = EstateSearchViewModel.Input(
            searchQuery: searchQuerySubject.asObservable(),
            onAppear: .just(())
        )
        let output = viewModel.transform(input: input)
        
        navigationBar.backButton.rx.tap
            .subscribe(onNext: { _ in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        searchBar.onSearchCompleted = { [weak self] searchText in
            self?.searchQuerySubject.onNext(searchText)
        }
        
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
//                if isLoading {
//                    self?.showLoading()
//                } else {
//                    self?.hideLoading()
//                }
            })
            .disposed(by: disposeBag)
        
        output.searchResults
            .drive(onNext: { [weak self] results in
                self?.searchResults = results
                self?.dataSource.apply(estates: results)
            })
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { [weak self] error in
                self?.hideLoading()
                print("Search Error: \(error)")
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let estate = self?.searchResults[safe: indexPath.item] else { return }
                print("Selected estate: \(estate.title)")
                // TODO: Navigate to detail view
                // let detailVC = EstateDetailViewController(estate.id)
                // self?.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Private Method
private extension EstateSearchViewController {
    func setNavigationBar() {
        /// - Navigation Bar Hidden 처리
//        navigationController?.setNavigationBarHidden(true, animated: false)
        /// - Navigation Bar Configure
        navigationBar.configure(title: "검색 결과")
    }
    
}


extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
