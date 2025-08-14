//
//  EstateMapFilterManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import SnapKit

/// - 지도 필터 관련 기능을 관리하는 매니저 클래스
class EstateMapFilterManager: NSObject {
    
    // MARK: - Properties
    /// - 필터 버튼들
    private let areaFilterButton = EstateMapFilterButton()
    private let priceMonthFilterButton = EstateMapFilterButton()
    private let priceFilterButton = EstateMapFilterButton()
    
    /// - 슬라이더 뷰들
    private lazy var areaFilterSliderView = EstateMapSliderView()
    private lazy var priceMonthFilterSliderView = EstateMapSliderView()
    private lazy var priceFilterSliderView = EstateMapSliderView()
    
    /// - 각 필터의 현재 설정된 텍스트를 저장
    private var areaRangeText: String?
    private var priceMonthRangeText: String?
    private var priceRangeText: String?
    
    /// - 필터 매니저 델리게이트
    weak var delegate: EstateMapFilterManagerDelegate?
    
    // MARK: - Public Methods
    
    /// - 필터 버튼들을 부모 뷰에 추가하고 제약조건 설정
    func setupFilterButtons(in parentView: UIView, below searchView: UIView) {
        parentView.addSubviews(
            areaFilterButton,
            priceMonthFilterButton,
            priceFilterButton,
            areaFilterSliderView,
            priceMonthFilterSliderView,
            priceFilterSliderView
        )
        
        setupFilterButtonConstraints(in: parentView)
        setupFilterButtonActions()
        configureSliders()
    }
    
    /// - 필터 버튼들을 맵 컨테이너 위로 가져오기
    func bringFiltersToFront(in parentView: UIView, mapContainer: UIView) {
        parentView.bringSubviewToFront(areaFilterButton)
        parentView.bringSubviewToFront(priceMonthFilterButton)
        parentView.bringSubviewToFront(priceFilterButton)
        parentView.bringSubviewToFront(areaFilterSliderView)
        parentView.bringSubviewToFront(priceMonthFilterSliderView)
        parentView.bringSubviewToFront(priceFilterSliderView)
        
        setupConstraintsRelativeToMapContainer(mapContainer)
    }
    
    /// - 슬라이더 뷰들의 말풍선 위치 업데이트
    func updateTooltipPositions() {
        updateTooltipPosition(for: areaFilterButton, sliderView: areaFilterSliderView)
        updateTooltipPosition(for: priceMonthFilterButton, sliderView: priceMonthFilterSliderView)
        updateTooltipPosition(for: priceFilterButton, sliderView: priceFilterSliderView)
    }
    
    /// - 현재 필터 설정값들을 반환
    func getCurrentFilterValues() -> (area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?) {
        let areaValues = (areaRangeText != nil && areaRangeText != "전체") ? areaFilterSliderView.getCurrentValues() : nil
        let priceMonthValues = (priceMonthRangeText != nil && priceMonthRangeText != "전체") ? priceMonthFilterSliderView.getCurrentValues() : nil
        let priceValues = (priceRangeText != nil && priceRangeText != "전체") ? priceFilterSliderView.getCurrentValues() : nil
        
        return (areaValues, priceMonthValues, priceValues)
    }
}

// MARK: - Private Methods
private extension EstateMapFilterManager {
    
    /// - 필터 버튼들의 제약조건 설정
    func setupFilterButtonConstraints(in parentView: UIView) {
        // 제약조건은 mapContainer가 설정된 후에 setupConstraintsRelativeToMapContainer에서 설정됨
    }
    
