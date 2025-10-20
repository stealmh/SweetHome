//
//  MockChatData.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct MockChatData {
    static let chatRooms: [ChatRoom] = [
        ChatRoom(
            roomId: "66387304d5418c5e1e141862",
            createdAt: Date(),
            updatedAt: Date(),
            participants: [
                Participant(
                    userId: "65c9aa6932b0964405117d97",
                    nickname: "새싹중개인",
                    introduction: "언제나 친절한 상담을 제공합니다.",
                    profileImageURL: "/data/profiles/1707716853682.png"
                )
            ],
            lastChat: LastChat(
                chatId: "66386735e7696bd61fd5ef14",
                roomId: "6638664652ba24c89bb29379",
                content: "반갑습니다 :)",
                createdAt: Date(),
                updatedAt: Date(),
                sender: ChatSender(
                    userId: "65c9aa6932b0964405117d97",
                    nickname: "새싹중개인",
                    introduction: "언제나 친절한 상담을 제공합니다.",
                    profileImageURL: "/data/profiles/1707716853682.png"
                ),
                attachedFiles: ["/data/chats/image_1712739634962.png"]
            ),
            lastPushMessage: nil,
            lastPushMessageDate: nil,
            unreadCount: 0
        ),
        ChatRoom(
            roomId: "66387304d5418c5e1e141863",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-1800),
            participants: [
                Participant(
                    userId: "65c9aa6932b0964405117d98",
                    nickname: "부동산전문가",
                    introduction: "20년 경력의 부동산 전문가입니다.",
                    profileImageURL: "/data/estates/house10_1747146288434.png"
                )
            ],
            lastChat: LastChat(
                chatId: "66386735e7696bd61fd5ef15",
                roomId: "66387304d5418c5e1e141863",
                content: "원하시는 조건의 매물을 찾아드리겠습니다.",
                createdAt: Date().addingTimeInterval(-1800),
                updatedAt: Date().addingTimeInterval(-1800),
                sender: ChatSender(
                    userId: "65c9aa6932b0964405117d98",
                    nickname: "부동산전문가",
                    introduction: "20년 경력의 부동산 전문가입니다.",
                    profileImageURL: "/data/estates/house17_1747146355023.png"
                ),
                attachedFiles: []
            ),
            lastPushMessage: nil,
            lastPushMessageDate: nil,
            unreadCount: 0
        ),
        ChatRoom(
            roomId: "66387304d5418c5e1e141864",
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-3600),
            participants: [
                Participant(
                    userId: "65c9aa6932b0964405117d99",
                    nickname: "집주인",
                    introduction: "직접 임대하는 집주인입니다.",
                    profileImageURL: "/data/profiles/1707716853684.png"
                )
            ],
            lastChat: LastChat(
                chatId: "66386735e7696bd61fd5ef16",
                roomId: "66387304d5418c5e1e141864",
                content: "내일 방문 가능하신가요? 고구려의 흥망성쇠 대한독립만세인가요? 8월15일은 광복80주년을 맞는 해 인가요??",
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                sender: ChatSender(
                    userId: "65c9aa6932b0964405117d99",
                    nickname: "집주인",
                    introduction: "직접 임대하는 집주인입니다.",
                    profileImageURL: "/data/profiles/1707716853684.png"
                ),
                attachedFiles: []
            ),
            lastPushMessage: nil,
            lastPushMessageDate: nil,
            unreadCount: 0
        )
    ]
}
