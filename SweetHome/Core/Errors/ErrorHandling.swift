//
//  ErrorHandling.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Error Handling Protocol
protocol ErrorHandleable {
    var errorRelay: PublishSubject<SHError> { get }
    var errorDriver: Driver<SHError> { get }
}

extension ErrorHandleable {
    var errorDriver: Driver<SHError> {
        return errorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    /// 에러를 안전하게 처리하는 헬퍼 메서드
    func handleError(_ error: Error) {
        let shError = SHError.from(error)
        errorRelay.onNext(shError)
    }
}

struct ErrorAlertHelper {
    static func showAlert(for error: SHError, on viewController: UIViewController) {
        let title = titleForError(error)
        let message = error.message
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        viewController.present(alert, animated: true)
    }
    
    private static func titleForError(_ error: SHError) -> String {
        switch error {
        case .clientError(_):
            return "입력 오류"
        case .networkError(_):
            return "네트워크 오류"
        case .commonError:
            return "오류"
        }
    }
    
    private static func showGenericAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "오류", 
            message: "일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        viewController.present(alert, animated: true)
    }
}

extension ObservableType {
    /// SHError로 변환하여 에러 처리
    func catchSHError() -> Observable<Element> {
        return self.catch { error in
            let shError = SHError.from(error)
            return Observable.error(shError)
        }
    }
    
    /// 에러를 로깅하고 계속 진행
    func logError() -> Observable<Element> {
        return self.do(onError: { error in
            let shError = SHError.from(error)
        })
    }
    
}

/// 이메일 검증 전용 에러 처리 함수
/// 서버 메시지를 우선 사용하고, 네트워크 에러는 그대로 전달
func handleEmailValidationError(_ error: Error) -> Observable<SHError?> {
    if let shError = error as? SHError { return Observable.just(shError) }

    let shError = SHError.from(error)
    return Observable.just(shError)
}
