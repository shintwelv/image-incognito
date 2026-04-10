//
//  Toast.swift
//  image-incognito
//
//  Design System – Bottom toast notification.
//  Usage: anyView.appToast(isPresented: $flag, message: "저장 완료")
//

import SwiftUI

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(LocalizedStringKey(message))
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

// MARK: - View Extension

extension View {
    /// Show a bottom toast notification that auto-dismisses after 2 seconds.
    func appToast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon))
    }
}
