//
//  MaskRegionTests.swift
//  image-incognitoTests
//
//  Unit tests for the MaskRegion domain entity: defaults, shape cases,
//  circle invariants on init and mutation, equality, and identity.
//

import CoreGraphics
import Foundation
import Testing
@testable import image_incognito

@Suite("MaskRegion")
struct MaskRegionTests {

    // MARK: - Defaults

    @Test("Init stores required values and sensible defaults")
    func initDefaults() {
        let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let region = MaskRegion(source: .manual, shape: .rectangle, rect: rect)

        #expect(region.source == .manual)
        #expect(region.shape == .rectangle)
        #expect(rectsAreEqual(region.rect, rect))
        #expect(region.isIncluded == true)
        #expect(region.style == .blurredGlass)
        #expect(region.intensity == 0.75)
        #expect(region.sizeMultiplier == 1.0)
        #expect(region.selectedEmoji == "😎")
        #expect(region.linkedFaceID == nil)
    }

    @Test("Init stores explicit values")
    func initExplicitValues() {
        let id = UUID()
        let faceID = UUID()
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.2, height: 0.2)
        let region = MaskRegion(
            id: id,
            source: .detectedFace,
            shape: .ellipse,
            rect: rect,
            isIncluded: false,
            style: .solidClean,
            intensity: 0.3,
            sizeMultiplier: 1.4,
            selectedEmoji: "🐱",
            linkedFaceID: faceID
        )

        #expect(region.id == id)
        #expect(region.source == .detectedFace)
        #expect(region.shape == .ellipse)
        #expect(rectsAreEqual(region.rect, rect))
        #expect(region.isIncluded == false)
        #expect(region.style == .solidClean)
        #expect(region.intensity == 0.3)
        #expect(region.sizeMultiplier == 1.4)
        #expect(region.selectedEmoji == "🐱")
        #expect(region.linkedFaceID == faceID)
    }

    @Test("Manual regions always use a 1.0 size multiplier and no linked face")
    func manualIgnoresFaceOnlyFields() {
        let region = MaskRegion(
            source: .manual,
            shape: .rectangle,
            rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            sizeMultiplier: 1.9,
            linkedFaceID: UUID()
        )

        #expect(region.sizeMultiplier == 1.0)
        #expect(region.linkedFaceID == nil)
    }

    @Test("isManual and isFace reflect the source")
    func sourceConvenience() {
        let manual = MaskRegion(source: .manual, shape: .rectangle, rect: CGRect(x: 0, y: 0, width: 0.2, height: 0.2))
        let face = MaskRegion(source: .detectedFace, shape: .ellipse, rect: CGRect(x: 0, y: 0, width: 0.2, height: 0.2))

        #expect(manual.isManual)
        #expect(!manual.isFace)
        #expect(face.isFace)
        #expect(!face.isManual)
    }

    // MARK: - Shape

    @Test("Shape cases expose stable raw values and ids")
    func shapeCases() {
        #expect(MaskRegion.Shape.allCases == [.rectangle, .ellipse, .circle])
        #expect(MaskRegion.Shape.rectangle.rawValue == "rectangle")
        #expect(MaskRegion.Shape.ellipse.rawValue == "ellipse")
        #expect(MaskRegion.Shape.circle.rawValue == "circle")

        for shape in MaskRegion.Shape.allCases {
            #expect(shape.id == shape.rawValue)
        }
    }

    // MARK: - Clamping

    @Test("Init clamps rects into the unit square")
    func initClampsRect() {
        let region = MaskRegion(
            source: .manual,
            shape: .rectangle,
            rect: CGRect(x: 0.8, y: -0.2, width: 0.5, height: 0.5)
        )

        #expect(region.rect.minX >= 0)
        #expect(region.rect.minY >= 0)
        #expect(region.rect.maxX <= 1)
        #expect(region.rect.maxY <= 1)
    }

    @Test("Mutating rect re-clamps it")
    func mutationClampsRect() {
        var region = MaskRegion(
            source: .manual,
            shape: .rectangle,
            rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        )

        region.rect = CGRect(x: -0.5, y: 0.9, width: 1.0, height: 0.5)

        #expect(region.rect.minX == 0)
        #expect(region.rect.maxY == 1)
    }

    // MARK: - Circle invariant

    @Test("Circle init squares the rect around its center")
    func circleInitSquaresRect() {
        let region = MaskRegion(
            source: .manual,
            shape: .circle,
            rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.1)
        )

        #expect(region.rect.width == region.rect.height)
        #expect(abs(region.rect.midX - 0.4) < 0.0001)
        #expect(abs(region.rect.midY - 0.25) < 0.0001)
        #expect(rectsAreEqual(region.rect, CGRect(x: 0.2, y: 0.05, width: 0.4, height: 0.4)))
    }

    @Test("Circle rect mutation keeps width equal to height")
    func circleMutationSquaresRect() {
        var region = MaskRegion(
            source: .manual,
            shape: .circle,
            rect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        )

        region.rect = CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.1)

        #expect(region.rect.width == region.rect.height)
        #expect(abs(region.rect.width - 0.3) < 0.0001)
        #expect(region.rect.minX >= 0)
        #expect(region.rect.maxX <= 1)
    }

    @Test("Switching shape to circle squares the rect")
    func switchingToCircleSquaresRect() {
        var region = MaskRegion(
            source: .manual,
            shape: .rectangle,
            rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.3)
        )

        region.shape = .circle

        #expect(region.shape == .circle)
        #expect(region.rect.width == region.rect.height)
        #expect(abs(region.rect.midX - 0.4) < 0.0001)
        #expect(abs(region.rect.midY - 0.35) < 0.0001)
    }

    @Test("Switching shape away from circle preserves the current bounding rect")
    func switchingFromCircleKeepsRect() {
        var region = MaskRegion(
            source: .manual,
            shape: .circle,
            rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        )
        let circleRect = region.rect

        region.shape = .ellipse

        #expect(region.shape == .ellipse)
        #expect(rectsAreEqual(region.rect, circleRect))
    }

    @Test("Circle rects stay inside the unit square at the edge")
    func circleEdgeStaysInsideUnitSquare() {
        let region = MaskRegion(
            source: .manual,
            shape: .circle,
            rect: CGRect(x: 0.8, y: 0.8, width: 0.4, height: 0.4)
        )

        #expect(region.rect.width == region.rect.height)
        #expect(region.rect.minX >= 0)
        #expect(region.rect.minY >= 0)
        #expect(region.rect.maxX <= 1)
        #expect(region.rect.maxY <= 1)
    }

    // MARK: - Equality & identity

    @Test("Regions with identical values are equal")
    func equality() {
        let id = UUID()
        let rect = CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        let a = MaskRegion(id: id, source: .manual, shape: .rectangle, rect: rect)
        let b = MaskRegion(id: id, source: .manual, shape: .rectangle, rect: rect)

        #expect(a == b)
    }

    @Test("Changing any value breaks equality")
    func inequality() {
        let base = MaskRegion(source: .manual, shape: .rectangle, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
        var changed = base
        changed.intensity = 0.1

        #expect(base != changed)
    }

    @Test("Default ids are unique across instances")
    func uniqueIds() {
        let ids = Set((0..<50).map { _ in
            MaskRegion(source: .manual, shape: .rectangle, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)).id
        })

        #expect(ids.count == 50)
    }
}
