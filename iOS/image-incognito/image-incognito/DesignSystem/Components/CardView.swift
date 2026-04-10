//
//  CardView.swift
//  image-incognito
//
//  Design System – Card Container Components
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
                    isOn: $loc
                )
                Divider().padding(.leading, 60)
                ToggleCardRow(
                    icon: "info.circle",
                    title: "촬영 정보 제거",
                    isOn: $exif
                )
                Divider().padding(.leading, 60)
                ToggleCardRow(
                    icon: "photo",
                    title: "고해상도 유지",
                    isOn: $hires
                )
            }
        }
        .padding(Spacing.large)
    }
    .background(Color.appBackground)
}
