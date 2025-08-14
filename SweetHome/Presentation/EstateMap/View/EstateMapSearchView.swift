//
//  EstateMapSearchView.swift
//  SweetHome
//
//  Created by 김민호 on 8/7/25.
//

import UIKit
import SnapKit

class EsstateMapSearchView: UIView {
    private let searchBar = SHSearchBar()
    
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
    
    func setupUI() {
        addSubview(searchBar)
    }
    
    func setupConstraints() {
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
