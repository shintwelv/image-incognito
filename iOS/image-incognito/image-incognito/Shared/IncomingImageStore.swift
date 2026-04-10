//
//  IncomingImageStore.swift
//  image-incognito
//
//  Shared – Observable store that carries images received from external apps
//  (e.g. Photos share sheet) into the SwiftUI navigation hierarchy.
//

import UIKit
import Observation

@Observable
final class IncomingImageStore {
    /// Non-empty when another app has shared images with us via the system
    /// share sheet. Consumed and cleared by HomeView.
    var pendingImages: [UIImage] = []
}
