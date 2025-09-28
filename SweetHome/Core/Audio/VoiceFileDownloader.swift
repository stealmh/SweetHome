//
//  VoiceFileDownloader.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift
import Alamofire

/// - VoiceFileDownloader: 음성 파일 다운로드 및 캐싱을 담당하는 클래스
final class VoiceFileDownloader {

    // MARK: - Singleton

    static let shared = VoiceFileDownloader()
    private init() {}

    // MARK: - Properties

    private let session = Session.default
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]

    /// - 음성 파일 캐시 디렉토리
    private var cacheDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let voiceCacheDir = documentsPath.appendingPathComponent("VoiceCache")

        if !fileManager.fileExists(atPath: voiceCacheDir.path) {
            try? fileManager.createDirectory(at: voiceCacheDir, withIntermediateDirectories: true)
        }

        return voiceCacheDir
    }

    // MARK: - Public Methods

    /// - 음성 파일 다운로드 (Observable 반환)
    func downloadVoiceFile(from relativePath: String) -> Observable<Data> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(SHError.networkError(.connectionFailed("다운로드에 실패하였습니다.")))
                return Disposables.create()
            }

            /// - 캐시된 파일이 있는지 확인
            let cacheKey = self.cacheKey(from: relativePath)
            let cachedFileURL = self.cacheDirectory.appendingPathComponent(cacheKey)

            if self.fileManager.fileExists(atPath: cachedFileURL.path) {
                do {
                    let cachedData = try Data(contentsOf: cachedFileURL)

                    /// - 파일 크기 검증 (56 bytes는 너무 작아서 오류 응답일 가능성)
                    if cachedData.count < 1000 {
                        print("⚠️ VoiceFileDownloader: Cached file too small (\(cachedData.count) bytes), re-downloading")
                        try? self.fileManager.removeItem(at: cachedFileURL)
                    } else {
                        print("✅ VoiceFileDownloader: Using valid cached file (\(cachedData.count) bytes)")
                        observer.onNext(cachedData)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                } catch {
                    print("⚠️ VoiceFileDownloader: Failed to load cached file - \(error)")
                    try? self.fileManager.removeItem(at: cachedFileURL)
                }
            }

            /// - 서버에서 다운로드
            let fullURL = APIConstants.baseURL + "/v1" + relativePath
            print("📥 VoiceFileDownloader: Attempting to download from: \(fullURL)")

            guard let url = URL(string: fullURL) else {
                print("❌ VoiceFileDownloader: Invalid URL: \(fullURL)")
                observer.onError(SHError.networkError(.connectionFailed("유효하지 않은 URL 입니다.")))
                return Disposables.create()
            }

            guard let accessToken = AuthTokenManager.shared.accessToken else {
                print("❌ VoiceFileDownloader: No access token available")
                observer.onError(SHError.networkError(.tokenExpired))
                return Disposables.create()
            }
            let sesacKey = AuthTokenManager.shared.sesacKey

            /// - HTTP 요청 헤더 설정
            var request = URLRequest(url: url)
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            request.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
            request.httpMethod = "GET"

            print("🔑 VoiceFileDownloader: Request headers - Authorization: \(accessToken.prefix(20))..., SeSACKey: \(sesacKey)")

            /// - 다운로드 태스크 생성
            let downloadTask = URLSession.shared.downloadTask(with: request) { [weak self] localURL, response, error in
                DispatchQueue.main.async {
                    /// - 응답 상태 로깅 및 검증
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 VoiceFileDownloader: HTTP Response - Status: \(httpResponse.statusCode)")
                        print("📡 VoiceFileDownloader: Content-Type: \(httpResponse.allHeaderFields["Content-Type"] ?? "unknown")")
                        print("📡 VoiceFileDownloader: Content-Length: \(httpResponse.allHeaderFields["Content-Length"] ?? "unknown")")

                        /// - HTTP 상태 코드 검증
                        if httpResponse.statusCode != 200 {
                            print("❌ VoiceFileDownloader: HTTP error \(httpResponse.statusCode)")
                            observer.onError(SHError.networkError(.connectionFailed("HTTP \(httpResponse.statusCode)")))
                            return
                        }
                    }

                    if let error {
                        print("❌ VoiceFileDownloader: Download error - \(error.localizedDescription)")
                        observer.onError(SHError.networkError(.connectionFailed(error.localizedDescription)))
                        return
                    }

                    guard let localURL else {
                        print("❌ VoiceFileDownloader: No local URL returned")
                        observer.onError(SHError.networkError(.connectionFailed("요청 실패")))
                        return
                    }

                    print("📁 VoiceFileDownloader: Downloaded to temporary location: \(localURL)")

                    do {
                        let data = try Data(contentsOf: localURL)

                        print("📊 VoiceFileDownloader: Downloaded data size: \(data.count) bytes")

                        /// - 작은 파일인 경우 내용 확인 (처음 100바이트)
                        if data.count <= 100 {
                            let hexString = data.prefix(data.count).map { String(format: "%02x", $0) }.joined()
                            print("🔍 VoiceFileDownloader: Small file content (hex): \(hexString)")

                            if let stringContent = String(data: data, encoding: .utf8) {
                                print("🔍 VoiceFileDownloader: Small file content (text): \(stringContent)")
                            }
                        } else {
                            /// - 큰 파일인 경우 처음 20바이트만 확인
                            let headerHex = data.prefix(20).map { String(format: "%02x", $0) }.joined()
                            print("🔍 VoiceFileDownloader: File header (hex): \(headerHex)")
                        }

                        /// - 다운로드된 파일 크기 검증
                        if data.count < 1000 {
                            print("❌ VoiceFileDownloader: Downloaded file too small (\(data.count) bytes), likely an error response")
                            observer.onError(SHError.networkError(.connectionFailed("Invalid audio file size")))
                            return
                        }

                        /// - 캐시에 저장
                        try? data.write(to: cachedFileURL)
                        print("✅ VoiceFileDownloader: Downloaded and cached \(data.count) bytes")

                        observer.onNext(data)
                        observer.onCompleted()
                    } catch {
                        print("❌ VoiceFileDownloader: Failed to read downloaded file - \(error)")
                        observer.onError(SHError.networkError(.connectionFailed("요청 실패")))
                    }

                    /// - 다운로드 태스크 제거
                    self?.downloadTasks.removeValue(forKey: relativePath)
                }
            }

            /// - 다운로드 태스크 저장 및 시작
            self.downloadTasks[relativePath] = downloadTask
            downloadTask.resume()

            return Disposables.create {
                downloadTask.cancel()
                self.downloadTasks.removeValue(forKey: relativePath)
            }
        }
    }

    /// - 음성 파일이 캐시되어 있는지 확인
    func isCached(relativePath: String) -> Bool {
        let cacheKey = cacheKey(from: relativePath)
        let cachedFileURL = cacheDirectory.appendingPathComponent(cacheKey)
        return fileManager.fileExists(atPath: cachedFileURL.path)
    }

    /// - 캐시된 음성 파일 데이터 반환
    func getCachedVoiceData(from relativePath: String) -> Data? {
        let cacheKey = cacheKey(from: relativePath)
        let cachedFileURL = cacheDirectory.appendingPathComponent(cacheKey)

        guard fileManager.fileExists(atPath: cachedFileURL.path) else {
            return nil
        }

        return try? Data(contentsOf: cachedFileURL)
    }

    /// - 특정 음성 파일 캐시 삭제
    func clearCache(for relativePath: String) {
        let cacheKey = cacheKey(from: relativePath)
        let cachedFileURL = cacheDirectory.appendingPathComponent(cacheKey)
        try? fileManager.removeItem(at: cachedFileURL)
    }

    /// - 모든 음성 파일 캐시 삭제
    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        print("🗑️ VoiceFileDownloader: Cleared all cache")
    }

    /// - 잘못된 캐시 파일들 정리 (1000 bytes 미만)
    func clearInvalidCache() {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else { return }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path)
            var clearedCount = 0

            for fileName in files {
                let fileURL = cacheDirectory.appendingPathComponent(fileName)
                let fileData = try? Data(contentsOf: fileURL)

                if let data = fileData, data.count < 1000 {
                    try? fileManager.removeItem(at: fileURL)
                    clearedCount += 1
                    print("🗑️ VoiceFileDownloader: Removed invalid cache file: \(fileName) (\(data.count) bytes)")
                }
            }

            if clearedCount > 0 {
                print("✅ VoiceFileDownloader: Cleared \(clearedCount) invalid cache files")
            }
        } catch {
            print("❌ VoiceFileDownloader: Failed to clear invalid cache - \(error)")
        }
    }

    // MARK: - Private Methods

    private func cacheKey(from relativePath: String) -> String {
        /// - 상대 경로를 파일명으로 변환 (특수문자 제거)
        let fileName = relativePath.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        return fileName
    }
}

// MARK: - VoiceMessageData Extension

extension VoiceMessageData {
    /// - 서버 상대 경로에서 실제 VoiceMessageData 생성
    static func from(relativePath: String, duration: TimeInterval) -> Observable<VoiceMessageData> {
        return VoiceFileDownloader.shared.downloadVoiceFile(from: relativePath)
            .map { audioData in
                return VoiceMessageData(
                    audioData: audioData,
                    duration: duration,
                    fileName: relativePath.components(separatedBy: "/").last
                )
            }
    }

    /// - 캐시된 데이터로 즉시 생성 (있는 경우)
    static func fromCache(relativePath: String, duration: TimeInterval) -> VoiceMessageData? {
        guard let audioData = VoiceFileDownloader.shared.getCachedVoiceData(from: relativePath) else {
            return nil
        }

        return VoiceMessageData(
            audioData: audioData,
            duration: duration,
            fileName: relativePath.components(separatedBy: "/").last
        )
    }
}
