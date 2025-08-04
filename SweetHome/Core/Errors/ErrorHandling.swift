//
//  ErrorHandling.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import UIKit
import RxSwift
import RxCocoa

struct ErrorAlertHelper {
    static func showAlert(for error: SHError, on viewController: UIViewController) {
        guard error.displayType == .toast else { return }
        
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
}

/// 이메일 검증 전용 에러 처리 함수
/// 서버 메시지를 우선 사용하고, 네트워크 에러는 그대로 전달
func handleEmailValidationError(_ error: Error) -> Observable<SHError?> {
    if let shError = error as? SHError { return Observable.just(shError) }

    let shError = SHError.from(error)
    return Observable.just(shError)
}
