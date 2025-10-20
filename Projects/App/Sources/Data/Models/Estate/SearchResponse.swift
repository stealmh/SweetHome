//
//  SearchResponse.swift
//  SweetHome
//
//  Created by 김민호 on 9/8/25.
//

struct SearchResponse: Decodable {
    let documents: [SearchItemResponse]
}

struct SearchItemResponse : Decodable {
    let y: String
    let x: String
}
