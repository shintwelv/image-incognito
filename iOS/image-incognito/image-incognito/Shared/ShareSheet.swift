//
//  ShareSheet.swift
//  image-incognito
//
//  Shared – UIActivityViewController wrapper for the system share sheet.
//  Images are wrapped in ShareableImage so the app name and icon appear
//  in the share sheet's rich-preview header via LPLinkMetadata.
//

import SwiftUI
import LinkPresentation

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let wrapped = items.map { item -> Any in
            if let image = item as? UIImage { return ShareableImage(image) }
            return item
        }
        return UIActivityViewController(activityItems: wrapped, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ShareableImage

/// Wraps a UIImage as a UIActivityItemSource so that LPLinkMetadata can be
/// supplied, causing the app name and icon to appear in the share sheet header.
private final class ShareableImage: NSObject, UIActivityItemSource {
    private let image: UIImage

    init(_ image: UIImage) { self.image = image }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any { image }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? { image }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = Bundle.main.displayName ?? "Incognify"
        metadata.imageProvider = NSItemProvider(object: image)
        if let icon = UIImage(named: "AppIcon") {
            metadata.iconProvider = NSItemProvider(object: icon)
        }
        return metadata
    }
}

// MARK: - Bundle helper

private extension Bundle {
    var displayName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
