import SwiftUI

/// The condensed title and mono detail on the left of a setting
public struct SettingLabel: View {
    let title: String
    let detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.display(17, relativeTo: .headline))
                .textCase(.uppercase)
                .foregroundStyle(AppColors.text)
            Text(detail)
                .font(.mono(9.5))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One setting on its own white card: the label, a control on the right
/// (a button, say) and optionally more below it (a slider, a note)
public struct SettingCard<Trailing: View, Below: View>: View {
    let title: String
    let detail: String
    let trailing: Trailing
    let below: Below

    public init(title: String, detail: String,
                @ViewBuilder trailing: () -> Trailing,
                @ViewBuilder below: () -> Below) {
        self.title = title
        self.detail = detail
        self.trailing = trailing()
        self.below = below()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                SettingLabel(title: title, detail: detail)
                trailing
            }
            below
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

public extension SettingCard where Below == EmptyView {
    init(title: String, detail: String, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: title, detail: detail, trailing: trailing) { EmptyView() }
    }
}

public extension SettingCard where Trailing == EmptyView {
    init(title: String, detail: String, @ViewBuilder below: () -> Below) {
        self.init(title: title, detail: detail, trailing: { EmptyView() }, below: below)
    }
}

/// A setting that's on or off, on its own white card. `below` shows under
/// it, e.g. an error or the extra options that appear when it's on.
public struct SettingToggle<Below: View>: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    let below: Below

    public init(title: String, detail: String, isOn: Binding<Bool>, @ViewBuilder below: () -> Below) {
        self.title = title
        self.detail = detail
        _isOn = isOn
        self.below = below()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isOn) {
                SettingLabel(title: title, detail: detail)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(AppColors.toggle)
            below
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

public extension SettingToggle where Below == EmptyView {
    init(title: String, detail: String, isOn: Binding<Bool>) {
        self.init(title: title, detail: detail, isOn: isOn) { EmptyView() }
    }
}

/// A small note under a setting, e.g. why it couldn't be changed
public struct SettingNote: View {
    let text: String
    let isError: Bool

    public init(_ text: String, isError: Bool = true) {
        self.text = text
        self.isError = isError
    }

    public var body: some View {
        Text(text)
            .font(.mono(9.5))
            .foregroundStyle(isError ? AppColors.destructive : AppColors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Pill switcher: the selected option is a solid capsule on a white track.
/// Used for tabs and for settings with a few choices.
public struct PillPicker<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [Value]
    let track: Color
    let label: (Value) -> String

    /// - Parameter track: the colour behind the options. White suits the
    ///   panel's ground; use `AppColors.ground` on a white card.
    public init(selection: Binding<Value>, options: [Value], track: Color = AppColors.surface,
                label: @escaping (Value) -> String) {
        _selection = selection
        self.options = options
        self.track = track
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.mono(10.5, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? AppColors.onSolid : AppColors.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background {
                            if selected { Capsule().fill(AppColors.solid) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(track, in: Capsule())
    }
}
