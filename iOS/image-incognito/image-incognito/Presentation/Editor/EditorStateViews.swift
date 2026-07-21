//
//  EditorStateViews.swift
//  image-incognito
//
//  Transient state overlays shown during face detection and when
//  no faces are found in the source image.
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
    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "person.fill.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .foregroundStyle(Color.appLabelTertiary)
            Text("editor.noFaceFound")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editor.noFaceFound")
    }
}
