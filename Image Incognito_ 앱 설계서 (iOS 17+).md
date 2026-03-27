# **Image Incognito: 상세 앱 설계서 (iOS 17+)**

## **1\. 프로젝트 개요**

* **앱 명칭:** Image Incognito (이미지 인코그니토)  
* **핵심 가치:** 프라이버시 보호(On-device AI), 감성적인 마스킹, 미니멀 UI  
* **최소 지원 버전:** iOS 17.0  
* **주요 기술:** SwiftUI, Observation, Vision Framework, Core Image

## **2\. 시스템 아키텍처 (Clean Architecture)**

의존성 규칙을 준수하여 **Domain → Data ← Presentation** 구조로 설계합니다.

### **2.1. Domain Layer (Pure Swift)**

외부 환경(UI, DB, API)에 의존하지 않는 비즈니스 로직의 핵심입니다.

* **Entities:**  
  * Face: 감지된 얼굴 정보 (ID, BoundingBox, Confidence, IsMasked)  
  * MaskingOption: 마스킹 스타일(Blur, Pixel, Solid) 및 강도 데이터  
* **UseCases:**  
  * DetectFacesUseCase: 이미지에서 얼굴을 찾는 비즈니스 규칙  
  * ProcessMaskingUseCase: 선택된 스타일로 이미지를 가공하는 규칙  
* **Interfaces:**  
  * FaceDetectorProtocol, ImageProcessorProtocol, PhotoRepositoryProtocol

### **2.2. Data Layer (Implementation)**

실제 프레임워크와의 통신 및 데이터 처리를 담당합니다.

* **Repositories:** Domain의 Interface를 구현하여 실제 데이터를 전달  
* **Services:**  
  * VisionFaceDetector: iOS Vision API를 이용한 온디바이스 얼굴 인식  
  * CoreImageProcessor: Core Image 필터를 활용한 렌더링 엔진  
  * PhotoLibraryManager: PHPicker 및 사진첩 저장 로직

### **2.3. Presentation Layer (SwiftUI \+ MVVM)**

iOS 17의 **Observation** 프레임워크를 적용합니다.

* **Views:** SwiftUI 기반의 선언적 UI  
* **ViewModels:** @Observable 클래스를 사용하여 뷰 상태 관리  
* **Components:** 버튼, 슬라이더, 이미지 캔버스 등 재사용 가능한 UI 요소

## **3\. 핵심 기능 설계 (Technical Details)**

### **3.1. 지능형 얼굴 감지 (Vision)**

* **구현 방식:** VNDetectFaceRectanglesRequest를 사용하여 이미지 로드 시 즉시 실행.  
* **최적화:** 고해상도 이미지의 경우 내부적으로 다운샘플링하여 감지 속도 향상.  
* **Privacy:** 모든 처리는 로컬 디바이스 내에서만 이루어짐 (네트워크 통신 없음).

### **3.2. 스마트 마스킹 모드 (Image Processing)**

Core Image의 CIFilter 체인을 활용합니다.

1. **Blurred Glass:** CIBoxBlur \+ 원본 이미지와의 마스킹 합성을 통해 배경 색감이 투영된 블러 구현.  
2. **Pixel Art:** CIPixellate 필터 적용.  
3. **Solid Clean:** 해당 영역을 특정 단색 또는 그라디언트로 채움.

## **4\. 데이터 흐름 (Data Flow)**

1. **Input:** 사용자가 PHPicker를 통해 사진 선택.  
2. **Analysis:** DetectFacesUseCase가 실행되어 Face 엔티티 리스트 생성.  
3. **State:** ViewModel의 faces 배열이 업데이트되며 뷰에 바운딩 박스 표시.  
4. **Interaction:** 사용자가 특정 얼굴 터치 또는 스타일 변경.  
5. **Processing:** ProcessMaskingUseCase가 백그라운드 스레드에서 UIImage 가공.  
6. **Output:** 가공된 이미지를 뷰에 표시하고, 확정 시 PHPhotoLibrary에 저장.

## **5\. UI/UX 디자인 가이드라인**

* **Minimalism:** 불필요한 테두리를 제거하고 시스템 블러(Material) 효과 활용.  
* **Haptics:** 얼굴이 감지되거나 마스킹이 적용될 때 미세한 햅틱 피드백 제공.  
* **Gesture:** 이미지 확대/축소(Pinch), 얼굴 선택(Tap), 마스킹 강도 조절(Slide).

## **6\. 테스트 전략 (Testing)**

### **6.1. Unit Testing (Domain & ViewModel)**

* DetectFacesUseCase가 빈 이미지나 얼굴이 없는 이미지에서 올바르게 작동하는지 확인.  
* @Observable ViewModel의 상태 변화가 의도대로 일어나는지 검증.

### **6.2. Integration Testing (Image Processing)**

* 각 CIFilter가 적용된 결과물이 nil이 아닌 유효한 이미지를 반환하는지 테스트.

## **7\. 향후 확장성 (Future-proofing)**

* **AI Inpainting:** ImageProcessorProtocol을 확장하여 Generative AI 기반의 배경 채우기 기능 추가 가능.  
* **Video Support:** Vision의 VNSession을 활용하여 동영상 내 얼굴 추적 및 실시간 마스킹 확장 고려.