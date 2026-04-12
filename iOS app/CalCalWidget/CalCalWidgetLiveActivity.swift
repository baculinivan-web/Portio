//
//  CalCalWidgetLiveActivity.swift
//  CalCalWidget
//
//  Created by Иван on 13.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CalCalWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CalCalWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CalCalWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension CalCalWidgetAttributes {
    fileprivate static var preview: CalCalWidgetAttributes {
        CalCalWidgetAttributes(name: "World")
    }
}

extension CalCalWidgetAttributes.ContentState {
    fileprivate static var smiley: CalCalWidgetAttributes.ContentState {
        CalCalWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CalCalWidgetAttributes.ContentState {
         CalCalWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CalCalWidgetAttributes.preview) {
   CalCalWidgetLiveActivity()
} contentStates: {
    CalCalWidgetAttributes.ContentState.smiley
    CalCalWidgetAttributes.ContentState.starEyes
}
