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
    
    private let appNameLabel: UILabel = {
        let v = UILabel()
        v.text = "Sweet Home"
        v.setFont(.yeongdeok, size: .extra)
        v.textColor = SHColor.Brand.deepWood
        return v
    }()
    
    private let emailInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "이메일",
            textFieldHint: "이메일을 입력하세요"
        )
        return v
    }()
    
    private let passwordInputField: SHInputFieldView = {
        let v = SHInputFieldView()
        v.configure(
            placeholderText: "비밀번호",
            textFieldHint: "비밀번호를 입력하세요",
            rightButtonImage: UIImage(systemName: "eye.slash")
        )
        v.isSecureTextEntry = true
        return v
    }()
    
    private let loginButton: UIButton = {
        let v = UIButton()
        v.setTitle("로그인", for: .normal)
        v.setTitleFont(.pretendard(.semiBold), size: .body1)
        v.backgroundColor = SHColor.GrayScale.gray_60
        v.clipsToBounds = true
        return v
    }()
    
    
    private let registerStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fill
        v.spacing = 5
        return v
    }()
    
    private let emailRegisterGuideLabel: UILabel = {
        let v = UILabel()
        v.text = "계정이 없으신가요?"
        v.setFont(.pretendard(.regular), size: .caption1)
        return v
    }()
    
    private let emailRegisterButton: UIButton = {
        let v = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "회원가입"
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        v.configuration = config
        v.setTitleFont(.pretendard(.regular), size: .caption1)
        v.tintColor = SHColor.Brand.brightCoast
        return v
    }()
    
    private let socialLoginGuideLabel: UILabel = {
        let v = UILabel()
        v.text = "또는"
        v.setFont(.pretendard(.regular), size: .caption1)
        return v
    }()
    
    private let socialLoginStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.spacing = 10
        return v
    }()
    
    private let kakaoLoginButton: UIButton = {
        let v = UIButton()
        let resizeImage = SHAsset.LoginIcon.kakao?.resized(to: 40)
        v.setImage(resizeImage, for: .normal)
        return v
    }()
    
    private let appleLoginButton: UIButton = {
        let v = UIButton()
        let resizeImage = SHAsset.LoginIcon.apple?.resized(to: 40)
        v.setImage(resizeImage, for: .normal)
        return v
    }()
    
    // MARK: - UI Components (Splash)
    private let splashOverlayView = UIView()
    private let logoImageView = UIImageView()
    
    /// - 집 애니메이션 관련 뷰
    private let houseContainerView = UIView()
    private let houseImageView = UIImageView()
    private let heartParticles: [UIImageView] = (0..<5).map { _ in
        let v = UIImageView()
        v.image = UIImage(systemName: "heart.fill")
        v.tintColor = UIColor.systemPink.withAlphaComponent(0.7)
        v.contentMode = .scaleAspectFit
        return v
    }
    
    // MARK: - Dependencies
    private let viewModel = LoginViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
