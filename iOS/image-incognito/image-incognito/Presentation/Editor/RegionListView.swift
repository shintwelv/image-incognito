//
//  RegionListView.swift
//  image-incognito
//
//  Sheet listing every maskable region with inclusion, shape, status, and
//  style. Rows select; check buttons toggle inclusion; swipe/context deletes.
//

import SwiftUI

struct RegionListView: View {
    let viewModel: EditorViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.regions.isEmpty {
                    emptyState
                } else {
                    regionList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("editor.regionList.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("editor.cancel")
                            .font(.appBody)
                            .foregroundStyle(Color.appLabelSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityIdentifier("editor.regionList.close")
                }
            }
        }
        .accessibilityIdentifier("editor.regionList")
    }

    // MARK: - List

    private var regionList: some View {
        List {
            ForEach(viewModel.regions) { region in
                row(for: region)
                    .listRowBackground(Color.appSurface)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text(accessibilityLabel(for: region)))
                    .accessibilityAddTraits(
                        region.id == viewModel.selectedRegionID ? .isSelected : AccessibilityTraits()
                    )
                    .accessibilityIdentifier("editor.regionRow.\(region.id.uuidString)")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteRegion(id: region.id)
                        } label: {
                            Label("editor.region.delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteRegion(id: region.id)
                        } label: {
                            Label("editor.region.delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(for region: MaskRegion) -> some View {
        HStack(spacing: Spacing.small) {
            Button {
                select(region)
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: region.isManual ? region.shape.iconName : "person.fill")
                        .imageScale(.medium)
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.appPrimary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(LocalizedStringKey(region.isManual ? "editor.region.manual" : "editor.region.face"))
                            .font(.appBody)
                            .foregroundStyle(Color.appLabelPrimary)

                        HStack(spacing: Spacing.xxSmall) {
                            Text(LocalizedStringKey(region.isIncluded ? "editor.region.included" : "editor.region.excluded"))
                                .font(.appCaption)
                                .foregroundStyle(region.isIncluded ? Color.appPrimary : Color.appDestructive)
                            Text("·")
                                .font(.appCaption)
                                .foregroundStyle(Color.appLabelTertiary)
                            Text(LocalizedStringKey(region.style.label))
                                .font(.appCaption)
                                .foregroundStyle(Color.appLabelSecondary)
                            if region.isManual {
                                Text("·")
                                    .font(.appCaption)
                                    .foregroundStyle(Color.appLabelTertiary)
                                Text(LocalizedStringKey(region.shape.labelKey))
                                    .font(.appCaption)
                                    .foregroundStyle(Color.appLabelSecondary)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("editor.regionRowSelect.\(region.id.uuidString)")

            Button {
                AppHaptics.light()
                viewModel.toggleInclusion(id: region.id)
            } label: {
                Image(systemName: region.isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(region.isIncluded ? Color.appPrimary : Color.appLabelTertiary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                LocalizedStringKey(region.isIncluded ? "editor.region.exclude" : "editor.region.include")
            )
            .accessibilityIdentifier("editor.regionRowCheck.\(region.id.uuidString)")
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.appLabelTertiary)
            Text("editor.regionList.empty")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xLarge)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editor.regionList.empty")
    }

    // MARK: - Helpers

    private func select(_ region: MaskRegion) {
        viewModel.selectRegion(id: region.id)
        onDismiss()
    }

    private func accessibilityLabel(for region: MaskRegion) -> String {
        let type = NSLocalizedString(region.isManual ? "editor.region.manual" : "editor.region.face", comment: "")
        let status = NSLocalizedString(region.isIncluded ? "editor.region.included" : "editor.region.excluded", comment: "")
        let style = NSLocalizedString(region.style.label, comment: "")
        if region.isManual {
            let shape = NSLocalizedString(region.shape.labelKey, comment: "")
            return "\(type) · \(shape) · \(status) · \(style)"
        }
        return "\(type) · \(status) · \(style)"
    }
}
