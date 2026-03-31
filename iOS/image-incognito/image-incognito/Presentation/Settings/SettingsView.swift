//
//  SettingsView.swift
//  image-incognito
//
//  Presentation – App Settings Screen
//  Lets the user configure default ExportSettings for all future exports.
//

import SwiftUI

struct SettingsView: View {

    @Environment(SettingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // @Bindable lets us derive bindings from the @Observable store.
        @Bindable var store = store

        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xxLarge) {
                        exportSection(store: $store)
                        appInfoSection
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.xxxLarge)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
    }

    // MARK: - Export Defaults Section

    private func exportSection(store: Bindable<SettingsStore>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader(
                icon: "square.and.arrow.up",
                title: "내보내기 기본 설정",
                subtitle: "모든 내보내기에 기본으로 적용됩니다"
            )

            SectionCard {
                ToggleCardRow(
                    icon: "location.slash.fill",
                    title: "위치 정보 제거",
                    isOn: store.exportSettings.removeLocation
                )

                Divider().padding(.leading, 60)

                ToggleCardRow(
                    icon: "info.circle.fill",
                    title: "촬영 정보 제거",
                    isOn: store.exportSettings.removeExif
                )

                Divider().padding(.leading, 60)

                ToggleCardRow(
                    icon: "photo.fill",
                    title: "고해상도 유지",
                    isOn: store.exportSettings.keepOriginalResolution
                )
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader(
                icon: "info.circle",
                title: "앱 정보",
                subtitle: nil
            )

            AppCard {
                VStack(spacing: 0) {
                    InfoRow(label: "버전", value: appVersion)
                    Divider().padding(.leading, Spacing.medium)
                    InfoRow(label: "개발", value: "Elvin Heo")
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: icon)
                .imageScale(.small)
                .foregroundStyle(Color.appPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.appTitle3)
                    .foregroundStyle(Color.appLabelPrimary)
                if let subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelSecondary)
                }
            }
        }
        .padding(.leading, Spacing.xxSmall)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .font(.appBody)
                .foregroundStyle(Color.appLabelPrimary)
            Spacer()
            Text(value)
                .font(.appBody)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(SettingsStore())
}

#Preview("Dark Mode") {
    SettingsView()
        .environment(SettingsStore())
        .preferredColorScheme(.dark)
}
