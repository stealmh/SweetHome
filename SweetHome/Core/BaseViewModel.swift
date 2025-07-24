//
//  BaseViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

class BaseViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {}
    
    struct Output {}
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
//MARK: - BaseViewModel Protocol
private protocol ViewModelable {
    associatedtype Input
    associatedtype Output
    
    var disposeBag: DisposeBag { get }
    
    func transform(input: Input) -> Output
}

/// - Output에 붙여 사용: 로딩이 필요한 Presents에서 사용
protocol ViewModelLoadable {
    var isLoading: Driver<Bool> { get }
}

/// - Output에 붙여 사용: 네트워크 에러 처리가 필요한 Presents에서 사용
protocol ViewModelErrorable {
    var error: Driver<Error> { get }
}
