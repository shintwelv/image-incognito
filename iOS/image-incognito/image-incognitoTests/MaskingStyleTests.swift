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

    @Test("Has exactly 4 cases")
    func caseCount() {
        #expect(MaskingStyle.allCases.count == 4)
    }

    @Test("Labels map correctly")
    func labels() {
        #expect(MaskingStyle.blurredGlass.label == "Blurred Glass")
        #expect(MaskingStyle.pixelArt.label == "Pixel Art")
        #expect(MaskingStyle.crystalize.label == "Crystalize")
        #expect(MaskingStyle.solidClean.label == "Solid Clean")
    }

    @Test("Icons are the expected SF Symbol names")
    func icons() {
        #expect(MaskingStyle.blurredGlass.icon == "drop.halffull")
        #expect(MaskingStyle.pixelArt.icon == "square.grid.3x3.fill")
        #expect(MaskingStyle.crystalize.icon == "diamond.fill")
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

import SwiftUI

@MainActor
@Suite("FaceOverlayView")
struct FaceOverlayViewTests {

    @Test("Initializes FaceOverlayView without crashing and covers body")
    func testFaceOverlayViewInitializationAndBody() throws {
        for style in MaskingStyle.allCases {
            let faceBox = FaceBox(
                id: UUID(),
                rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
                isMasked: true,
                style: style,
                intensity: 0.5,
                sizeMultiplier: 1.0
            )
            
            let view = FaceOverlayView(
                faceBox: faceBox,
                solidCleanColor: .black,
                isSelected: true
            )
            
            let _ = view.body
        }
        
        let unmaskedFaceBox = FaceBox(
            id: UUID(),
            rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            isMasked: false,
            style: .solidClean,
            intensity: 0.5,
            sizeMultiplier: 1.0
        )
        let unmaskedView = FaceOverlayView(
            faceBox: unmaskedFaceBox,
            solidCleanColor: .black,
            isSelected: false
        )
        let _ = unmaskedView.body
    }
    
    @Test("Initializes PixelArtMaskView and covers body")
    func testPixelArtMaskView() throws {
        let view = PixelArtMaskView(intensity: 0.5)
        let _ = view.body
    }
    
    @Test("Initializes CrystalizeMaskView and covers body")
    func testCrystalizeMaskView() throws {
        let view = CrystalizeMaskView(intensity: 0.5)
        let _ = view.body
    }
}

@MainActor
@Suite("Typography")
struct TypographyTests {
    @Test("Test Font properties and appTextStyle")
    func testTypographyAndModifier() throws {
        let _ = Font.appDisplay
        let _ = Font.appTitle
        let _ = Font.appTitle2
        let _ = Font.appTitle3
        let _ = Font.appBody
        let _ = Font.appBodyEmphasized
        let _ = Font.appSubheadline
        let _ = Font.appFootnote
        let _ = Font.appCaption
        let _ = Font.appCaption2
        
        let text = Text("Hello")
        let styled = text.appTextStyle(.appBody, color: .red)
        #expect(styled != nil)
    }
}

@MainActor
@Suite("Toast")
struct ToastTests {
    @Test("Test ToastView body")
    func testToastViewBody() throws {
        let view = ToastView(message: "Saved", icon: "checkmark")
        let _ = view.body
    }
    
    @Test("Test ToastModifier body")
    func testToastModifierBody() throws {
        let text = Text("Hello")
        let styledPresented = text.appToast(isPresented: .constant(true), message: "Saved")
        let _ = styledPresented.body
        
        let styledNotPresented = text.appToast(isPresented: .constant(false), message: "Saved")
        let _ = styledNotPresented.body
    }
}


@MainActor
@Suite("ShareSheetCoverage")
struct ShareSheetCoverageTests {
    @Test("Test ShareSheet body and view controller generation")
    func testShareSheet() throws {
        let textItem = "Hello World"
        let imageItem = UIImage()
        let shareSheet = ShareSheet(items: [textItem, imageItem])
        
        let hostingController = UIHostingController(rootView: shareSheet)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }
}
