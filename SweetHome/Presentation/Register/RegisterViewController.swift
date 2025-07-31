//
//  RegisterViewController.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class RegisterViewController: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        return v
    }()
    
    private let contentView = UIView()
    
    private let emailInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "이메일",
            textFieldHint: "이메일을 입력하세요",
            isRequired: true
        )
        return v
    }()
    
    private let passwordInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "비밀번호",
            textFieldHint: "8자 이상 입력하세요",
            rightButtonImage: UIImage(systemName: "eye.slash"),
            isRequired: true
        )
        v.isSecureTextEntry = true
        return v
    }()
    
    private let nicknameInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "닉네임",
            textFieldHint: "사용할 닉네임을 입력하세요",
            isRequired: true
        )
        return v
    }()
    
    private let phoneInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "전화번호",
            textFieldHint: "010-0000-0000"
        )
        return v
    }()
    
    private let descriptionInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "설명",
            textFieldHint: "자기소개를 입력하세요."
        )
        return v
    }()
    
    private let registerButton: UIButton = {
        let v = UIButton()
        v.setTitle("회원가입", for: .normal)
        v.setTitleFont(.pretendard(.semiBold), size: .body1)
        v.backgroundColor = SHColor.GrayScale.gray_60
        v.clipsToBounds = true
        return v
    }()
    
    private let viewModel = RegisterViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardObserver()
        setupNavigationTitle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        registerButton.layer.cornerRadius = registerButton.bounds.height / 2
    }

    override func setupUI() {
        super.setupUI()
    
        contentView.addSubviews(
            emailInputField,
            passwordInputField,
            nicknameInputField,
            phoneInputField,
            descriptionInputField
        )
        
        scrollView.addSubview(contentView)
        view.addSubviews(scrollView, registerButton)
    }
    
    override func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(registerButton.snp.top).offset(-20)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        emailInputField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        passwordInputField.snp.makeConstraints {
            $0.top.equalTo(emailInputField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(emailInputField)
        }
        
        nicknameInputField.snp.makeConstraints {
            $0.top.equalTo(passwordInputField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(emailInputField)
        }
        
        phoneInputField.snp.makeConstraints {
            $0.top.equalTo(nicknameInputField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(emailInputField)
        }
        
        descriptionInputField.snp.makeConstraints {
            $0.top.equalTo(phoneInputField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(emailInputField)
            $0.bottom.equalToSuperview().inset(20)
        }

        registerButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(50)
            $0.trailing.equalToSuperview().inset(50)
            $0.height.equalTo(42)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }
    }
    
    override func bind() {
        let input = RegisterViewModel.Input(
            email: emailInputField.inputTextField.rx.text.orEmpty.asObservable(),
            password: passwordInputField.inputTextField.rx.text.orEmpty.asObservable(),
            nickname: nicknameInputField.inputTextField.rx.text.orEmpty.asObservable(),
            phone: phoneInputField.inputTextField.rx.text.orEmpty.asObservable(),
            description: descriptionInputField.inputTextField.rx.text.orEmpty.asObservable(),
            registerTapped: registerButton.rx.tap.throttle(.seconds(2), scheduler: MainScheduler.instance).asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.error
            .drive(onNext: { [weak self] error in
                self?.handleRegisterError(error)
            })
            .disposed(by: disposeBag)
        
        output.shouldNavigateToMain
            .drive(onNext: { [weak self] in
                self?.navigateToMain()
            })
            .disposed(by: disposeBag)
        
        output.emailValidationState
            .drive(onNext: { [weak self] state in
                self?.emailInputField.updateEmailValidationUI(state)
            })
            .disposed(by: disposeBag)
        
        // isLoading과 registerButtonEnable을 결합하여 버튼 상태 관리
        Driver.combineLatest(output.isLoading, output.registerButtonEnable)
            .drive(onNext: { [weak self] (isLoading, isFormValid) in
                let shouldEnable = isFormValid && !isLoading
                self?.registerButton.isEnabled = shouldEnable

                if isLoading {
                    self?.registerButton.alpha = 0.6
                    self?.registerButton.setTitle("처리중...", for: .normal)
                } else {
                    self?.registerButton.alpha = 1.0
                    self?.registerButton.setTitle("회원가입", for: .normal)
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.registerButton.backgroundColor = isFormValid
                            ? SHColor.Brand.deepWood
                            : SHColor.GrayScale.gray_60
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNavigationTitle() {
        setupNavigationBar(title: "회원가입")
    }
    
}
// MARK: - Error Handling
extension RegisterViewController {
    private func handleRegisterError(_ error: RegisterError) {
        showErrorAlert(message: error.localizedDescription)
    }
    
    private func showErrorAlert(message: String) {
        // TODO: 경고 Alert
        print("Register Error: \(message)")
    }
}

// MARK: - Navigation
extension RegisterViewController {
    
    private func navigateToMain() {
        let mainTabBarController = MainTabBarController()
        
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            if let navigationController = navigationController {
                print("🏠 메인탭 이동 - 현재 네비게이션 스택: \(navigationController.viewControllers.map { String(describing: type(of: $0)) })")
            }
            
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = mainTabBarController
            }, completion: nil)
        }
    }
}

// MARK: - Keyboard Handling
extension RegisterViewController {
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = keyboardFrame.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        let adjustedKeyboardHeight = keyboardHeight - safeAreaBottom
        
        // registerButton을 키보드 바로 위로 이동
        UIView.animate(withDuration: animationDuration) {
            self.registerButton.snp.updateConstraints {
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(adjustedKeyboardHeight + 10)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        UIView.animate(withDuration: animationDuration) {
            self.registerButton.snp.updateConstraints {
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func findActiveTextField() -> UIView? {
        let textFields = [emailInputField, passwordInputField, nicknameInputField, phoneInputField, descriptionInputField]
        
        for inputField in textFields {
            if inputField.inputTextField.isFirstResponder {
                return inputField
            }
        }
        return nil
    }
}

@available(iOS 17.0, *)
#Preview {
    RegisterViewController()
}
