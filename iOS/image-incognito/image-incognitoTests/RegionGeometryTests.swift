//
//  RegionGeometryTests.swift
//  image-incognitoTests
//
//  Unit tests for RegionGeometry: clamping, drag normalization, circle
//  invariants, shape conversion, minimum sizes, and hit testing.
//

import CoreGraphics
import Testing
@testable import image_incognito

@Suite("RegionGeometry")
struct RegionGeometryTests {

    private let accuracy: CGFloat = 0.0001

    // MARK: - Clamping

    @Test("clamped standardizes negative-size rects")
    func clampedStandardizes() {
        let rect = RegionGeometry.clamped(CGRect(x: 0.6, y: 0.6, width: -0.3, height: -0.3))

        #expect(rectsAreEqual(rect, CGRect(x: 0.3, y: 0.3, width: 0.3, height: 0.3)))
    }

    @Test("clamped intersects rects with the unit square")
    func clampedIntersects() {
        let rect = RegionGeometry.clamped(CGRect(x: 0.8, y: 0.8, width: 0.5, height: 0.5))

        #expect(abs(rect.minX - 0.8) < accuracy)
        #expect(abs(rect.minY - 0.8) < accuracy)
        #expect(abs(rect.width - 0.2) < accuracy)
        #expect(abs(rect.height - 0.2) < accuracy)
    }

    @Test("clamped collapses rects fully outside to zero-size anchors")
    func clampedFullyOutside() {
        let beyond = RegionGeometry.clamped(CGRect(x: 2, y: 2, width: 1, height: 1))
        let before = RegionGeometry.clamped(CGRect(x: -1, y: -1, width: 0.5, height: 0.5))

        #expect(beyond.isEmpty)
        #expect(beyond.minX == 1)
        #expect(beyond.minY == 1)
        #expect(before.isEmpty)
        #expect(before.minX == 0)
        #expect(before.minY == 0)
    }

    @Test("clamped is zero-safe for non-finite input")
    func clampedNonFinite() {
        #expect(RegionGeometry.clamped(CGRect(x: .nan, y: 0, width: 0.2, height: 0.2)) == .zero)
        #expect(RegionGeometry.clamped(CGRect(x: 0, y: 0, width: .infinity, height: 0.2)) == .zero)
    }

    // MARK: - Minimum size

    @Test("Minimum size accepts rects at or above the threshold")
    func minimumSizeAccepts() {
        #expect(RegionGeometry.minimumNormalizedSize == 0.01)
        #expect(RegionGeometry.isAtLeastMinimumSize(CGRect(x: 0, y: 0, width: 0.01, height: 0.01)))
        #expect(RegionGeometry.isAtLeastMinimumSize(CGRect(x: 0, y: 0, width: 0.5, height: 0.2)))
    }

    @Test("Minimum size rejects smaller or zero rects")
    func minimumSizeRejects() {
        #expect(!RegionGeometry.isAtLeastMinimumSize(CGRect(x: 0, y: 0, width: 0.0099, height: 0.2)))
        #expect(!RegionGeometry.isAtLeastMinimumSize(CGRect(x: 0, y: 0, width: 0.2, height: 0.0099)))
        #expect(!RegionGeometry.isAtLeastMinimumSize(CGRect(x: 0.5, y: 0.5, width: 0, height: 0)))
    }

    // MARK: - Drag rects

    @Test("normalizedRect builds a rect from drag points in any order")
    func normalizedRectAnyOrder() {
        let forward = RegionGeometry.normalizedRect(from: CGPoint(x: 0.2, y: 0.3), to: CGPoint(x: 0.6, y: 0.7))
        let reverse = RegionGeometry.normalizedRect(from: CGPoint(x: 0.6, y: 0.7), to: CGPoint(x: 0.2, y: 0.3))

        #expect(rectsAreEqual(forward, CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.4)))
        #expect(rectsAreEqual(reverse, forward))
    }

    @Test("normalizedRect clamps drag points to the unit square")
    func normalizedRectClamps() {
        let rect = RegionGeometry.normalizedRect(from: CGPoint(x: -0.2, y: 0.5), to: CGPoint(x: 0.5, y: 1.5))

        #expect(rectsAreEqual(rect, CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)))
    }

    @Test("squareRect centers a square on the given point")
    func squareRectCenters() {
        let rect = RegionGeometry.squareRect(center: CGPoint(x: 0.5, y: 0.5), side: 0.2)

        #expect(abs(rect.minX - 0.4) < accuracy)
        #expect(abs(rect.minY - 0.4) < accuracy)
        #expect(abs(rect.width - 0.2) < accuracy)
        #expect(abs(rect.height - 0.2) < accuracy)
    }

    // MARK: - Circle drag

    @Test("circleRect uses the longest drag edge as diameter")
    func circleRectElongated() {
        let rect = RegionGeometry.circleRect(from: CGPoint(x: 0.2, y: 0.2), to: CGPoint(x: 0.6, y: 0.3))

        #expect(rect.width == rect.height)
        #expect(abs(rect.width - 0.4) < accuracy)
        #expect(abs(rect.midX - 0.4) < accuracy)
        #expect(abs(rect.midY - 0.25) < accuracy)
        #expect(rectsAreEqual(rect, CGRect(x: 0.2, y: 0.05, width: 0.4, height: 0.4)))
    }