    /// - 맵 컨테이너 기준으로 제약조건 재설정
    func setupConstraintsRelativeToMapContainer(_ mapContainer: UIView) {
        areaFilterButton.snp.makeConstraints {
            $0.top.equalTo(mapContainer).offset(8)
            $0.leading.equalTo(mapContainer).offset(20)
        }
        
        priceMonthFilterButton.snp.makeConstraints {
            $0.top.equalTo(areaFilterButton)
            $0.leading.equalTo(areaFilterButton.snp.trailing).offset(4)
        }
        
        priceFilterButton.snp.makeConstraints {
            $0.top.equalTo(areaFilterButton)
            $0.leading.equalTo(priceMonthFilterButton.snp.trailing).offset(4)
        }
        
        areaFilterSliderView.snp.makeConstraints {
            $0.top.equalTo(areaFilterButton.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        priceMonthFilterSliderView.snp.makeConstraints {
            $0.top.equalTo(priceMonthFilterButton.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        priceFilterSliderView.snp.makeConstraints {
            $0.top.equalTo(priceFilterButton.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
    }
    
    /// - 필터 버튼들의 액션 설정
    func setupFilterButtonActions() {
        areaFilterButton.buttonTapped = { [weak self] in
            self?.toggleSliderView(self?.areaFilterSliderView, button: self?.areaFilterButton)
        }
        
        priceMonthFilterButton.buttonTapped = { [weak self] in
            self?.toggleSliderView(self?.priceMonthFilterSliderView, button: self?.priceMonthFilterButton)
        }
        
        priceFilterButton.buttonTapped = { [weak self] in
            self?.toggleSliderView(self?.priceFilterSliderView, button: self?.priceFilterButton)
        }
        
        /// - 슬라이더 값 변경 이벤트 설정
        areaFilterSliderView.addSliderValueChangedTarget(self, action: #selector(areaSliderValueChanged))
        priceMonthFilterSliderView.addSliderValueChangedTarget(self, action: #selector(priceMonthSliderValueChanged))
        priceFilterSliderView.addSliderValueChangedTarget(self, action: #selector(priceSliderValueChanged))
    }
    
    /// - 슬라이더들을 초기 설정
    func configureSliders() {
        /// - 평수 선택 슬라이더 설정 (0~50평, 초기값: 전체 범위)
        areaFilterSliderView.configureSlider(
            minimumValue: 0,
            maximumValue: 50,
            lowerValue: 0,
            upperValue: 50,
            unit: "평"
        )
        
        /// - 월세 선택 슬라이더 설정 (0~200만원, 초기값: 전체 범위)
        priceMonthFilterSliderView.configureSlider(
            minimumValue: 0,
            maximumValue: 200,
            lowerValue: 0,
            upperValue: 200,
            unit: "만원"
        )
        
        /// - 보증금 선택 슬라이더 설정 (0~10000만원 = 1억, 초기값: 전체 범위)
        priceFilterSliderView.configureSlider(
            minimumValue: 0,
            maximumValue: 10000,
            lowerValue: 0,
            upperValue: 10000,
            unit: "만원"
        )
        
        /// - 필터 버튼 초기 텍스트 설정 (전체 범위로 설정되었으므로)
        areaFilterButton.configure(title: "평수: 전체")
        priceMonthFilterButton.configure(title: "월세: 전체")
        priceFilterButton.configure(title: "보증금: 전체")
        
        /// - 초기 범위 텍스트 저장
        areaRangeText = "전체"
        priceMonthRangeText = "전체"
        priceRangeText = "전체"
        
        print("📱 Filter buttons and sliders configured")
    }
    
    /// - 슬라이더 뷰 토글 (표시/숨김)
    func toggleSliderView(_ sliderView: EstateMapSliderView?, button: EstateMapFilterButton?) {
        guard let sliderView = sliderView, let button = button else { return }
        
        /// - 다른 슬라이더들은 숨기고 버튼 선택 해제
        hideOtherSliders(except: sliderView)
        
        /// - 현재 슬라이더 토글
        UIView.animate(withDuration: 0.3) {
            sliderView.isHidden = !button.isSelected
        }
        
        /// - 선택된 경우 버튼 텍스트 업데이트 (현재 설정된 값이 있으면 그것을 유지)
        if button.isSelected {
            let currentRangeText = sliderView.getRangeText()
            updateButtonText(button, with: currentRangeText)
            saveRangeText(for: button, text: currentRangeText)
        }
        
        /// - 델리게이트에게 필터 상태 변경 알림
        delegate?.filterDidToggle(isActive: button.isSelected)
    }
    
    /// - 다른 슬라이더들을 숨기고 버튼 선택 해제 (설정된 값은 유지)
    func hideOtherSliders(except currentSlider: EstateMapSliderView) {
        let allSliders = [areaFilterSliderView, priceMonthFilterSliderView, priceFilterSliderView]
        let allButtons = [areaFilterButton, priceMonthFilterButton, priceFilterButton]
        
        for (slider, button) in zip(allSliders, allButtons) {
            if slider != currentSlider {
                UIView.animate(withDuration: 0.3) {
                    slider.isHidden = true
                }
                button.setSelected(false, animated: true)
                /// - 설정된 값이 있으면 유지, 없으면 기본 텍스트로 복원
                if let savedText = getSavedRangeText(for: button) {
                    updateButtonText(button, with: savedText)
                } else {
                    resetButtonText(button)
                }
            }
        }
    }
    
    /// - 버튼 텍스트를 선택된 범위로 업데이트
    func updateButtonText(_ button: EstateMapFilterButton, with rangeText: String) {
        var title = ""
        if button == areaFilterButton {
            title = "평수: \(rangeText)"
        } else if button == priceMonthFilterButton {
            title = "월세: \(rangeText)"
        } else if button == priceFilterButton {
            title = "보증금: \(rangeText)"
        }
        button.configure(title: title)
    }
    
    /// - 버튼 텍스트를 원래대로 복원
    func resetButtonText(_ button: EstateMapFilterButton) {
        if button == areaFilterButton {
            button.configure(title: "평수: 전체")
        } else if button == priceMonthFilterButton {
            button.configure(title: "월세: 전체")
        } else if button == priceFilterButton {
            button.configure(title: "보증금: 전체")
        }
    }
    
    /// - 버튼에 대응하는 범위 텍스트를 저장
    func saveRangeText(for button: EstateMapFilterButton, text: String) {
        if button == areaFilterButton {
            areaRangeText = text
        } else if button == priceMonthFilterButton {
            priceMonthRangeText = text
        } else if button == priceFilterButton {
            priceRangeText = text
        }
        
        /// - 델리게이트에게 필터 값 변경 알림
        delegate?.filterValueDidChange()
    }
    
    /// - 버튼에 대응하는 저장된 범위 텍스트를 가져옴
    func getSavedRangeText(for button: EstateMapFilterButton) -> String? {
        if button == areaFilterButton {
            return areaRangeText
        } else if button == priceMonthFilterButton {
            return priceMonthRangeText
        } else if button == priceFilterButton {
            return priceRangeText
        }
        return nil
    }
    
    /// - 말풍선 위치 업데이트
    func updateTooltipPosition(for button: EstateMapFilterButton, sliderView: EstateMapSliderView) {
        if let tipCenter = button.superview?.convert(button.center, to: sliderView) {
            sliderView.updateTipStartX(tipCenter.x)
        }
    }
    
    /// - 슬라이더 값 변경 이벤트 핸들러들
    @objc func areaSliderValueChanged() {
        let rangeText = areaFilterSliderView.getRangeText()
        saveRangeText(for: areaFilterButton, text: rangeText)
        if areaFilterButton.isSelected {
            updateButtonText(areaFilterButton, with: rangeText)
        }
    }
    
    @objc func priceMonthSliderValueChanged() {
        let rangeText = priceMonthFilterSliderView.getRangeText()
        saveRangeText(for: priceMonthFilterButton, text: rangeText)
        if priceMonthFilterButton.isSelected {
            updateButtonText(priceMonthFilterButton, with: rangeText)
        }
    }
    
    @objc func priceSliderValueChanged() {
        let rangeText = priceFilterSliderView.getRangeText()
        saveRangeText(for: priceFilterButton, text: rangeText)
        if priceFilterButton.isSelected {
            updateButtonText(priceFilterButton, with: rangeText)
        }
    }
}

// MARK: - EstateMapFilterManagerDelegate
protocol EstateMapFilterManagerDelegate: AnyObject {
    /// - 필터가 토글되었을 때 호출
    func filterDidToggle(isActive: Bool)
    
    /// - 필터 값이 변경되었을 때 호출
    func filterValueDidChange()
}