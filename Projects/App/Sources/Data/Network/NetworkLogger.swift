//
//  NetworkLogger.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import os.log

final class NetworkLogger {
    static let shared = NetworkLogger()
    
    private let logger = Logger(subsystem: "com.mino.sweethome", category: "api")
    
    private init() {}
    
    // MARK: - Request Logging
    func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "UNKNOWN_URL"
        
        logger.info("🌐 REQUEST: \(method) \(url)")
        
        // Headers logging
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let headersString = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logger.debug("📄 Headers: \(headersString)")
        }
        
        // Body logging
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("📦 Body: \(bodyString)")
        }
    }
    
    // MARK: - Response Logging
    func logResponse(_ response: HTTPURLResponse, data: Data?) {
        let statusCode = response.statusCode
        let dataSize = data?.count ?? 0
        let url = response.url?.absoluteString ?? "UNKNOWN_URL"
        
        if 200..<300 ~= statusCode {
            logger.info("✅ RESPONSE: \(statusCode) - \(url) (\(dataSize) bytes)")
        } else {
            logger.error("❌ RESPONSE: \(statusCode) - \(url) (\(dataSize) bytes)")
        }
        
        // Response data logging (only for debug)
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            logger.debug("📥 Response Data: \(responseString)")
        }
    }
    
    // MARK: - Error Logging
    func logError(_ error: Error, for request: URLRequest?) {
        let url = request?.url?.absoluteString ?? "UNKNOWN_URL"
        logger.error("🚨 ERROR: \(error.localizedDescription) - \(url)")
    }
    
    // MARK: - Upload Logging
    func logUploadStart(_ request: URLRequest, dataSize: Int) {
        let url = request.url?.absoluteString ?? "UNKNOWN_URL"
        logger.info("📤 UPLOAD START: \(url) (\(dataSize) bytes)")
    }
    
    func logUploadComplete(_ response: HTTPURLResponse) {
        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "UNKNOWN_URL"
        
        if 200..<300 ~= statusCode {
            logger.info("📤 UPLOAD SUCCESS: \(statusCode) - \(url)")
        } else {
            logger.error("📤 UPLOAD FAILED: \(statusCode) - \(url)")
        }
    }
    
    // MARK: - Token Logging
    func logTokenRefresh() {
        logger.info("🔄 TOKEN REFRESH: Starting token refresh")
    }
    
    func logTokenRefreshSuccess() {
        logger.info("🔄 TOKEN REFRESH: Success")
    }
    
    func logTokenRefreshFailed(_ error: Error) {
        logger.error("🔄 TOKEN REFRESH: Failed - \(error.localizedDescription)")
    }
    
    func logTokenCleared() {
        logger.notice("🗑️ TOKEN CLEARED: All tokens have been cleared")
    }
    
    func logTokenRefreshTokenExpired() {
        logger.error("🔐 REFRESH TOKEN EXPIRED: Refresh token has expired, navigating to login")
    }
}
