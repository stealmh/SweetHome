//
//  HomeViewController.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class HomeViewController: BaseViewController {
    private let searchBar = SHSearchBar()
    
    // Section 정의
    enum Section: Int, CaseIterable {
        case banner
    }
    
    // Item 정의
    enum Item: Hashable {
        case estate(Estate, uniqueID: String)
    }
    
    // 컬렉션 뷰와 페이지 컨트롤
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.bounces = true
        cv.alwaysBounceVertical = false
        cv.alwaysBounceHorizontal = false
        cv.isScrollEnabled = true
        cv.register(BannerCollectionViewCell.self, forCellWithReuseIdentifier: BannerCollectionViewCell.identifier)
        cv.register(BannerFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BannerFooterView.identifier)
        return cv
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            switch item {
            case .estate(let estate, _):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCollectionViewCell.identifier, for: indexPath) as! BannerCollectionViewCell
                cell.configure(with: estate)
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionFooter {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: BannerFooterView.identifier,
                    for: indexPath
                ) as! BannerFooterView
                return footer
            }
            return nil
        }
        
        return dataSource
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = SHColor.GrayScale.gray_15
        pc.pageIndicatorTintColor = SHColor.GrayScale.gray_60
        pc.numberOfPages = 0
        pc.currentPage = 0
        return pc
    }()
    
    private let viewModel = HomeViewModel()
    private var estates: [Estate] = []
    private var infiniteArray: [Estate] = []
    private var currentAutoScrollIndex = 1
    
    private let startAutoScrollSubject = PublishSubject<Void>()
    private let stopAutoScrollSubject = PublishSubject<Void>()
    private let userScrollingSubject = BehaviorSubject<Bool>(value: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.addSubviews(collectionView, searchBar, pageControl)
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
    }
    
    override func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalTo(view)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            //            $0.height.equalTo(335)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(getStatusBarHeight() + 3)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.top).offset(335 - 16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(6)
        }
    }
    
    override func bind() {
        let input = HomeViewModel.Input(
            onAppear: .just(()),
            startAutoScroll: startAutoScrollSubject.asObservable(),
            stopAutoScroll: stopAutoScrollSubject.asObservable(),
            userScrolling: userScrollingSubject.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.todayEstates
            .skip(1)
            .drive(onNext: { [weak self] estates in
                guard let self else { return }
                self.estates = estates
                self.infiniteArray = self.createInfiniteArray(estates)
                self.pageControl.numberOfPages = estates.count
                self.pageControl.currentPage = 0
                self.updateSnapshot()
                
                if !self.infiniteArray.isEmpty {
                    DispatchQueue.main.async {
                        self.currentAutoScrollIndex = 1
                        self.collectionView.scrollToItem(
                            at: IndexPath(item: 1, section: 0),
                            at: .left,
                            animated: false
                        )
                        self.startAutoScrollSubject.onNext(())
                    }
                }
            })
            .disposed(by: disposeBag)
        
        output.autoScrollTrigger
            .drive(onNext: { [weak self] _ in
                self?.moveToNextPage()
            })
            .disposed(by: disposeBag)
    }
    
    private func moveToNextPage() {
        guard !infiniteArray.isEmpty else { return }
        
        currentAutoScrollIndex += 1
        
        if currentAutoScrollIndex >= infiniteArray.count - 1 {
            currentAutoScrollIndex = 1
        }
        
        collectionView.scrollToItem(
            at: IndexPath(item: currentAutoScrollIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    private func createInfiniteArray(_ items: [Estate]) -> [Estate] {
        guard !items.isEmpty else { return [] }
        
        var infiniteArray: [Estate] = []
        let count = items.count
        
        infiniteArray.append(items[count - 1])
        infiniteArray.append(contentsOf: items)
        infiniteArray.append(items[0])
        
        return infiniteArray
    }
    
    
    @objc private func pageControlValueChanged() {
        userScrollingSubject.onNext(true)
        
        let targetPage = pageControl.currentPage
        let targetIndex = targetPage + 1
        
        if targetIndex < infiniteArray.count {
            currentAutoScrollIndex = targetIndex
            collectionView.scrollToItem(
                at: IndexPath(item: targetIndex, section: 0),
                at: .left,
                animated: true
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.userScrollingSubject.onNext(false)
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            switch Section.allCases[sectionIndex] {
            case .banner:
                return self.createBannerSection()
            }
        }
    }
    
    private func createBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(335)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        
        section.visibleItemsInvalidationHandler = { [weak self] items, contentOffset, environment in
            guard let self = self else { return }
            
            let pageWidth = environment.container.contentSize.width
            let currentPage = Int(contentOffset.x / pageWidth)
            
            if self.currentAutoScrollIndex != currentPage {
                self.userScrollingSubject.onNext(true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.userScrollingSubject.onNext(false)
                }
            }
            
            self.currentAutoScrollIndex = currentPage
            
            if currentPage == 0 && !self.infiniteArray.isEmpty {
                DispatchQueue.main.async {
                    let targetIndex = self.infiniteArray.count - 2
                    self.currentAutoScrollIndex = targetIndex
                    self.collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .left, animated: false)
                }
            } else if currentPage == self.infiniteArray.count - 1 && !self.infiniteArray.isEmpty {
                DispatchQueue.main.async {
                    self.currentAutoScrollIndex = 1
                    self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .left, animated: false)
                }
            }
            
            self.updatePageControlFromOrthogonal(currentPage: currentPage)
        }
        
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        
        return section
    }
    
    private func updatePageControlFromOrthogonal(currentPage: Int) {
        guard !estates.isEmpty else { return }
        
        let actualPage: Int
        
        if currentPage == 0 {
            actualPage = estates.count - 1
        } else if currentPage <= estates.count {
            actualPage = currentPage - 1
        } else {
            actualPage = 0
        }
        
        pageControl.currentPage = actualPage
    }
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        
        let bannerItems = infiniteArray.enumerated().map { index, estate in
            Item.estate(estate, uniqueID: "\(estate.id)_\(index)")
        }
        snapshot.appendItems(bannerItems, toSection: .banner)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

