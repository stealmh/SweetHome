// This folder is for constants

import Foundation

// MARK: - API Configuration
struct APIConstants {
    static let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
    static let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as! String
}
