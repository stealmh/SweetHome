//
//  EstateDetailOptionCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailOptionCell: UICollectionViewCell {
    static let identifier = "EstateDetailOptionCell"
    
    /// - 1행
    private let refrigeratorView = EstateDetailOptionView()
    private let washerView = EstateDetailOptionView()
    private let airConditionerView = EstateDetailOptionView()
    private let closetView = EstateDetailOptionView()
    
    /// - 2행
    private let shoeRackView = EstateDetailOptionView()
    private let microwaveView = EstateDetailOptionView()
    private let sinkView = EstateDetailOptionView()
    private let tvView = EstateDetailOptionView()
    
    /// - StackViews
    private lazy var firstRowStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [refrigeratorView, washerView, airConditionerView, closetView])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 28
        return stackView
    }()
    
    private lazy var secondRowStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [shoeRackView, microwaveView, sinkView, tvView])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 28
        return stackView
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [firstRowStackView, secondRowStackView])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
}
/// - Private
private extension EstateDetailOptionCell {
    func setupUI() {
        contentView.addSubview(mainStackView)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = SHColor.GrayScale.gray_30.cgColor
    }
    
    func setupConstraints() {
        mainStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(20)
            $0.leading.trailing.equalToSuperview().inset(25)
        }
    }
}
/// - Public
extension EstateDetailOptionCell {
    func configure(with options: EstateOptions) {
        /// - 1행 옵션
        refrigeratorView.configure(
            optionImage: SHAsset.Option.refrigerator,
            optionName: "냉장고",
            hasOption: options.refrigerator
        )
        
        washerView.configure(
            optionImage: SHAsset.Option.washingMachine,
            optionName: "세탁기",
            hasOption: options.washer
        )
        
        airConditionerView.configure(
            optionImage: SHAsset.Option.airConditioner,
            optionName: "에어컨",
            hasOption: options.airConditioner
        )
        
        closetView.configure(
            optionImage: SHAsset.Option.closet,
            optionName: "옷장",
            hasOption: options.closet
        )
        
        /// - 2행 옵션
        shoeRackView.configure(
            optionImage: SHAsset.Option.shoeCabinet,
            optionName: "신발장",
            hasOption: options.shoeRack
        )
        
        microwaveView.configure(
            optionImage: SHAsset.Option.microwave,
            optionName: "전자레인지",
            hasOption: options.microwave
        )
        
        sinkView.configure(
            optionImage: SHAsset.Option.sink,
            optionName: "싱크대",
            hasOption: options.sink
        )
        
        tvView.configure(
            optionImage: SHAsset.Option.television,
            optionName: "TV",
            hasOption: options.tv
        )
    }
}
