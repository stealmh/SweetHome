//
//  ObservableType+.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import RxSwift

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
