//
//  ExportView.swift
//  image-incognito
//
//  Screen 3 – Export & Metadata Settings
//  마스킹 완료 이미지 미리보기 + 메타데이터 옵션 + 저장/공유 액션
//

import SwiftUI

struct ExportView: View {

    @State private var viewModel: ExportViewModel
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(\.dismiss) private var dismiss

    init(maskedImage: UIImage) {
        _viewModel = State(initialValue: ExportViewModel(maskedImage: maskedImage))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.xSmall)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        resultPreviewCard
                        settingsCard
                        actionButtons
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.xxxLarge)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Seed settings from the app-wide store when the view first appears.
        .onAppear {
            viewModel.settings = settingsStore.exportSettings
        }
        // System share sheet
        .sheet(isPresented: $viewModel.isShowingShareSheet) {
            ShareSheet(items: [viewModel.maskedImage])
                .ignoresSafeArea()
        }
        // Save error alert
        .alert("저장 실패", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("확인", role: .cancel) { viewModel.dismissError() }
        } message: {
            if let error = viewModel.saveError {
                Text(error)
            }
        }
        // Save success toast
        .appToast(isPresented: $viewModel.showSaveToast, message: "저장 완료")
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                AppHaptics.light()
                dismiss()
            } label: {
                HStack(spacing: Spacing.xxSmall) {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .fontWeight(.semibold)
                    Text("편집기")
                        .font(.appBody)
                }
                .foregroundStyle(Color.appLabelSecondary)
            }

            Spacer()

            Text("내보내기")
                .font(.appBodyEmphasized)
                .foregroundStyle(Color.appLabelPrimary)

            Spacer()

            // Balancing spacer element (same width as back button area)
            Color.clear
                .frame(width: 60, height: 1)
        }
    }

    // MARK: - Result Preview Card

    private var resultPreviewCard: some View {
        AppCard {
            VStack(spacing: 0) {
                Image(uiImage: viewModel.maskedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Radius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Radius.card,
                            style: .continuous
                        )
                    )

                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "checkmark.shield.fill")
                        .imageScale(.small)
                        .foregroundStyle(Color.appSuccess)
                    Text("마스킹 완료")
                        .font(.appFootnote)
                        .foregroundStyle(Color.appLabelSecondary)
                    Spacer()
                    Text(imageSizeDescription)
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelTertiary)
                        .monospacedDigit()
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
        }
    }

    private var imageSizeDescription: String {
        let size = viewModel.maskedImage.size
        return "\(Int(size.width)) × \(Int(size.height))"
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("저장 옵션")
                .font(.appTitle3)
                .foregroundStyle(Color.appLabelPrimary)
                .padding(.leading, Spacing.xxSmall)

            SectionCard {
                ToggleCardRow(
                    icon: "location.slash.fill",
                    title: "위치 정보 제거",
                    isOn: $viewModel.settings.removeLocation
                )

                Divider()
                    .padding(.leading, 60)

                ToggleCardRow(
                    icon: "info.circle.fill",
                    title: "촬영 정보 제거",
                    isOn: $viewModel.settings.removeExif
                )

                Divider()
                    .padding(.leading, 60)

                ToggleCardRow(
                    icon: "photo.fill",
                    title: "고해상도 유지",
                    isOn: $viewModel.settings.keepOriginalResolution
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.medium) {
            // Primary: Save to Photos
            Button {
                Task { await viewModel.saveToPhotos() }
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .imageScale(.medium)
                    }
                    Text(viewModel.isSaving ? "저장 중..." : "앨범에 저장")
                        .font(.appBodyEmphasized)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
                .background(Color.appPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
            .animation(AppAnimation.snappy, value: viewModel.isSaving)

            // Secondary: Share to Instagram (system share sheet)
            SecondaryButton("인스타그램 공유", icon: "square.and.arrow.up") {
                viewModel.shareImageTapped()
            }
            .disabled(viewModel.isSaving)
        }
    }
}

// MARK: - Preview

#Preview("Export – Light") {
    NavigationStack {
        ExportView(maskedImage: previewMaskedImage())
    }
    .environment(SettingsStore())
}

#Preview("Export – Dark Mode") {
    NavigationStack {
        ExportView(maskedImage: previewMaskedImage())
    }
    .environment(SettingsStore())
    .preferredColorScheme(.dark)
}

private func previewMaskedImage() -> UIImage {
    let size = CGSize(width: 390, height: 520)
    return UIGraphicsImageRenderer(size: size).image { ctx in
        // Background gradient
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                UIColor.systemIndigo.withAlphaComponent(0.3).cgColor,
                UIColor.systemGray5.cgColor
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.cgContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: 0, y: size.height),
            options: []
        )

        // Simulated face with blur mask
        UIColor.systemGray3.setFill()
        UIBezierPath(ovalIn: CGRect(x: 130, y: 160, width: 130, height: 150)).fill()

        // Mask overlay representation
        UIColor.systemIndigo.withAlphaComponent(0.6).setFill()
        UIBezierPath(roundedRect: CGRect(x: 120, y: 150, width: 150, height: 170), cornerRadius: 12).fill()
    }
}
