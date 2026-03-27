//
//  ExportSettings.swift
//  image-incognito
//
//  Domain Entity – User-configurable options applied before saving/sharing.
//

import Foundation

struct ExportSettings: Codable {
    /// Strip GPS / location metadata from EXIF. Default ON.
    var removeLocation: Bool = true
    /// Strip all EXIF metadata (camera model, shutter speed, etc.). Default ON.
    var removeExif: Bool = true
    /// Preserve the original image resolution when saving. Default ON.
    var keepOriginalResolution: Bool = true
}
