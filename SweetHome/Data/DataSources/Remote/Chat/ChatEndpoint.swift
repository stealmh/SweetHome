//
//  ChatEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import Alamofire

enum ChatEndpoint: TargetType {
    /// - 생성(조회)
    case create_or_read(model: CreateChat)
    /// - 목록 조회
    case listRead
    /// - 채팅 보내기
    case sendMessage(room_id: String, model: SendChat)
    /// - 채팅내역 목록 조회
    case messageRead(room_id: String, next: String?)
}

extension ChatEndpoint {
    var baseURL: String { return APIConstants.baseURL }
    
    var path: String {
        switch self {
        case .create_or_read:
            return "/v1/chats"
        case .listRead:
            return "/v1/chats"
        case let .sendMessage(id, _):
            return "/v1/chats/\(id)"
        case let .messageRead(id, _):
            return "/v1/chats/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .listRead, .messageRead:
            return .get
        case .create_or_read, .sendMessage:
            return .post
        }
    }
    
    var task: HTTPTask {
        switch self {
        case let .create_or_read(model):
            return .requestJSONEncodable(model)
        case .listRead:
            return .requestPlain
        case let .sendMessage(_, model):
            return .requestJSONEncodable(model)
        case let .messageRead(_, next):
            if let next = next {
                let parameters = ["next": next]
                return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
            } else {
                return .requestPlain
            }
        }
    }
    
    var headers: HTTPHeaders? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
        return HTTPHeaders([
            "SeSACKey": key,
            "Content-Type": "application/json"
        ])
    }
}