    @Test("circleRect clamps and shrinks so the circle fits the unit square")
    func circleRectEdgeShrinks() {
        let rect = RegionGeometry.circleRect(from: CGPoint(x: 0.93, y: 0.93), to: CGPoint(x: 1.03, y: 1.03))

        #expect(rect.width == rect.height)
        #expect(abs(rect.maxX - 1) < accuracy)
        #expect(abs(rect.maxY - 1) < accuracy)
        #expect(abs(rect.width - 0.07) < accuracy)
        #expect(rect.minX >= 0)
        #expect(rect.minY >= 0)
    }

    @Test("circleRect keeps the diameter when the drag box already fits")
    func circleRectInside() {
        let rect = RegionGeometry.circleRect(from: CGPoint(x: 0.8, y: 0.8), to: CGPoint(x: 1.0, y: 0.9))

        #expect(rect.width == rect.height)
        #expect(abs(rect.width - 0.2) < accuracy)
        #expect(abs(rect.minX - 0.8) < accuracy)
        #expect(abs(rect.minY - 0.75) < accuracy)
    }

    // MARK: - Shape conversion

    @Test("Converting to rectangle or ellipse keeps the bounding rect")
    func convertKeepsRectForRectangularShapes() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.2)

        #expect(rectsAreEqual(RegionGeometry.convert(rect, to: .rectangle), rect))
        #expect(rectsAreEqual(RegionGeometry.convert(rect, to: .ellipse), rect))
    }

    @Test("Converting to circle squares the rect around its center")
    func convertToCircle() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.2)
        let converted = RegionGeometry.convert(rect, to: .circle)

        #expect(converted.width == converted.height)
        #expect(abs(converted.midX - 0.4) < accuracy)
        #expect(abs(converted.midY - 0.3) < accuracy)
        #expect(rectsAreEqual(converted, CGRect(x: 0.2, y: 0.1, width: 0.4, height: 0.4)))
    }

    @Test("Converting to circle clamps the square inside the unit square")
    func convertToCircleAtEdge() {
        let converted = RegionGeometry.convert(CGRect(x: 0.8, y: 0.8, width: 0.4, height: 0.2), to: .circle)

        #expect(converted.width == converted.height)
        #expect(converted.minX >= 0)
        #expect(converted.minY >= 0)
        #expect(converted.maxX <= 1)
        #expect(converted.maxY <= 1)
    }

    // MARK: - Hit testing

    @Test("Rectangle hit testing includes corners")
    func containsRectangle() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)

        #expect(RegionGeometry.contains(CGPoint(x: 0.4, y: 0.4), in: rect, shape: .rectangle))
        #expect(RegionGeometry.contains(CGPoint(x: 0.21, y: 0.21), in: rect, shape: .rectangle))
        #expect(!RegionGeometry.contains(CGPoint(x: 0.7, y: 0.7), in: rect, shape: .rectangle))
    }

    @Test("Ellipse hit testing excludes bounding-box corners")
    func containsEllipse() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)

        #expect(RegionGeometry.contains(CGPoint(x: 0.4, y: 0.4), in: rect, shape: .ellipse))
        #expect(RegionGeometry.contains(CGPoint(x: 0.4, y: 0.21), in: rect, shape: .ellipse))
        #expect(!RegionGeometry.contains(CGPoint(x: 0.21, y: 0.21), in: rect, shape: .ellipse))
    }

    @Test("Circle hit testing uses the inscribed circle")
    func containsCircle() {
        let rect = RegionGeometry.convert(CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4), to: .circle)

        #expect(RegionGeometry.contains(CGPoint(x: 0.4, y: 0.4), in: rect, shape: .circle))
        #expect(!RegionGeometry.contains(CGPoint(x: 0.21, y: 0.21), in: rect, shape: .circle))
        #expect(!RegionGeometry.contains(CGPoint(x: 0.4, y: 0.4), in: .zero, shape: .circle))
    }

    // MARK: - Coordinate helper

    @Test("normalizedPoint maps display coordinates into unit space")
    func normalizedPointMapping() {
        let imageRect = CGRect(x: 50, y: 50, width: 200, height: 100)

        let center = RegionGeometry.normalizedPoint(CGPoint(x: 150, y: 100), in: imageRect)
        #expect(abs(center.x - 0.5) < accuracy)
        #expect(abs(center.y - 0.5) < accuracy)

        let origin = RegionGeometry.normalizedPoint(CGPoint(x: 50, y: 50), in: imageRect)
        #expect(origin == .zero)
    }

    @Test("normalizedPoint is zero-safe for degenerate image rects")
    func normalizedPointDegenerate() {
        #expect(RegionGeometry.normalizedPoint(CGPoint(x: 10, y: 10), in: .zero) == .zero)
    }
}
