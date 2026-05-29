//
//  SubsqManagerWidgetBundle.swift
//  SubsqManagerWidget
//
//  Created by 森崎大夢 on 2026/05/20.
//

import WidgetKit
import SwiftUI

@main
struct SubsqManagerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubsqMonthlyWidget()
        SubsqUpcomingWidget()
        SubsqSavingsWidget()
    }
}
