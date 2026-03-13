import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            // Lock screen / banner view
            SessionLockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(context.attributes.roomName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(.title3, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SessionActionsView(locale: context.attributes.locale,
                                       drink1Name: context.state.drink1Name,
                                       drink2Name: context.state.drink2Name)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(context.state.startTime, style: .timer)
                        .monospacedDigit()
                        .font(.caption)
                }
            } compactTrailing: {
                Text(context.attributes.roomName)
                    .lineLimit(1)
                    .font(.caption)
            } minimal: {
                Image(systemName: "play.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
private struct SessionLockScreenView: View {
    let context: ActivityViewContext<SessionActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Room name + timer
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(context.attributes.roomName)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                Text(context.state.startTime, style: .timer)
                    .font(.system(.title2, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }

            // Action buttons
            SessionActionsView(locale: context.attributes.locale,
                               drink1Name: context.state.drink1Name,
                               drink2Name: context.state.drink2Name)
        }
        .padding(16)
    }
}

// MARK: - Action Buttons

@available(iOS 16.2, *)
private struct SessionActionsView: View {
    let locale: String
    let drink1Name: String?
    let drink2Name: String?

    private var isArabic: Bool { locale == "ar" }

    var body: some View {
        HStack(spacing: 8) {
            actionLink(
                url: "com.chillax.client://action/call_waiter",
                label: isArabic ? "الويتر" : "Waiter",
                icon: "bell.fill"
            )

            actionLink(
                url: "com.chillax.client://action/controller",
                label: isArabic ? "دراع" : "Controller",
                icon: "gamecontroller.fill"
            )

            if let drink1 = drink1Name {
                actionLink(
                    url: "com.chillax.client://action/order_drink_1",
                    label: drink1,
                    icon: "cup.and.saucer.fill"
                )
            }

            if let drink2 = drink2Name {
                actionLink(
                    url: "com.chillax.client://action/order_drink_2",
                    label: drink2,
                    icon: "mug.fill"
                )
            }
        }
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
    }

    private func actionLink(url: String, label: String, icon: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
            .foregroundColor(.white)
        }
    }
}