//        setupSplashOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSmokeAnimation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loginButton.layer.cornerRadius = loginButton.bounds.height / 2
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSmokeAnimation()
    }
    
    override func setupUI() {
        super.setupUI()
        
//        view.backgroundColor = SHColor.Brand.brightCream
        setupHouseAnimation()
        
        socialLoginStackView.addArrangeSubviews(kakaoLoginButton, appleLoginButton)
        registerStackView.addArrangeSubviews(emailRegisterGuideLabel, emailRegisterButton)
        
        view.addSubviews(
            houseContainerView,
            appNameLabel,
            emailInputField,
            passwordInputField,
            loginButton,
            socialLoginStackView,
            registerStackView,
            socialLoginGuideLabel
        )
    }
    
    override func setupConstraints() {
        /// - 앱 이름
        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            $0.centerX.equalToSuperview()
        }
        /// - 집 애니메이션 (Sweet Home의 e 위에 위치)
        houseContainerView.snp.makeConstraints {
            $0.trailing.equalTo(appNameLabel.snp.trailing).offset(10)
            $0.bottom.equalTo(appNameLabel.snp.top).offset(20)
            $0.width.height.equalTo(30)
        }
        /// - 이메일 입력 필드
        emailInputField.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        /// - 비밀번호 입력 필드
        passwordInputField.snp.makeConstraints {
            $0.top.equalTo(emailInputField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(emailInputField)
        }
        /// - 로그인 버튼
        loginButton.snp.makeConstraints {
            $0.top.equalTo(passwordInputField.snp.bottom).offset(40)
            $0.leading.equalTo(passwordInputField).offset(30)
            $0.trailing.equalTo(passwordInputField).inset(30)
            $0.height.equalTo(42)
        }
        /// - 소셜로그인(place)
        socialLoginGuideLabel.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        /// - 소셜로그인
        socialLoginStackView.snp.makeConstraints {
            $0.top.equalTo(socialLoginGuideLabel.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        /// - 회원가입
        registerStackView.snp.makeConstraints {
            $0.top.equalTo(socialLoginStackView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
    }
    
    override func bind() {
        let appleLoginInput = appleLoginButton.rx.tap
            .compactMap { [weak self] in self }
            .map { $0 as ASAuthorizationControllerPresentationContextProviding }
        
        let input = LoginViewModel.Input(
            onAppear: .just(()),
            email: emailInputField.inputTextField.rx.text.orEmpty.asObservable(),
            password: passwordInputField.inputTextField.rx.text.orEmpty.asObservable(),
            emailLoginTapped: loginButton.rx.tap.throttle(.seconds(2), scheduler: MainScheduler.instance).asObservable(),
            registerTapped: emailRegisterButton.rx.tap.asObservable(),
            appleLoginTapped: appleLoginInput.asObservable(),
            kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        Driver.combineLatest(output.isLoading, output.loginButtonEnable)
            .drive(onNext: { [weak self] (isLoading, isFormValid) in
                let shouldEnable = isFormValid && !isLoading
                self?.loginButton.isEnabled = shouldEnable

                if isLoading {
                    self?.loginButton.alpha = 0.6
                    self?.loginButton.setTitle("로그인중...", for: .normal)
                } else {
                    self?.loginButton.alpha = 1.0
                    self?.loginButton.setTitle("로그인", for: .normal)
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.loginButton.backgroundColor = isFormValid
                            ? SHColor.Brand.deepWood
                            : SHColor.GrayScale.gray_60
                    }
                }
            })
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                ErrorAlertHelper.showAlert(for: error, on: self)
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

// MARK: - Error Handling
extension LoginViewController {
//    private func handleLoginError(_ error: SHError) {
//        ErrorAlertHelper.showAlert(for: error, on: self)
//    }
    
//    @objc private func appleLoginButtonTapped() {
//        appleLoginTappedSubject.onNext(self)
//    }
    
}

// MARK: - Navigation
extension LoginViewController {
    private func navigateToMain() {
        let mainTabBarController = MainTabBarController()
        
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            // 부드러운 fade 애니메이션과 함께 전환
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = mainTabBarController
            }, completion: nil)
        }
    }
    
    private func navigateToRegister() {
        let registerViewController = RegisterViewController()
        navigationController?.pushViewController(registerViewController, animated: true)
    }
}

// MARK: - Splash Overlay
extension LoginViewController {
    private func setupSplashOverlay() {
        splashOverlayView.backgroundColor = .systemBackground
        
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "house.fill")
        logoImageView.tintColor = .systemBlue
        
        view.addSubview(splashOverlayView)
        splashOverlayView.addSubviews(logoImageView)
        
        splashOverlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-50)
            $0.size.equalTo(100)
        }
    }
    
    private func hideSplashOverlay() {
        UIView.animate(withDuration: 0.3, animations: {
            self.splashOverlayView.alpha = 0
        }) { _ in
            self.splashOverlayView.removeFromSuperview()
        }
    }
}

// MARK: - House Animation
extension LoginViewController {
    private func setupHouseAnimation() {
        houseImageView.image = UIImage(systemName: "house.fill")
        houseImageView.tintColor = SHColor.GrayScale.gray_45
        houseImageView.contentMode = .scaleAspectFit
        houseImageView.transform = CGAffineTransform(rotationAngle: 20 * .pi / 180)
        
        houseContainerView.addSubview(houseImageView)
        
        /// - 하트 파티클들 컨테이너에 추가
        heartParticles.forEach { particle in
            particle.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
            houseContainerView.addSubview(particle)
        }
        
        /// - set Layout
        houseImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func startSmokeAnimation() {
        for (index, particle) in heartParticles.enumerated() {
            animateHeartParticle(particle, delay: Double(index) * 0.3)
        }
    }
    
    private func stopSmokeAnimation() {
        heartParticles.forEach { particle in
            particle.layer.removeAllAnimations()
        }
    }
    
    private func animateHeartParticle(_ particle: UIImageView, delay: Double) {
        /// - 기울어진 집에 맞춘 굴뚝 위치 (20도 회전 고려)
        /// house.fill SF Symbol의 굴뚝은 보통 우측 상단에 위치하며, 20도 회전을 고려
        let chimneyX: CGFloat = 24
        let chimneyY: CGFloat = 9
        
        particle.center = CGPoint(x: chimneyX, y: chimneyY)
        particle.alpha = 0.8
        particle.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        UIView.animateKeyframes(withDuration: 4.0, delay: delay, options: [.repeat], animations: {
            /// - 1단계: 하트가 작게 시작해서 올라가면서 크기 증가
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                particle.center = CGPoint(x: chimneyX + CGFloat.random(in: -3...10), y: chimneyY - 12)
                particle.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                particle.alpha = 0.7
            }
            
            /// - 2단계: 하트가 더 위로 올라가면서 부드럽게 흔들림
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.35) {
                particle.center = CGPoint(x: chimneyX + CGFloat.random(in: -10...5), y: chimneyY - 28)
                particle.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                particle.alpha = 0.5
            }
            
            /// - 3단계: 하트가 더 크게 되면서 계속 올라감
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.25) {
                particle.center = CGPoint(x: chimneyX + CGFloat.random(in: -10...10), y: chimneyY - 45)
                particle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                particle.alpha = 0.3
            }
            
            /// - 4단계: 최종 위치에서 사라짐
            UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.15) {
                particle.center = CGPoint(x: chimneyX + CGFloat.random(in: -10...10), y: chimneyY - 60)
                particle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                particle.alpha = 0.0
            }
        })
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

@available(iOS 17.0, *)
#Preview {
    LoginViewController()
}
