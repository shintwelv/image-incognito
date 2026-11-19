//
//  EditorStateViews.swift
//  image-incognito
//
//  Transient editor states: detection progress, no-face / detection-failure
//  recovery, and the sequential rendering overlay.
//

import SwiftUI

// MARK: - Detecting Skeleton View

struct DetectingSkeletonView: View {
    var body: some View {
        VStack(spacing: Spacing.small) {
            ProgressView()
                .tint(Color.appPrimary)
                .scaleEffect(1.2)
            Text("editor.detecting")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editor.detectingOverlay")
    }
}

// MARK: - No Face Found View

struct NoFaceFoundView: View {
    let onAddRegion: () -> Void

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "person.fill.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .foregroundStyle(Color.appLabelTertiary)

            VStack(spacing: Spacing.xxSmall) {
                Text("editor.noFaceFound.title")
                    .font(.appBodyEmphasized)
                    .foregroundStyle(Color.appLabelPrimary)
                Text("editor.noFaceFound.message")
                    .font(.appFootnote)
                    .foregroundStyle(Color.appLabelSecondary)
                    .multilineTextAlignment(.center)
            }

            SecondaryButton("editor.noFaceFound.addRegion", icon: "plus.viewfinder") {
                onAddRegion()
            }
            .accessibilityIdentifier("editor.noFaceFound.addRegion")
            .frame(maxWidth: 240)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editor.noFaceFound")
    }
}

// MARK: - Detection Failed View

struct DetectionFailedView: View {
    let onAddRegion: () -> Void

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36)
                .foregroundStyle(Color.appLabelTertiary)

            VStack(spacing: Spacing.xxSmall) {
                Text("editor.detectionFailed.title")
                    .font(.appBodyEmphasized)
                    .foregroundStyle(Color.appLabelPrimary)
                Text("editor.detectionFailed.message")
                    .font(.appFootnote)
                    .foregroundStyle(Color.appLabelSecondary)
                    .multilineTextAlignment(.center)
            }

            SecondaryButton("editor.noFaceFound.addRegion", icon: "plus.viewfinder") {
                onAddRegion()
            }
            .accessibilityIdentifier("editor.detectionFailed.addRegion")
            .frame(maxWidth: 240)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editor.detectionFailed")
    }
}

// MARK: - Rendering Overlay

struct RenderingOverlayView: View {
    let current: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            AppCard {
                VStack(spacing: Spacing.medium) {
                    ProgressView(value: progress)
                        .tint(Color.appPrimary)

                    Text(
                        String(
                            format: String(localized: "editor.rendering.progress"),
                            current,
                            total
                        )
                    )
                    .font(.appBodyEmphasized)
                    .foregroundStyle(Color.appLabelPrimary)
                    .monospacedDigit()
                }
                .padding(Spacing.large)
            }
            .frame(maxWidth: 280)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editor.renderingOverlay")
    }
}
