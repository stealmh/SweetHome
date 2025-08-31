//
//  String+.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPhone: Bool {
        let phoneRegex = "^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$"
        let phonePredicate = NSPredicate(format:"SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        // 최소 8자 이상
        guard self.count >= 8 else { return false }
        
        // 영문자 포함 여부
        let letterRegex = ".*[A-Za-z]+.*"
        let letterTest = NSPredicate(format:"SELF MATCHES %@", letterRegex)
        guard letterTest.evaluate(with: self) else { return false }
        
        // 숫자 포함 여부
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        guard numberTest.evaluate(with: self) else { return false }
        
        // 특수문자 포함 여부
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        let specialCharTest = NSPredicate(format:"SELF MATCHES %@", specialCharRegex)
        guard specialCharTest.evaluate(with: self) else { return false }
        
        return true
    }
    
    var passwordValidationMessage: String? {
        if self.isEmpty {
            return nil
        }
        
        if self.count < 8 {
            return "비밀번호는 최소 8자 이상이어야 합니다"
        }
        
        let letterRegex = ".*[A-Za-z]+.*"
        let letterTest = NSPredicate(format:"SELF MATCHES %@", letterRegex)
        if !letterTest.evaluate(with: self) {
            return "영문자를 포함해야 합니다"
        }
        
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        if !numberTest.evaluate(with: self) {
            return "숫자를 포함해야 합니다"
        }
        
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        let specialCharTest = NSPredicate(format:"SELF MATCHES %@", specialCharRegex)
        if !specialCharTest.evaluate(with: self) {
            return "특수문자를 포함해야 합니다"
        }
        
        return nil
    }
    /// - "2025-05-13T14:53:43.177Z" 형식을 Date로 반환
    func toISO8601Date() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}
