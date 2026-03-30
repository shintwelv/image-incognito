//
//  CardView.swift
//  image-incognito
//
//  Design System – Card Container Component
//  Radius: 20pt (Tokens.Radius.card) / Surface: appSurface
//

import SwiftUI

// MARK: - App Card

struct AppCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .appShadow(.card)
    }
}

// MARK: - Settings Toggle Card Row

struct ToggleCardRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    @Binding var isOn: Bool

    init(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = LocalizedStringKey(title)
        self.subtitle = LocalizedStringKey(subtitle ?? "")
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .imageScale(.medium)
                .frame(width: 32, height: 32)
                .background(Color.appPrimary.opacity(0.12))
                .foregroundStyle(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appBody)
                    .foregroundStyle(Color.appLabelPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.appPrimary)
        }
        .padding(Spacing.medium)
    }
}

// MARK: - Section Card (groups multiple rows)

struct SectionCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        AppCard {
            VStack(spacing: 0) {
                content()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var loc = true
    @Previewable @State var exif = true
    @Previewable @State var hires = true

    ScrollView {
        VStack(spacing: Spacing.medium) {
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("카드 타이틀")
                        .font(.appTitle3)
                    Text("카드 내용 예시입니다.")
                        .font(.appBody)
                        .foregroundStyle(Color.appLabelSecondary)
                }
                .padding(Spacing.large)
            }

            SectionCard {
                ToggleCardRow(
                    icon: "location.slash",
                    title: "위치 정보 제거",
                    subtitle: "Remove Location",
                    isOn: $loc
                )
                Divider().padding(.leading, 60)
                ToggleCardRow(
                    icon: "info.circle",
                    title: "촬영 정보 제거",
                    subtitle: "Remove Exif",
                    isOn: $exif
                )
                Divider().padding(.leading, 60)
                ToggleCardRow(
                    icon: "photo",
                    title: "고해상도 유지",
                    subtitle: "Original Resolution",
                    isOn: $hires
                )
            }
        }
        .padding(Spacing.large)
    }
    .background(Color.appBackground)
}
