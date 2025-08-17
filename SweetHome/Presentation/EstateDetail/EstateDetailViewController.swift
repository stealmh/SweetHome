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

class EstateDetailViewController: BaseViewController, UICollectionViewDelegate, EstateDetailCollectionViewLayoutDelegate {
    private let estateID: String
    private let detailNavigationBar = EstateDetailNavigationBar()
    
    // MARK: - ViewModel
    private let viewModel = EstateDetailViewModel()
    
    // MARK: - Layout & DataSource
    private var layoutManager: EstateDetailCollectionViewLayout!
    private var dataSourceManager: EstateDetailCollectionViewDataSource!
    
    enum Section: Int, CaseIterable {
        case banner
        case topInfo
        case options
        case description
        case similar
        case broker
    }
    
    enum Item: Hashable {
        case image(String, uniqueID: String)
        case topInfo(DetailEstate)
        case options(EstateOptions)
        case description(String)
        case broker(DetailEstate)
        case similarEstate(Estate)
    }
    
    private lazy var collectionView: UICollectionView = {
        layoutManager = EstateDetailCollectionViewLayout(delegate: self)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layoutManager.createLayout())
        cv.isPagingEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.bounces = false
        cv.alwaysBounceVertical = false
        cv.alwaysBounceHorizontal = false
        cv.isScrollEnabled = true
        cv.register(EstateDetailBannerCell.self, forCellWithReuseIdentifier: EstateDetailBannerCell.identifier)
        cv.register(EstateDetailBannerFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: EstateDetailBannerFooterView.identifier)
        cv.register(EstateSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EstateSectionHeaderView.identifier)
        cv.register(EstateDetailOptionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: EstateDetailOptionFooterView.identifier)
        cv.register(EstateDetailTopCell.self, forCellWithReuseIdentifier: EstateDetailTopCell.identifier)
        cv.register(EstateDetailOptionCell.self, forCellWithReuseIdentifier: EstateDetailOptionCell.identifier)
        cv.register(EstateDetailDescriptionCell.self, forCellWithReuseIdentifier: EstateDetailDescriptionCell.identifier)
        cv.register(EstateDetailBrokerCell.self, forCellWithReuseIdentifier: EstateDetailBrokerCell.identifier)
        cv.register(RecentSearchEstateViewCell.self, forCellWithReuseIdentifier: RecentSearchEstateViewCell.identifier)
        cv.register(EstateDetailSimilarFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: EstateDetailSimilarFooterView.identifier)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubviews(collectionView, detailNavigationBar, pageControl, imageCountTagView)
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
        collectionView.delegate = self
        setupScrollObserver()
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
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        /// - PageControl (배너 섹션 위에 overlay)
        pageControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(56 + 250 - 22) // NavigationBar + 배너 하단 - 22
            $0.centerX.equalToSuperview()
            $0.height.equalTo(6)
        }
        /// - ImageCountTagView (배너 섹션 위에 overlay)
        imageCountTagView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(56 + 250 - 40) // NavigationBar + 배너 하단 - 40
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
                self?.setupBannerSectionItem(detail.thumbnails, likeCount: detail.likeCount)
                self?.setupTopInfoSection(detail)
                self?.setupOptionsSection(detail.options, parkingCount: detail.parkingCount)
                self?.setupDescriptionSection(detail.description)
                self?.setupBrokerSection(detail)
            })
            .disposed(by: disposeBag)
            
        /// - 유사한 매물 정보 처리
        output.similarEstates
            .drive(onNext: { [weak self] estates in
                self?.setupSimilarSection(estates)
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
    private func setupBannerSectionItem(_ images: [String], likeCount: Int = 0) {
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
        dataSourceManager.updateSnapshot(bannerItems: bannerItems, likeCount: likeCount)
    }
    
    private func setupTopInfoSection(_ detail: DetailEstate) {
        let topInfoItem = Item.topInfo(detail)
        dataSourceManager.updateTopInfoSnapshot(topInfoItem: topInfoItem)
    }
    
    private func setupOptionsSection(_ options: EstateOptions, parkingCount: Int) {
        let optionsItem = Item.options(options)
        dataSourceManager.updateOptionsSnapshot(optionsItem: optionsItem, parkingCount: parkingCount)
    }
    
    private func setupDescriptionSection(_ description: String) {
        let descriptionItem = Item.description(description)
        dataSourceManager.updateDescriptionSnapshot(descriptionItem: descriptionItem)
    }
    
    private func setupBrokerSection(_ detail: DetailEstate) {
        let brokerItem = Item.broker(detail)
        dataSourceManager.updateBrokerSnapshot(brokerItem: brokerItem)
    }
    
    private func setupSimilarSection(_ estates: [Estate]) {
        let similarItems = estates.map { Item.similarEstate($0) }
        dataSourceManager.updateSimilarSnapshot(similarItems: similarItems)
    }
    
    @objc private func pageControlValueChanged() {
        /// - PageControl 탭 시 해당 이미지로 스크롤
        let targetPage = pageControl.currentPage
        currentImageIndex = targetPage
        /// - 이미지 카운트 태그 업데이트 (1-based 인덱스)
        imageCountTagView.configure(currentIndex: targetPage + 1, totalCount: thumbnailsCount)
        
        /// - orthogonalScrollingBehavior 환경에서는 scrollToItem 사용
        collectionView.scrollToItem(
            at: IndexPath(item: targetPage, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    /// - 스크롤 추적을 위한 Observer 설정
    private func setupScrollObserver() {
        collectionView.rx.contentOffset
            .subscribe(onNext: { [weak self] offset in
                self?.updateOverlayPositions(for: offset.y)
            })
            .disposed(by: disposeBag)
    }
    
    /// - 스크롤에 따른 pageControl과 imageCountTagView 위치 업데이트
    private func updateOverlayPositions(for scrollY: CGFloat) {
        let bannerHeight: CGFloat = 250
        let navigationBarHeight: CGFloat = 56
        
        /// - pageControl과 imageCountTagView의 초기 위치 (safeArea 기준)
        let pageControlInitialY = navigationBarHeight + bannerHeight - 22
        let imageCountTagInitialY = navigationBarHeight + bannerHeight - 40
        
        /// - 스크롤에 따른 새로운 위치 계산
        let pageControlNewY = pageControlInitialY - scrollY
        let imageCountTagNewY = imageCountTagInitialY - scrollY
        
        /// - NavigationBar 아래로 내려가지 않도록 제한
        let pageControlFinalY = max(pageControlNewY, navigationBarHeight + 10)
        let imageCountTagFinalY = max(imageCountTagNewY, navigationBarHeight + 10)
        
        /// - 즉각적으로 위치 업데이트
        pageControl.snp.updateConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(pageControlFinalY)
        }
        
        imageCountTagView.snp.updateConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(imageCountTagFinalY)
        }
        
        /// - 원래 위치에서 벗어나기 시작하면 숨기기
        let pageControlShouldHide = pageControlNewY < navigationBarHeight + 10
        let imageCountTagShouldHide = imageCountTagNewY < navigationBarHeight + 10
        
        pageControl.isHidden = pageControlShouldHide
        imageCountTagView.isHidden = imageCountTagShouldHide
    }
    
}

// MARK: - EstateDetailCollectionViewLayoutDelegate
extension EstateDetailViewController {
    func bannerDidScroll(to page: Int, offset: CGPoint) {
        guard page >= 0 && page < thumbnailsCount else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pageControl.currentPage = page
            self.currentImageIndex = page
            self.imageCountTagView.configure(currentIndex: page + 1, totalCount: self.thumbnailsCount)
        }
    }
}
