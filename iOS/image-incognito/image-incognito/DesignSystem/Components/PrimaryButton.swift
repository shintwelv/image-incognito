//
//  PrimaryButton.swift
//  image-incognito
//
//  Design System – Primary Button Component
//  Radius: 16pt (Tokens.Radius.button) / Color: appPrimary
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = LocalizedStringKey(title)
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            AppHaptics.medium()
            action()
        }) {
            HStack(spacing: Spacing.xSmall) {
                if let icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                }
                Text(title)
                    .font(.appBodyEmphasized)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .padding(.horizontal, Spacing.large)
            .background(Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: LocalizedStringKey
    let icon: String?
    let action: () -> Void

    init(_ title: LocalizedStringKey, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            AppHaptics.light()
            action()
        }) {
            HStack(spacing: Spacing.xSmall) {
                if let icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                }
                Text(title)
                    .font(.appBodyEmphasized)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .padding(.horizontal, Spacing.large)
            .background(Color.appPrimary.opacity(0.12))
            .foregroundStyle(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button (circular)

struct IconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            AppHaptics.light()
            action()
        }) {
            Image(systemName: icon)
                .imageScale(.large)
                .frame(width: 44, height: 44)
                .background(Color.appPrimary.opacity(0.12))
                .foregroundStyle(Color.appPrimary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.medium) {
        PrimaryButton("사진 선택", icon: "photo.on.rectangle") {}
        SecondaryButton("카메라 촬영", icon: "camera") {}
        IconButton(icon: "gear") {}
    }
    .padding(Spacing.large)
    .background(Color.appBackground)
}
