# **Image Incognito: UI/UX Design Specification**

**버전:** 1.0

**목표:** AI 기술을 활용한 빠르고 세련된 얼굴 마스킹 경험 제공

**디자인 키워드:** Minimalist, Sophisticated, Intuitive, Privacy-focused

## **1\. 디자인 시스템 (Design Tokens)**

| 구분 | 사양 | 비고 |
| :---- | :---- | :---- |
| **Color Palette** | Main: \#5E5CE6 (Indigo) / BG: \#F2F2F7 (System Gray 6\) / Dark Mode Support | 신뢰감과 세련미 강조 |
| **Typography** | Font: San Francisco (iOS System Font) / Body: 17pt, Title: 28pt Bold | 가독성 위주의 타이포그래피 |
| **Icons** | SF Symbols 5.0 기반 (Standard, Variable Color 사용) | 시스템 일관성 유지 |
| **Border Radius** | Elements: 12pt / Buttons: 16pt / Cards: 20pt | 부드러운 곡률의 'Continuous' 스타일 |

## **2\. 화면별 상세 설계 (Screen-by-Screen)**

### **\[Screen 1\] Home & Library Access**

*앱의 시작점이자 이미지 업로드 경로를 선택하는 화면*

* **Header:** 앱 로고 Incognito와 설정 아이콘.  
* **Hero Area:** "프라이버시를 보호할 사진을 선택하세요" 라는 문구와 함께 감성적인 플레이스홀더 이미지.  
* **Main Actions (Floating or Center):**  
  * \[+\] 사진 선택: 시스템 사진첩 호출 (PHPicker).  
  * \[Camera\] 촬영: 카메라 모드 실행.  
* **Recent List (Optional):** 최근 작업한 마스킹 이미지의 썸네일 리스트 (Privacy를 위해 블러 처리된 상태로 표시).

### **\[Screen 2\] AI Editor (Core Experience)**

*얼굴 감지 결과 확인 및 마스킹 스타일을 적용하는 메인 작업 공간*

* **Top Bar:** \- Cancel 버튼 (홈으로 이동).  
  * Export 버튼 (우측 상단, 강조색).  
* **Main Canvas:** \- 불러온 이미지가 전면에 배치됨.  
  * **Face Overlays:** Vision Framework로 감지된 얼굴 위에 얇은 흰색 테두리(Bounding Box) 또는 반투명 원형 표시.  
  * **Interaction:** 감지된 얼굴을 터치하면 마스킹 On/Off 전환 (본인 제외 기능).  
* **Style Toolbar (Bottom Tab):**  
  * **Presets:** Blurred Glass(기본), Pixel Art, Solid Clean. 각 스타일은 직관적인 아이콘으로 표시.  
* **Adjustment Layer:**  
  * 스타일 선택 시 하단에서 슬라이더 노출: 강도(Intensity) 및 범위(Size) 조절.  
  * 햅틱 피드백(Taptic Engine) 적용: 슬라이더 눈금 이동 시 미세한 진동.

### **\[Screen 3\] Export & Metadata Settings**

*최종 저장 전 옵션 설정 및 공유 화면*

* **Result Preview:** 마스킹이 완료된 최종 이미지 미리보기.  
* **Settings Toggle List (Cards):**  
  * 위치 정보 제거 (Remove Location): Default ON.  
  * 촬영 정보 제거 (Remove Exif): Default ON.  
  * 고해상도 유지 (Original Resolution): Default ON.  
* **Primary Actions:**  
  * 앨범에 저장 (Save to Photos): 성공 시 하단에 '저장 완료' Toast 메시지.  
  * 인스타그램 공유 (Share to Instagram): 공유 시트 호출.

## **3\. 사용자 흐름 (User Flow)**

1. **Entry:** 앱 실행 후 사진 선택 버튼 탭.  
2. **Detection:** 사진 로드 즉시 배경에서 Face Detection Service 실행. (로딩 시 부드러운 스켈레톤 애니메이션 노출)  
3. **Editing:** \- AI가 찾은 모든 얼굴에 기본 Blurred Glass 적용.  
   * 사용자가 특정 인물을 탭하여 마스킹 해제.  
   * 하단 스타일 탭에서 스타일 변경 및 슬라이더로 농도 조절.  
4. **Finalize:** Export 버튼 클릭 후 메타데이터 옵션 확인.  
5. **Completion:** 저장 및 공유 후 홈으로 복귀 또는 새로운 사진 작업.

## **4\. 기술적 UI 대응 (Clean Architecture 기반)**

* **State Management:** EditorViewModel에서 FaceBox 객체 배열을 관리.  
  * isMasked: Bool, rect: CGRect, style: MaskingStyle 상태를 기반으로 UI가 실시간 업데이트됨.  
* **Performance UX:** \- 고해상도 이미지 처리 시 메인 스레드 차단 방지를 위해 Thumbnail View에서 편집하고, 저장 시에만 원본 해상도에 마스킹을 렌더링.  
  * Vision API 호출 중에는 '인물 찾는 중...' 이라는 마이크로 인터랙션 제공.

## **5\. UI 가이드라인 (Design Mockup 이미지 묘사)**

* **Glassmorphism:** 하단 툴바에 배경이 살짝 비치는 블러 효과를 적용하여 현대적인 느낌 강조.  
* **Empty State:** 사진 접근 권한이 없을 때, 시스템 설정으로 유도하는 깔끔한 일러스트와 가이드 버튼 배치.  
* **Dark Mode:** 모든 배경은 순수 Black(000000)보다는 Deep Gray(1C1C1E)를 사용하여 눈의 피로도를 낮춤.