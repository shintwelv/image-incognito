//
//  GlassmorphismToolbar.swift
//  image-incognito
//
//  Design System – Glassmorphism Bottom Toolbar Component
//  Applies a background blur so the canvas beneath shows through
//

import SwiftUI

// MARK: - Glass Toolbar Container

struct GlassmorphismToolbar<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .background {
                // Ultra-thin material for the frosted-glass effect
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .appShadow(.floating)
            }
            .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Masking Style Pill (toolbar chip)

struct StylePill: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            AppHaptics.selection()
            action()
        }) {
            VStack(spacing: Spacing.xxSmall) {
                Image(systemName: icon)
                    .imageScale(.medium)
                    .frame(width: 36, height: 36)
                    .background(
                        isSelected ? Color.appPrimary : Color.appPrimary.opacity(0.10)
                    )
                    .foregroundStyle(isSelected ? .white : Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))
                    .animation(AppAnimation.snappy, value: isSelected)

                Text(label)
                    .font(.appCaption2)
                    .foregroundStyle(
                        isSelected ? Color.appPrimary : Color.appLabelSecondary
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast Message

struct ToastView: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(message)
                .font(.appSubheadline)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .appShadow(.card)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if isPresented {
                ToastView(message: message, icon: icon)
                    .padding(.bottom, Spacing.xxLarge)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(AppAnimation.standard) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(AppAnimation.standard, value: isPresented)
    }
}

extension View {
    /// Show a bottom toast notification.
    func appToast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected = "blur"
    @Previewable @State var showToast = false

    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            GlassmorphismToolbar {
                HStack(spacing: Spacing.xxLarge) {
                    StylePill(icon: "drop.halffull", label: "Blurred Glass", isSelected: selected == "blur") {
                        selected = "blur"
                    }
                    StylePill(icon: "square.grid.3x3.fill", label: "Pixel Art", isSelected: selected == "pixel") {
                        selected = "pixel"
                    }
                    StylePill(icon: "circle.fill", label: "Solid Clean", isSelected: selected == "solid") {
                        selected = "solid"
                    }
                }
            }
            .padding(.bottom, Spacing.large)
        }
    }
    .appToast(isPresented: $showToast, message: "저장 완료")
    .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation { showToast = true }
        }
    }
}
