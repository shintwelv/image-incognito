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
    @Environment(IncomingImageStore.self) private var incomingImageStore

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

                        recentSection
                            .padding(.top, Spacing.xxLarge)

                        Spacer(minLength: Spacing.xxxLarge)
                    }
                }

                // Shown while photo library images are being decoded
                if viewModel.isLoadingImages {
                    ImageLoadingOverlay()
                        .transition(.opacity)
                        .accessibilityIdentifier("home.loadingOverlay")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbar }
            .animation(AppAnimation.standard, value: viewModel.isLoadingImages)
            // Receive images shared from external apps (e.g. Photos share sheet)
            .onChange(of: incomingImageStore.pendingImages) { _, images in
                guard !images.isEmpty else { return }
                incomingImageStore.pendingImages = []
                // Clear first so any existing navigation (e.g. ExportView on top of EditorView)
                // is popped before pushing a fresh EditorView with the incoming image.
                viewModel.selectedImages = []
                Task { @MainActor in
                    viewModel.didSelectImages(images)
                }
            }
            // PHPicker Sheet
            .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
                PhotoPickerRepresentable(
                    onLoadingStarted: { viewModel.isLoadingImages = true },
                    onImagesSelected: { images in viewModel.didSelectImages(images) }
                )
                .ignoresSafeArea()
            }
            // Camera Sheet
            .fullScreenCover(isPresented: $viewModel.isShowingCamera) {
                CameraPickerRepresentable(
                    selectedImage: .init(
                        get: { viewModel.selectedImages.first },
                        set: { image in
                            if let image { viewModel.didSelectImages([image]) }
                        }
                    ),
                    onDismiss: { viewModel.isShowingCamera = false }
                )
                .ignoresSafeArea()
            }
            // Settings Sheet
            .sheet(isPresented: $viewModel.isShowingSettings) {
                SettingsView()
            }
            // Navigate to AI Editor when images are selected
            .navigationDestination(
                isPresented: Binding(
                    get: { !viewModel.selectedImages.isEmpty },
                    set: { if !$0 { viewModel.selectedImages = [] } }
                )
            ) {
                if !viewModel.selectedImages.isEmpty {
                    EditorView(images: viewModel.selectedImages)
                }
            }
        }
    }

    // MARK: - Settings Toolbar

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.settingsTapped()
            } label: {
                Image(systemName: "gearshape")
                    .imageScale(.medium)
                    .foregroundStyle(Color.appLabelSecondary)
            }
            .accessibilityIdentifier("home.settingsButton")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        Button {
            viewModel.selectPhotoTapped()
        } label: {
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
                            .fill(Color.appPrimary)
                            .frame(width: 100, height: 100)
                            .appShadow(.floating)

                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.white)
                    }

                    // Hero copy
                    VStack(spacing: Spacing.xSmall) {
                        Text("프라이버시를 보호할")
                            .font(.appTitle)
                            .foregroundStyle(Color.appLabelPrimary)
                        Text("사진 선택하기")
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.heroCard")
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: Spacing.medium) {
            SecondaryButton("카메라 촬영", icon: "camera") {
                viewModel.cameraTapped()
            }
            .accessibilityIdentifier("home.cameraButton")
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("최근 작업")
                    .font(.appTitle3)
                    .foregroundStyle(Color.appLabelPrimary)
                    .accessibilityIdentifier("home.recentSectionTitle")
                Spacer()
                if !viewModel.recentItems.isEmpty {
                    Button("모두 보기") {}
                        .font(.appSubheadline)
                        .foregroundStyle(Color.appPrimary)
                        .accessibilityIdentifier("home.recentSeeAllButton")
                }
            }
            .padding(.horizontal, Spacing.large)

            if viewModel.recentItems.isEmpty {
                VStack(spacing: Spacing.medium) {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appLabelTertiary)
                    Text("최근 작업이 없습니다.\n위에서 사진을 선택해 시작해보세요.")
                        .font(.appSubheadline)
                        .foregroundStyle(Color.appLabelSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xLarge)
                .background(Color.appPrimary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .padding(.horizontal, Spacing.large)
            } else {
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
}

// MARK: - Recent Item Thumbnail

private struct RecentItemThumbnail: View {
    let item: RecentMaskingItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Blurred thumbnail for privacy
            Image(uiImage: item.thumbnailImage ?? UIImage())
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

// MARK: - Image Loading Overlay

private struct ImageLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: Spacing.medium) {
                ProgressView()
                    .tint(Color.appPrimary)
                    .scaleEffect(1.2)
                Text("사진 불러오는 중...")
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
}

// MARK: - Preview

#Preview("Empty state") {
    HomeView()
        .environment(SettingsStore())
}

#Preview("With recent items") {
    HomeView()
        .environment(SettingsStore())
}
