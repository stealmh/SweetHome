/// - UIViewExtensionTests: UIView Extension 기능들을 테스트
/// - addSubviews, makeCapsule, updateCapsuleShape 및 UIStackView extension 테스트

import XCTest
import UIKit
@testable import SweetHome

final class UIViewExtensionTests: XCTestCase {

    var testView: UIView!
    var containerView: UIView!

    override func setUp() {
        super.setUp()
        testView = UIView()
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
    }

    override func tearDown() {
        testView = nil
        containerView = nil
        super.tearDown()
    }

    // MARK: - addSubviews Tests

    func test_addSubviews_단일_뷰() {
        let childView = UIView()

        containerView.addSubviews(childView)

        XCTAssertEqual(containerView.subviews.count, 1)
        XCTAssertTrue(containerView.subviews.contains(childView))
        XCTAssertEqual(childView.superview, containerView)
    }

    func test_addSubviews_여러_뷰들() {
        let childView1 = UIView()
        let childView2 = UIView()
        let childView3 = UIView()

        containerView.addSubviews(childView1, childView2, childView3)

        XCTAssertEqual(containerView.subviews.count, 3)
        XCTAssertTrue(containerView.subviews.contains(childView1))
        XCTAssertTrue(containerView.subviews.contains(childView2))
        XCTAssertTrue(containerView.subviews.contains(childView3))

        /// - 모든 자식 뷰의 superview가 containerView인지 확인
        XCTAssertEqual(childView1.superview, containerView)
        XCTAssertEqual(childView2.superview, containerView)
        XCTAssertEqual(childView3.superview, containerView)
    }

    func test_addSubviews_빈_매개변수() {
        /// - 매개변수 없이 호출해도 에러가 발생하지 않아야 함
        XCTAssertNoThrow(containerView.addSubviews())
        XCTAssertEqual(containerView.subviews.count, 0)
    }

    func test_addSubviews_순서_확인() {
        let firstView = UIView()
        let secondView = UIView()
        let thirdView = UIView()

        containerView.addSubviews(firstView, secondView, thirdView)

        /// - 추가된 순서대로 subviews 배열에 있는지 확인
        XCTAssertEqual(containerView.subviews[0], firstView)
        XCTAssertEqual(containerView.subviews[1], secondView)
        XCTAssertEqual(containerView.subviews[2], thirdView)
    }

    // MARK: - makeCapsule Tests

    func test_makeCapsule_기본값_적용() {
        /// - 높이를 설정하여 cornerRadius 계산이 가능하도록
        testView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)

        testView.makeCapsule()

