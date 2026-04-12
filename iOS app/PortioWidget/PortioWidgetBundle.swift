import WidgetKit
import SwiftUI

@main

struct PortioWidgetBundle: WidgetBundle {

    var body: some Widget {

        PortioWidget()

        CalorieWidget()

        ProteinWidget()

        CarbsWidget()

        FatWidget()

    }

}
