# Agent Rules

You are a senior iOS engineer with expertise in SwiftUI and Clean Architecture.

## Project Overview
- App Name: Image Incognito
- Objective: An iOS application that automatically detects faces in photos and applies aesthetic masking (Blur, Pixelation, etc.) to protect privacy while maintaining the photo's visual quality for SNS sharing.
- Target Platform: iOS (17.0 +)
- Primary User: SNS users (Instagram, etc.) who care about portrait rights and aesthetics.

## Technical Stack & Architecture
- Language: Swift
- UI Framework: SwiftUI
- Architecture: Clean Architecture with MVVM
- Domain Layer: Entities, Use Cases, Repository Protocols (Logic-heavy, no dependencies).
- Data Layer: Repository Implementations, Image Processing Services (Vision Framework, Core Image).
- Presentation Layer: SwiftUI Views, ViewModels (State-driven).
- Core Libraries: * Vision: For high-performance face detection. * Core Image / Metal: For image filtering and masking. * PhotosUI: For system gallery access.

### Folder Structure
- Domain: Entities, UseCases, Interfaces
- Data: Repositories, Services (Vision, Filter)
- Presentation: Views, ViewModels

### Coding Convention
- Use Swift Package Manager for dependency management.
- Use Async/Await for asynchronous operations.
- Use `@Observable` macro for state management.
- Use `ViewModifier` for reusable UI components.
- Use Initializer Injection for dependency injection.
- Use `throws` for error handling.

## Domain Languages
- Mask: The instance of applying a filter to a face to protect privacy.
- Obfuscation: The behavior of applying a filter to a face to protect privacy.

## Engineering Principles & Constraints
- Clean Code: Follow SOLID principles. Prioritize readability and maintainability.
- Side-Effect Management: Ensure image processing happens on background threads to keep the UI responsive. Use Async/Await.
- Test-Driven approach: Write Unit Tests for the Domain Logic (e.g., face detection coordinate mapping) and Data Layer (e.g., image processing pipelines).
- UI/UX: Minimalist and "Apple-like" interface. Use SF Symbols for icons.
- VisionKit doesn't work on Simulator

## Design Tokens

| Category | Specification | Notes |
| :---- | :---- | :---- |
| **Color Palette** | Main: \#5E5CE6 (Indigo) / BG: \#F2F2F7 (System Gray 6\) / Dark Mode Support | Emphasize trust and sophistication |
| **Typography** | Font: San Francisco (iOS System Font) / Body: 17pt, Title: 28pt Bold | Prioritize readability |
| **Icons** | SF Symbols 5.0 (Standard, Variable Color) | Maintain system consistency |
| **Border Radius** | Elements: 12pt / Buttons: 16pt / Cards: 20pt | Soft curvature of 'Continuous' style |

## UI Guidelines (Design Mockup Image Description)
* **Glassmorphism:** Apply a subtle blur effect to the bottom toolbar to create a modern feel.  
* **Empty State:** When photo access permission is not granted, place a clean illustration and guide button to direct the user to system settings.  
* **Dark Mode:** Use Deep Gray (1C1C1E) instead of pure Black (000000) for all backgrounds to reduce eye strain.