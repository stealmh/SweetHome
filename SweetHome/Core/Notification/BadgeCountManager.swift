//
//  BadgeCountManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import UserNotifications
import RxSwift

final class BadgeCountManager {
    static let shared = BadgeCountManager()
    
    private let localRepository = ChatCoreDataRepository()
    private let disposeBag = DisposeBag()
    
    private init() {}
    
    func updateAppBadgeCount() {
        localRepository.fetchChatRooms()
            .subscribe(onNext: { chatRooms in
                let totalUnreadCount = chatRooms.reduce(0) { $0 + $1.unreadCount }
                
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().setBadgeCount(totalUnreadCount) { error in
                        if let error = error {
                            print("배지 카운트 설정 실패: \(error)")
                        } else {
                            print("배지 카운트 업데이트: \(totalUnreadCount)")
                        }
                    }
                }
            }, onError: { error in
                print("배지 카운트 계산 실패: \(SHError.notificationError(.badgeUpdateFailed).message)")
            })
            .disposed(by: disposeBag)
    }
}