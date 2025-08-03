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
    
    // 컬렉션 뷰와 페이지 컨트롤
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.bounces = true
        cv.alwaysBounceVertical = false
        cv.alwaysBounceHorizontal = true
        cv.isScrollEnabled = true
        cv.register(BannerCollectionViewCell.self, forCellWithReuseIdentifier: BannerCollectionViewCell.identifier)
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
    
    private let viewModel = HomeViewModel()
    private var estates: [Estate] = []
    private var infiniteArray: [Estate] = []
    
    private let startAutoScrollSubject = PublishSubject<Void>()
    private let stopAutoScrollSubject = PublishSubject<Void>()
    private let userScrollingSubject = BehaviorSubject<Bool>(value: false)

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.addSubviews(collectionView, searchBar, pageControl)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 335)
        }
    }
    
    override func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(335)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(getStatusBarHeight() + 3)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(collectionView.snp.bottom).inset(16)
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
                self.collectionView.reloadData()
                
                if !self.infiniteArray.isEmpty {
                    DispatchQueue.main.async {
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
        
        let pageWidth = collectionView.frame.width
        let currentIndex = Int(collectionView.contentOffset.x / pageWidth)
        let nextIndex = currentIndex + 1
        
        if nextIndex < infiniteArray.count {
            collectionView.scrollToItem(
                at: IndexPath(item: nextIndex, section: 0),
                at: .left,
                animated: true
            )
        }
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
    
    private func updatePageControl() {
        guard !estates.isEmpty else { return }
        let pageWidth = collectionView.frame.width
        let currentIndex = Int(collectionView.contentOffset.x / pageWidth)
        
        let actualPage: Int
        
        if currentIndex == 0 {
            actualPage = estates.count - 1
        } else if currentIndex <= estates.count {
            actualPage = currentIndex - 1
        } else {
            actualPage = 0
        }
        
        pageControl.currentPage = actualPage
    }
    
    @objc private func pageControlValueChanged() {
        userScrollingSubject.onNext(true)
        
        let targetPage = pageControl.currentPage
        let targetIndex = targetPage + 1
        
        if targetIndex < infiniteArray.count {
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
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infiniteArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCollectionViewCell.identifier, for: indexPath) as! BannerCollectionViewCell
        
        if indexPath.item < infiniteArray.count {
            cell.configure(with: infiniteArray[indexPath.item])
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userScrollingSubject.onNext(true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleInfiniteScroll()
        updatePageControl()
        userScrollingSubject.onNext(false)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        handleInfiniteScroll()
        updatePageControl()
    }
    
    private func handleInfiniteScroll() {
        guard !infiniteArray.isEmpty else { return }
        let pageWidth = collectionView.frame.width
        let currentIndex = Int(collectionView.contentOffset.x / pageWidth)
        
        if currentIndex == 0 {
            let targetIndex = infiniteArray.count - 2
            collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .left, animated: false)
        }

        if currentIndex == infiniteArray.count - 1 {
            collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .left, animated: false)
        }
    }
}