        /// - 기본값들이 적용되었는지 확인
        XCTAssertEqual(testView.backgroundColor, SHColor.GrayScale.gray_0)
        XCTAssertEqual(testView.layer.borderColor, SHColor.Brand.deepCream.cgColor)
        XCTAssertEqual(testView.layer.borderWidth, 1.5)
        XCTAssertEqual(testView.layer.cornerRadius, 20.0) // height/2 = 40/2 = 20
        XCTAssertTrue(testView.clipsToBounds)
    }

    func test_makeCapsule_커스텀_값들() {
        testView.frame = CGRect(x: 0, y: 0, width: 80, height: 30)

        let customBackgroundColor = UIColor.red
        let customBorderColor = UIColor.blue
        let customBorderWidth: CGFloat = 2.0

        testView.makeCapsule(
            backgroundColor: customBackgroundColor,
            borderColor: customBorderColor,
            borderWidth: customBorderWidth
        )

        XCTAssertEqual(testView.backgroundColor, customBackgroundColor)
        XCTAssertEqual(testView.layer.borderColor, customBorderColor.cgColor)
        XCTAssertEqual(testView.layer.borderWidth, customBorderWidth)
        XCTAssertEqual(testView.layer.cornerRadius, 15.0) // height/2 = 30/2 = 15
        XCTAssertTrue(testView.clipsToBounds)
    }

    func test_makeCapsule_다양한_높이들() {
        let testCases: [(height: CGFloat, expectedRadius: CGFloat)] = [
            (20, 10),
            (44, 22),
            (60, 30),
            (100, 50)
        ]

        for (height, expectedRadius) in testCases {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: height))
            view.makeCapsule()

            XCTAssertEqual(view.layer.cornerRadius, expectedRadius,
                          "높이 \(height)일 때 cornerRadius는 \(expectedRadius)이어야 함")
        }
    }

    // MARK: - updateCapsuleShape Tests

    func test_updateCapsuleShape_높이_변경_후() {
        /// - 초기 설정
        testView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        testView.makeCapsule()

        let initialRadius = testView.layer.cornerRadius
        XCTAssertEqual(initialRadius, 20.0)

        /// - 높이 변경
        testView.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        testView.updateCapsuleShape()

        /// - cornerRadius가 새로운 높이에 맞게 업데이트되었는지 확인
        XCTAssertEqual(testView.layer.cornerRadius, 30.0) // 60/2 = 30
    }

    func test_updateCapsuleShape_여러번_호출() {
        testView.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        testView.makeCapsule()

        /// - 여러 번 높이 변경 후 업데이트
        let heightChanges: [CGFloat] = [30, 50, 25, 80]

        for height in heightChanges {
            testView.frame = CGRect(x: 0, y: 0, width: 100, height: height)
            testView.updateCapsuleShape()

            let expectedRadius = height / 2
            XCTAssertEqual(testView.layer.cornerRadius, expectedRadius,
                          "높이 \(height)일 때 cornerRadius는 \(expectedRadius)이어야 함")
        }
    }

    // MARK: - UIStackView Extension Tests

    func test_stackView_addArrangeSubviews_단일_뷰() {
        let stackView = UIStackView()
        let childView = UIView()

        stackView.addArrangeSubviews(childView)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
        XCTAssertTrue(stackView.arrangedSubviews.contains(childView))
    }

    func test_stackView_addArrangeSubviews_여러_뷰들() {
        let stackView = UIStackView()
        let view1 = UIView()
        let view2 = UIView()
        let view3 = UIView()

        stackView.addArrangeSubviews(view1, view2, view3)

        XCTAssertEqual(stackView.arrangedSubviews.count, 3)
        XCTAssertEqual(stackView.arrangedSubviews[0], view1)
        XCTAssertEqual(stackView.arrangedSubviews[1], view2)
        XCTAssertEqual(stackView.arrangedSubviews[2], view3)
    }

    func test_stackView_addArrangeSubviews_빈_매개변수() {
        let stackView = UIStackView()

        XCTAssertNoThrow(stackView.addArrangeSubviews())
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    // MARK: - Integration Tests

    func test_makeCapsule_실제_사용_시나리오() {
        /// - 실제 앱에서 사용될 수 있는 시나리오 테스트
        let buttonView = UIView()
        buttonView.frame = CGRect(x: 0, y: 0, width: 120, height: 44)

        /// - 버튼 스타일로 캡슐 적용
        buttonView.makeCapsule(
            backgroundColor: .systemBlue,
            borderColor: .clear,
            borderWidth: 0
        )

        /// - 결과 검증
        XCTAssertEqual(buttonView.backgroundColor, .systemBlue)
        XCTAssertEqual(buttonView.layer.borderColor, UIColor.clear.cgColor)
        XCTAssertEqual(buttonView.layer.borderWidth, 0)
        XCTAssertEqual(buttonView.layer.cornerRadius, 22) // 44/2
        XCTAssertTrue(buttonView.clipsToBounds)
    }

    func test_makeCapsule_태그_뷰_시나리오() {
        /// - 태그 뷰에서 사용되는 작은 캡슐 모양
        let tagView = UIView()
        tagView.frame = CGRect(x: 0, y: 0, width: 60, height: 24)

        tagView.makeCapsule(
            backgroundColor: UIColor.systemGray6,
            borderColor: UIColor.systemGray4,
            borderWidth: 1.0
        )

        XCTAssertEqual(tagView.backgroundColor, UIColor.systemGray6)
        XCTAssertEqual(tagView.layer.borderColor, UIColor.systemGray4.cgColor)
        XCTAssertEqual(tagView.layer.borderWidth, 1.0)
        XCTAssertEqual(tagView.layer.cornerRadius, 12) // 24/2
    }

    // MARK: - Edge Cases

    func test_makeCapsule_높이가_0인_경우() {
        let zeroHeightView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 0))

        /// - 높이가 0이어도 에러 없이 처리되어야 함
        XCTAssertNoThrow(zeroHeightView.makeCapsule())
        XCTAssertEqual(zeroHeightView.layer.cornerRadius, 0)
    }

    func test_updateCapsuleShape_bounds가_zero인_경우() {
        let view = UIView() // bounds가 zero인 상태

        /// - bounds가 zero여도 에러 없이 처리되어야 함
        XCTAssertNoThrow(view.updateCapsuleShape())
        XCTAssertEqual(view.layer.cornerRadius, 0)
    }

    func test_stackView_와_일반_뷰_함께_사용() {
        let stackView = UIStackView()
        let containerView = UIView()

        let label1 = UILabel()
        let label2 = UILabel()
        let button = UIButton()

        /// - StackView에 arranged subviews 추가
        stackView.addArrangeSubviews(label1, label2)

        /// - Container에 일반 subviews 추가
        containerView.addSubviews(stackView, button)

        XCTAssertEqual(stackView.arrangedSubviews.count, 2)
        XCTAssertEqual(containerView.subviews.count, 2)
        XCTAssertTrue(containerView.subviews.contains(stackView))
        XCTAssertTrue(containerView.subviews.contains(button))
    }
}