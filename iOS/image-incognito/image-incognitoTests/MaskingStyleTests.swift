//
//  MaskingStyleTests.swift
//  image-incognitoTests
//
//  Unit tests for the MaskingStyle domain enum.
//

import Testing
@testable import image_incognito

@Suite("MaskingStyle")
struct MaskingStyleTests {

    @Test("Has exactly 3 cases")
    func caseCount() {
        #expect(MaskingStyle.allCases.count == 3)
    }

    @Test("Labels map correctly")
    func labels() {
        #expect(MaskingStyle.blurredGlass.label == "Blurred Glass")
        #expect(MaskingStyle.pixelArt.label == "Pixel Art")
        #expect(MaskingStyle.solidClean.label == "Solid Clean")
    }

    @Test("Icons are the expected SF Symbol names")
    func icons() {
        #expect(MaskingStyle.blurredGlass.icon == "drop.halffull")
        #expect(MaskingStyle.pixelArt.icon == "square.grid.3x3.fill")
        #expect(MaskingStyle.solidClean.icon == "circle.fill")
    }

    @Test("id equals rawValue for all cases")
    func idEqualsRawValue() {
        for style in MaskingStyle.allCases {
            #expect(style.id == style.rawValue)
        }
    }

    @Test("rawValue round-trips back to the same case")
    func rawValueRoundTrip() {
        for style in MaskingStyle.allCases {
            let restored = MaskingStyle(rawValue: style.rawValue)
            #expect(restored == style)
        }
    }
}
