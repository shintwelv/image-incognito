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
            Text("인물 찾는 중...")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
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
            Text("감지된 얼굴이 없습니다")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
