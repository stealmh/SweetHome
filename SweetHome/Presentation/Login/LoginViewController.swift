//
//  LoginViewController.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit
import SnapKit
import AuthenticationServices
import RxSwift
import RxCocoa

class LoginViewController: BaseViewController {
    
    // MARK: - UI Components
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    
    private let loginButton = UIButton()
    private let emailRegisterButton = UIButton()
    
    private let kakaoLoginButton: UIButton = {
        let v = UIButton()
        v.titleLabel?.text = "까까오 로그인"
        v.backgroundColor = .yellow
        return v
    }()
    private let appleLoginButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        return button
    }()
    
    // MARK: - UI Components (Splash)
    private let splashOverlayView = UIView()
    private let logoImageView = UIImageView()
    private let appNameLabel = UILabel()
    
    // MARK: - Dependencies
    private let viewModel = LoginViewModel()
    
    // MARK: - Subjects
    private let emailLoginTappedSubject = PublishSubject<(email: String, password: String)>()
    private let appleLoginTappedSubject = PublishSubject<ASAuthorizationControllerPresentationContextProviding>()
    private let kakaoLoginTappedSubject = PublishSubject<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplashOverlay()
    }
    
    override func setupUI() {
        super.setupUI()
        
        view.addSubviews(emailTextField, passwordTextField, loginButton, emailRegisterButton, kakaoLoginButton, appleLoginButton)
        
        appleLoginButton.addTarget(self, action: #selector(appleLoginButtonTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(emailLoginButtonTapped), for: .touchUpInside)
    }
    
    override func setupConstraints() {
        // TODO: Implement constraints
        appleLoginButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        kakaoLoginButton.snp.makeConstraints {
//            $0.top.equalTo(appleLoginButton.snp.bottom)
            $0.bottom.equalToSuperview().inset(40)
            $0.centerX.equalToSuperview()
        }
    }
    
    override func bind() {
        let input = LoginViewModel.Input(
            onAppear: Observable.just(()),
            emailLoginTapped: emailLoginTappedSubject.asObservable(),
            registerTapped: emailRegisterButton.rx.tap.asObservable(),
            appleLoginTapped: appleLoginTappedSubject.asObservable(),
            kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                //TODO: 로딩 Indicator 구성
            })
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { [weak self] error in
                self?.handleLoginError(error)
            })
            .disposed(by: disposeBag)
        
        output.shouldNavigateToMain
            .drive(onNext: { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.navigateToMain()
                    self?.hideSplashOverlay()
                }
            })
            .disposed(by: disposeBag)
        
        output.shouldNavigateToRegister
            .drive(onNext: { [weak self] in
                self?.navigateToRegister()
            })
            .disposed(by: disposeBag)
        
        output.shouldHideSplash
            .drive(onNext: { [weak self] in
                self?.hideSplashOverlay()
            })
            .disposed(by: disposeBag)
        
        output.kakaoLoginResult
            .drive(onNext: { [weak self] in
                // 카카오 로그인 성공 시 추가 처리가 필요하면 여기에 작성
                print("Kakao login completed")
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Helper
extension LoginViewController {
    private func handleLoginError(_ error: LoginError) {
        showErrorAlert(message: error.localizedDescription)
    }
    
    private func showErrorAlert(message: String) {
        // TODO: 경고 Alert
    }
    
    private func navigateToMain() {
        let mainTabBarController = MainTabBarController()
        
        // NavigationController로 감싸서 전환
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = mainTabBarController
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
    private func navigateToRegister() {
        //TODO: 회원가입으로 이동
    }
    
    // MARK: - Splash Overlay Methods
    private func setupSplashOverlay() {
        splashOverlayView.backgroundColor = .systemBackground
        
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "house.fill")
        logoImageView.tintColor = .systemBlue
        
        appNameLabel.text = "SweetHome"
        appNameLabel.font = .systemFont(ofSize: 32, weight: .bold)
        appNameLabel.textAlignment = .center
        appNameLabel.textColor = .label
        
        view.addSubview(splashOverlayView)
        splashOverlayView.addSubviews(logoImageView, appNameLabel)
        
        splashOverlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-50)
            $0.size.equalTo(100)
        }
        
        appNameLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(logoImageView.snp.bottom).offset(20)
        }
    }
    
    private func hideSplashOverlay() {
        UIView.animate(withDuration: 0.3, animations: {
            self.splashOverlayView.alpha = 0
        }) { _ in
            self.splashOverlayView.removeFromSuperview()
        }
    }
    
    @objc private func appleLoginButtonTapped() {
        appleLoginTappedSubject.onNext(self)
    }
    
    @objc private func emailLoginButtonTapped() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        emailLoginTappedSubject.onNext((email, password))
    }
    
    @objc private func kakaoLoginButtonTapped() {
        kakaoLoginTappedSubject.onNext(())
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
