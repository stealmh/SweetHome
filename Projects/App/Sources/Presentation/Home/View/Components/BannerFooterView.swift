//
//  BannerFooterView.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit

class BannerFooterView: UICollectionReusableView {
    static let identifier = "BannerFooterView"
    
    private let oneRoomButton = EstateTypeButton(type: .oneRoom)
    private let officettelButton = EstateTypeButton(type: .officetel)
    private let apartmentButton = EstateTypeButton(type: .apartment)
    private let villaButton = EstateTypeButton(type: .villa)
    private let commercialButton = EstateTypeButton(type: .commercial)
    
    var buttonTapped: ((BannerEstateType) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupButtonActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BannerFooterView {
    func setupUI() {
        backgroundColor = .white
        
        addSubview(oneRoomButton)
        addSubview(officettelButton)
        addSubview(apartmentButton)
        addSubview(villaButton)
        addSubview(commercialButton)
    }
    
    func setupConstraints() {
        let sideMargin: CGFloat = 20
        let buttonSpacing: CGFloat = 17.5
        let totalWidth = UIScreen.main.bounds.width
        let availableWidth = totalWidth - (sideMargin * 2) - (buttonSpacing * 4)
        let buttonWidth = availableWidth / 5
        
        oneRoomButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(sideMargin)
            $0.width.equalTo(buttonWidth)
            $0.bottom.equalToSuperview().inset(20)
        }
        
        officettelButton.snp.makeConstraints {
            $0.top.equalTo(oneRoomButton)
            $0.leading.equalTo(oneRoomButton.snp.trailing).offset(buttonSpacing)
            $0.width.equalTo(buttonWidth)
            $0.bottom.equalTo(oneRoomButton)
        }
        
        apartmentButton.snp.makeConstraints {
            $0.top.equalTo(oneRoomButton)
            $0.leading.equalTo(officettelButton.snp.trailing).offset(buttonSpacing)
            $0.width.equalTo(buttonWidth)
            $0.bottom.equalTo(oneRoomButton)
        }
        
        villaButton.snp.makeConstraints {
            $0.top.equalTo(oneRoomButton)
            $0.leading.equalTo(apartmentButton.snp.trailing).offset(buttonSpacing)
            $0.width.equalTo(buttonWidth)
            $0.bottom.equalTo(oneRoomButton)
        }
        
        commercialButton.snp.makeConstraints {
            $0.top.equalTo(oneRoomButton)
            $0.leading.equalTo(villaButton.snp.trailing).offset(buttonSpacing)
            $0.width.equalTo(buttonWidth)
            $0.trailing.equalToSuperview().inset(sideMargin)
            $0.bottom.equalTo(oneRoomButton)
        }
    }
    
    func setupButtonActions() {
        oneRoomButton.onTapped = { [weak self] in
            self?.buttonAction(type: .oneRoom)
        }
        
        officettelButton.onTapped = { [weak self] in
            self?.buttonAction(type: .officetel)
        }
        
        apartmentButton.onTapped = { [weak self] in
            self?.buttonAction(type: .apartment)
        }
        
        villaButton.onTapped = { [weak self] in
            self?.buttonAction(type: .villa)
        }
        
        commercialButton.onTapped = { [weak self] in
            self?.buttonAction(type: .commercial)
        }
    }
    
    func buttonAction(type: BannerEstateType) {
        buttonTapped?(type)
    }
}
