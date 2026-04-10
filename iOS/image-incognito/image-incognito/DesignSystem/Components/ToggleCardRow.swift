//
//  ToggleCardRow.swift
//  image-incognito
//
//  Design System – Settings toggle row component.
//  Used inside SectionCard to display a labelled icon + toggle switch.
//

import SwiftUI

// MARK: - Settings Toggle Card Row

struct ToggleCardRow: View {
    let icon: String
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    init(icon: String, title: String, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = LocalizedStringKey(title)
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .imageScale(.medium)
                .frame(width: 32, height: 32)
                .background(Color.appPrimary.opacity(0.12))
                .foregroundStyle(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))

            Text(title)
                .font(.appBody)
                .foregroundStyle(Color.appLabelPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.appPrimary)
        }
        .padding(Spacing.medium)
    }
}
