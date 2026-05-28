import XCTest
@testable import SubsqManager

final class ViewModelTests: XCTestCase {
    
    // MARK: - AddSubscriptionViewModel Tests

    func testAddViewModelValidation() {
        let vm = AddSubscriptionViewModel()
        
        // 初期状態は空なので false
        XCTAssertFalse(vm.isValid)
        
        // 名前だけ入力
        vm.name = "Netflix"
        XCTAssertFalse(vm.isValid)
        
        // 金額を入力 (数値)
        vm.amountText = "1490"
        XCTAssertTrue(vm.isValid)
        
        // 金額が無効
        vm.amountText = "abc"
        XCTAssertFalse(vm.isValid)
        
        // 金額が0以下
        vm.amountText = "-100"
        XCTAssertFalse(vm.isValid)
        vm.amountText = "0"
        XCTAssertFalse(vm.isValid)
        
        // 名前が空白のみ
        vm.name = "   "
        vm.amountText = "1000"
        XCTAssertFalse(vm.isValid)
    }

    // MARK: - EditSubscriptionViewModel Tests
    
    func testEditViewModelInitialization() {
        let startDate = Date()
        let sub = Subscription(name: "TestSub", amount: 1234, billingCycle: .yearly, category: .other, startDate: startDate)
        
        let vm = EditSubscriptionViewModel(subscription: sub)
        
        XCTAssertEqual(vm.name, "TestSub")
        XCTAssertEqual(vm.amountText, "1234")
        XCTAssertEqual(vm.billingCycle, .yearly)
        XCTAssertEqual(vm.category, .other)
        XCTAssertTrue(vm.isValid)
    }
}
