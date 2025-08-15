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

class EstateDetailViewController: BaseViewController, UICollectionViewDelegate {
    private let estateID: String
    private let detailNavigationBar = EstateDetailNavigationBar()
    
    // MARK: - ViewModel
    private let viewModel = EstateDetailViewModel()
    
    // MARK: - Layout & DataSource
    private var layoutManager: EstateDetailCollectionViewLayout!
    private var dataSourceManager: EstateDetailCollectionViewDataSource!
    
    enum Section: Int, CaseIterable {
        case banner
    }
    
    enum Item: Hashable {
        case image(String, uniqueID: String)
    }
    
    private lazy var collectionView: UICollectionView = {
        layoutManager = EstateDetailCollectionViewLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layoutManager.createLayout())
        /// - 수평 페이징 스크롤 활성화
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        /// - 경계에서 바운스 효과 완전 제거 (하얀색 배경 방지)
        cv.bounces = false
        cv.alwaysBounceVertical = false
        cv.alwaysBounceHorizontal = false
        cv.isScrollEnabled = true
        cv.register(EstateDetailImageCell.self, forCellWithReuseIdentifier: EstateDetailImageCell.identifier)
        
        dataSourceManager = EstateDetailCollectionViewDataSource(collectionView: cv)
        return cv
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = SHColor.GrayScale.gray_15
        pc.pageIndicatorTintColor = SHColor.GrayScale.gray_60
        pc.numberOfPages = 0
        pc.currentPage = 0
        return pc
    }()
    
    /// - 현재 이미지 인덱스 표시 태그
    private let imageCountTagView = ImageCountTagView()
    
    private var currentImageIndex = 0
    /// - ViewModel에서 제공하는 이미지 개수
    private var thumbnailsCount = 0

    
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
        view.addSubviews(collectionView, detailNavigationBar, pageControl, imageCountTagView)
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
        collectionView.delegate = self
    }
    
    override func setupConstraints() {
        /// - NavigationBar
        detailNavigationBar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
        /// - CollectionView
        collectionView.snp.makeConstraints {
            $0.top.equalTo(detailNavigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(250)
        }
        /// - PageControl
        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(collectionView.snp.bottom).inset(16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(6)
        }
        /// - ImageCountTagView (우측 하단)
        imageCountTagView.snp.makeConstraints {
            $0.trailing.equalTo(collectionView.snp.trailing).inset(16)
            $0.bottom.equalTo(collectionView.snp.bottom).inset(16)
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
                self?.setupBannerImages(detail.thumbnails)
            })
            .disposed(by: disposeBag)
            
        /// - 이미지 개수 정보 처리
        output.thumbnailsCount
            .drive(onNext: { [weak self] count in
                self?.thumbnailsCount = count
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
    private func setupBannerImages(_ images: [String]) {
        /// - PageControl 설정 (ViewModel에서 개수 관리)
        self.pageControl.numberOfPages = images.count
        self.pageControl.currentPage = 0
        /// - 이미지 카운트 태그 초기 설정
        self.imageCountTagView.configure(currentIndex: 1, totalCount: images.count)
        /// - 이미지 URL을 CollectionView Item으로 변환
        let bannerItems = images.enumerated().map { index, imageUrl in
            Item.image(imageUrl, uniqueID: "image_\(index)")
        }
        /// - DiffableDataSource 업데이트
        dataSourceManager.updateSnapshot(bannerItems: bannerItems)
    }
    
    @objc private func pageControlValueChanged() {
        /// - PageControl 탭 시 해당 이미지로 스크롤
        let targetPage = pageControl.currentPage
        currentImageIndex = targetPage
        /// - 이미지 카운트 태그 업데이트 (1-based 인덱스)
        imageCountTagView.configure(currentIndex: targetPage + 1, totalCount: thumbnailsCount)
        collectionView.scrollToItem(
            at: IndexPath(item: targetPage, section: 0),
            at: .left,
            animated: true
        )
    }
    
    private func updatePageControlFromScroll(currentPage: Int) {
        /// - 스크롤 위치에 따른 PageControl 업데이트
        guard currentPage >= 0 && currentPage < thumbnailsCount else { return }
        pageControl.currentPage = currentPage
        currentImageIndex = currentPage
        /// - 이미지 카운트 태그 업데이트 (1-based 인덱스)
        imageCountTagView.configure(currentIndex: currentPage + 1, totalCount: thumbnailsCount)
    }
}

// MARK: - UIScrollViewDelegate
extension EstateDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        
        let currentOffsetX = scrollView.contentOffset.x
        let frameWidth = scrollView.frame.width
        let contentWidth = scrollView.contentSize.width
        let maxOffsetX = max(0, contentWidth - frameWidth)
        let currentPage = Int(round(currentOffsetX / frameWidth))
        
        /// - 첫 번째 이미지에서 왼쪽으로 스크롤 방지 (하얀색 배경 차단)
        if currentOffsetX < 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y), animated: false)
        }
        /// - 마지막 이미지에서 오른쪽으로 스크롤 방지 (하얀색 배경 차단)
        if currentOffsetX > maxOffsetX {
            scrollView.setContentOffset(CGPoint(x: maxOffsetX, y: scrollView.contentOffset.y), animated: false)
        }
        /// - 스크롤 위치에 따른 PageControl 실시간 업데이트
        if currentPage >= 0 && currentPage < thumbnailsCount {
            updatePageControlFromScroll(currentPage: currentPage)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        /// - 사용자 드래그 시작 시점 감지
        guard scrollView == collectionView else { return }
        let currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        /// - 사용자 드래그 종료 시점 감지
        guard scrollView == collectionView else { return }
        let currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
}

