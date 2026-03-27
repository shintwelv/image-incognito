//
//  HomeView.swift
//  image-incognito
//
//  Screen 1 – Home & Library Access
//  앱의 시작점: 이미지 업로드 경로 선택 (PHPicker / Camera)
//

import SwiftUI

struct HomeView: View {

    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                            .padding(.top, Spacing.xLarge)

                        actionSection
                            .padding(.top, Spacing.xxLarge)
                            .padding(.horizontal, Spacing.large)

                        if !viewModel.recentItems.isEmpty {
                            recentSection
                                .padding(.top, Spacing.xxLarge)
                        }

                        Spacer(minLength: Spacing.xxxLarge)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { headerToolbar }
            // PHPicker Sheet
            .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
                PhotoPickerRepresentable(
                    selectedImage: .init(
                        get: { viewModel.selectedImage },
                        set: { image in
                            if let image { viewModel.didSelectImage(image) }
                        }
                    )
                )
                .ignoresSafeArea()
            }
            // Camera Sheet
            .sheet(isPresented: $viewModel.isShowingCamera) {
                CameraPlaceholderView()
            }
            // Settings Sheet
            .sheet(isPresented: $viewModel.isShowingSettings) {
                SettingsPlaceholderView()
            }
            // Navigate to AI Editor when an image is selected
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.selectedImage != nil },
                    set: { if !$0 { viewModel.selectedImage = nil } }
                )
            ) {
                if let image = viewModel.selectedImage {
                    EditorView(image: image)
                }
            }
        }
    }

    // MARK: - Header Toolbar

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        // Logo (leading)
        ToolbarItem(placement: .topBarLeading) {
            Image(systemName: "person.fill.viewfinder")
                .imageScale(.large)
                .foregroundStyle(Color.appPrimary)
        }
        // Settings (trailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.settingsTapped()
            } label: {
                Image(systemName: "gearshape")
                    .imageScale(.medium)
                    .foregroundStyle(Color.appLabelSecondary)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Background gradient card
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.18),
                            Color.appPrimary.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .padding(.horizontal, Spacing.large)

            VStack(spacing: Spacing.large) {
                // Placeholder illustration
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.12))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                        .foregroundStyle(Color.appPrimary)
                }

                // Hero copy
                VStack(spacing: Spacing.xSmall) {
                    Text("프라이버시를 보호할")
                        .font(.appTitle)
                        .foregroundStyle(Color.appLabelPrimary)
                    Text("사진을 선택하세요")
                        .font(.appTitle)
                        .foregroundStyle(Color.appPrimary)
                }
                .multilineTextAlignment(.center)

                Text("AI가 자동으로 얼굴을 찾아 마스킹해드립니다.")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appLabelSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xxLarge)
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: Spacing.medium) {
            PrimaryButton("사진 선택", icon: "photo.on.rectangle.angled") {
                viewModel.selectPhotoTapped()
            }

            SecondaryButton("카메라 촬영", icon: "camera") {
                viewModel.cameraTapped()
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("최근 작업")
                    .font(.appTitle3)
                    .foregroundStyle(Color.appLabelPrimary)
                Spacer()
                Button("모두 보기") {}
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(.horizontal, Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    ForEach(viewModel.recentItems) { item in
                        RecentItemThumbnail(item: item)
                    }
                }
                .padding(.horizontal, Spacing.large)
            }
        }
    }
}

// MARK: - Recent Item Thumbnail

private struct RecentItemThumbnail: View {
    let item: RecentMaskingItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Blurred thumbnail for privacy
            Image(uiImage: item.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .blur(radius: 12)
                .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))

            // Face count badge
            HStack(spacing: 3) {
                Image(systemName: "person.fill")
                    .imageScale(.small)
                Text("\(item.maskedFaceCount)")
                    .font(.appCaption2)
            }
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(Spacing.xSmall)
        }
        .appShadow(.card)
    }
}

// MARK: - Placeholder Screens (will be replaced by actual screens)

private struct CameraPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: Spacing.medium) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundStyle(Color.appPrimary)
                    Text("카메라 화면")
                        .font(.appTitle2)
                }
            }
            .navigationTitle("카메라")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

private struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: Spacing.medium) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundStyle(Color.appPrimary)
                    Text("설정 화면")
                        .font(.appTitle2)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty state") {
    HomeView()
}

#Preview("With recent items") {
    let view = HomeView()
    // Cannot inject recentItems directly without access to viewModel from outside,
    // but the structure is correct — use HomeView() with state set in makePreview.
    return view
}
