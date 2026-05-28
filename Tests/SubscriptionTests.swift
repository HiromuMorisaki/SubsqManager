import XCTest
@testable import SubsqManager

final class SubscriptionTests: XCTestCase {
    
    // MARK: - Validation Tests

    func testSubscriptionInitialization() {
        let startDate = createDate(year: 2026, month: 1, day: 1)
        let sub = Subscription(
            name: "Netflix",
            amount: 1490,
            billingCycle: .monthly,
            category: .entertainment,
            startDate: startDate,
            iconName: "play.tv.fill",
            notes: "Family Plan"
        )
        
        XCTAssertEqual(sub.name, "Netflix")
        XCTAssertEqual(sub.amount, 1490)
        XCTAssertEqual(sub.billingCycle, .monthly)
        XCTAssertEqual(sub.category, .entertainment)
        XCTAssertEqual(sub.iconName, "play.tv.fill")
        XCTAssertEqual(sub.notes, "Family Plan")
        XCTAssertTrue(sub.isActive) // デフォルトはアクティブ
    }
    
    // MARK: - NextPaymentDate Update Tests
    
    func testUpdateNextPaymentDate_Monthly() {
        let startDate = createDate(year: 2026, month: 1, day: 15)
        let sub = Subscription(
            name: "Test",
            amount: 1000,
            billingCycle: .monthly,
            category: .entertainment,
            startDate: startDate
        )
        
        // 初回の nextPaymentDate が正しくセットされているか (登録時に自動計算される想定だが、メソッド呼び出しで確実にする)
        sub.updateNextPaymentDate()
        
        // もし startDate (2026/1/15) が今日より未来なら nextPaymentDate = startDate になる。
        // そうでなければ、今日以降の直近の15日になる。
        XCTAssertNotNil(sub.nextPaymentDate)
    }

    func testMonthlyAmountCalculation() {
        // 月額1000円
        let subMonthly = Subscription(name: "A", amount: 1000, billingCycle: .monthly, category: .entertainment, startDate: Date())
        XCTAssertEqual(subMonthly.monthlyAmount, 1000)
        
        // 年額12000円 -> 月額1000円
        let subYearly = Subscription(name: "B", amount: 12000, billingCycle: .yearly, category: .entertainment, startDate: Date())
        XCTAssertEqual(subYearly.monthlyAmount, 1000)
        
        // 週間1000円 -> 月額 約4345円 (1000 * 365 / 12 / 7)
        let subWeekly = Subscription(name: "C", amount: 1000, billingCycle: .weekly, category: .entertainment, startDate: Date())
        XCTAssertEqual(subWeekly.monthlyAmount, Decimal(1000) * 365 / 12 / 7)
    }

    // MARK: - Trial Ends Update
    
    func testTrialEndsStatus() {
        let trialEnd = createDate(year: 2030, month: 1, day: 1) // 未来
        let sub = Subscription(name: "D", amount: 1000, billingCycle: .monthly, category: .entertainment, startDate: Date(), trialEndDate: trialEnd)
        
        XCTAssertTrue(sub.isTrial)
        
        let pastTrialEnd = createDate(year: 2020, month: 1, day: 1) // 過去
        sub.trialEndDate = pastTrialEnd
        XCTAssertFalse(sub.isTrial)
    }

    // MARK: - Helpers
    
    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
