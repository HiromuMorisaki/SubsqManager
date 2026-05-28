import XCTest
@testable import SubsqManager

final class PaymentDateCalculatorTests: XCTestCase {
    
    // MARK: - Testing .monthly (月額)

    func testMonthlyPaymentSameDay() throws {
        // 開始日: 2026/05/15
        let startDate = createDate(year: 2026, month: 5, day: 15)
        let sub = createSubscription(startDate: startDate, cycle: .monthly)
        
        // ターゲット月: 2026/07
        let targetMonth = createDate(year: 2026, month: 7, day: 1)
        let dates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetMonth)
        
        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(dates.first, createDate(year: 2026, month: 7, day: 15))
    }
    
    func testMonthlyPaymentEndOfMonth() throws {
        // 開始日: 2026/01/31
        let startDate = createDate(year: 2026, month: 1, day: 31)
        let sub = createSubscription(startDate: startDate, cycle: .monthly)
        
        // ターゲット月: 2026/02 (28日までしかない月)
        let targetMonth = createDate(year: 2026, month: 2, day: 1)
        let dates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetMonth)
        
        XCTAssertEqual(dates.count, 1)
        // 2/31は存在しないので2/28に丸められる
        XCTAssertEqual(dates.first, createDate(year: 2026, month: 2, day: 28))
    }
    
    // MARK: - Testing .yearly (年額)
    
    func testYearlyPaymentMatch() throws {
        // 開始日: 2025/11/10
        let startDate = createDate(year: 2025, month: 11, day: 10)
        let sub = createSubscription(startDate: startDate, cycle: .yearly)
        
        // ターゲット月: 2026/11
        let targetMonth = createDate(year: 2026, month: 11, day: 1)
        let dates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetMonth)
        
        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(dates.first, createDate(year: 2026, month: 11, day: 10))
    }
    
    func testYearlyPaymentNoMatch() throws {
        // 開始日: 2025/11/10
        let startDate = createDate(year: 2025, month: 11, day: 10)
        let sub = createSubscription(startDate: startDate, cycle: .yearly)
        
        // ターゲット月: 2026/10 (支払い月ではない)
        let targetMonth = createDate(year: 2026, month: 10, day: 1)
        let dates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetMonth)
        
        XCTAssertTrue(dates.isEmpty)
    }

    // MARK: - EndDate (終了日) testing
    
    func testPaymentStopsAfterEndDate() throws {
        // 開始日: 2026/01/01
        let startDate = createDate(year: 2026, month: 1, day: 1)
        let endDate = createDate(year: 2026, month: 3, day: 15)
        let sub = createSubscription(startDate: startDate, cycle: .monthly, endDate: endDate)
        
        // 2026/03 までは支払いあり (3/1)
        let targetMarch = createDate(year: 2026, month: 3, day: 1)
        let marchDates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetMarch)
        XCTAssertEqual(marchDates.count, 1)
        
        // 2026/04 は支払いなし (4/1 は endDate より後)
        let targetApril = createDate(year: 2026, month: 4, day: 1)
        let aprilDates = PaymentDateCalculator.paymentDates(for: sub, inMonth: targetApril)
        XCTAssertTrue(aprilDates.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // タイムゾーンによるブレを防ぐためUTC12時などに設定するのが安全だが、
        // アプリ内はCalendar.currentを使っているのでここでもcurrentを使う
        return Calendar.current.date(from: components)!
    }
    
    private func createSubscription(startDate: Date, cycle: BillingCycle, endDate: Date? = nil) -> Subscription {
        return Subscription(
            name: "Test Sub",
            amount: 1000,
            billingCycle: cycle,
            category: .entertainment,
            startDate: startDate,
            endDate: endDate
        )
    }
}
