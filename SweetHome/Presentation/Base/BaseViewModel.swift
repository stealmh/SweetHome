//
//  BaseViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import Foundation
import RxSwift
import RxCocoa

public protocol ViewModelable {
    associatedtype Input
    associatedtype Output
    
    var disposeBag: DisposeBag { get }
    
    func transform(input: Input) -> Output
}

/// Output에 로딩 상태가 필요한 ViewModel에서 채택
public protocol ViewModelLoadable {
    var isLoading: Driver<Bool> { get }
}

/// Output에 에러 처리가 필요한 ViewModel에서 채택
public protocol ViewModelErrorable {
    associatedtype ErrorType: Error
    var error: Driver<ErrorType> { get }
}
