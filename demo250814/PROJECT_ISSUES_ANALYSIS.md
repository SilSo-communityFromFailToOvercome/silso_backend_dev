# 프로젝트 문제점 및 개발 요구사항 분석 보고서

## 개요
Flutter 앱의 현재 상태를 분석하고 Frontend/Backend 문제점을 정리하여 개발 우선순위를 제시합니다.

---

## 📱 Frontend 문제점

### 1. 전화번호 로그인 버튼 상호작용 문제
**파일**: `lib/screens/login_screen.dart`

#### 현재 상태:
- 카카오, 구글, 애플, 전화번호 로그인 버튼이 모두 독립적으로 작동
- 다른 버튼 클릭 시 '전화번호' 버튼 비활성화 부자연스러움
- `_isLoading` 상태가 모든 버튼에 공통으로 적용되어 일부만 비활성화 불가

#### 문제점:
```dart
// 현재 코드 (210번째 줄)
onPressed: _isLoading ? null : () {}, // 전화번호 로그인 로직으로 연결 필요

// 문제: 다른 로그인 진행 중에도 전화번호 버튼 활성화됨
```

#### 해결 방안:
- 개별 버튼별 로딩 상태 관리 (`_kakaoLoading`, `_googleLoading`, `_phoneLoading`)
- 버튼 클릭 시 다른 버튼들 비활성화 로직 추가

### 2. 전화번호 로그인 미구현
**파일**: `lib/screens/login_screen.dart` (210줄)

#### 현재 상태:
```dart
onPressed: _isLoading ? null : () {}, // 전화번호 로그인 로직으로 연결 필요
```

#### 필요 구현사항:
- 전화번호 입력 화면 또는 모달 다이얼로그
- SMS 인증 기능
- Firebase Phone Authentication 연동
- 국가별 전화번호 형식 지원

### 3. 로그인 버튼 높이 불일치
**파일**: `lib/screens/login_screen.dart`

#### 현재 상태:
- 카카오/구글 버튼: 이미지 파일 사용 (높이 자동)
- 애플 버튼: `height: 52 * widthRatio` (268-294줄)
- 전화번호 버튼: `height: 52 * heightRatio` (208줄)

#### 문제점:
- `widthRatio`와 `heightRatio` 혼용으로 일관성 없음
- 이미지 버튼과 위젯 버튼 높이가 다름

#### 해결 방안:
- 모든 버튼을 동일한 높이 기준으로 통일 (52dp 권장)
- 이미지 버튼에도 Container로 높이 제한 적용

---

## 🔧 Backend 문제점

### 1. Kakao 인증 플랫폼 제한
**파일**: `lib/services/korean_auth_service.dart`

#### 현재 상태:
- Web 플랫폼만 지원 (JavaScript SDK 사용)
- Mobile 구현이 placeholder 상태

```dart
// 124-137줄: Mobile Kakao login 미구현
Future<String?> _signInWithKakaoMobile() async {
  if (kIsWeb) return null;
  
  try {
    print('🟡 Starting mobile Kakao login...');
    
    // This would use the kakao_flutter_sdk package
    // For now, we'll throw an error to indicate it needs implementation
    throw 'Mobile Kakao login implementation needed. Install Kakao Flutter SDK properly.';
    
  } catch (e) {
    print('❌ Mobile Kakao login error: $e');
    rethrow;
  }
}
```

#### Android Build 에러 원인:
- `pubspec.yaml`에 `kakao_flutter_sdk: ^1.9.5` 의존성은 있음
- 하지만 Android 네이티브 설정이 누락
- `android/app/src/main/AndroidManifest.xml`에 Kakao 앱키 설정 필요

### 2. Community Profile 페이지 네비게이션 오류
**파일**: `lib/screens/community/profile_information_screen.dart`

#### 현재 상태 (216-224줄):
```dart
if (mounted) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PhoneVerificationScreen(
        phoneNumber: _phoneController.text.trim(),
      ),
    ),
  );
}
```

#### 문제점:
- `PhoneVerificationScreen`으로 push하지만 뒤로가기 가능
- Community 가입 완료 후 적절한 페이지로 리다이렉션 누락
- Lock 문제: 사용자가 중간에 나가면 불완전한 상태로 남음

#### 해결 방안:
- `pushReplacement` 또는 `pushAndRemoveUntil` 사용
- 가입 완료 후 홈 화면 또는 커뮤니티 메인으로 리다이렉션
- 임시 저장 기능으로 중간 단계 데이터 보존

---

## 🧹 사용하지 않는 코드 정리

### 제거 대상 파일들:

1. **`lib/splash_screen.dart`** - 전체 파일이 주석 처리됨 (86줄 모두 주석)
2. **`lib/login_screen.dart`** - `lib/screens/login_screen.dart`와 중복
3. **`lib/welcome_screen.dart`** - 사용되지 않음 (main.dart에서 import하지 않음)
4. **`lib/auth/login_page.dart`** - 사용되지 않는 별도 로그인 페이지
5. **`lib/auth/signup_page.dart`** - 사용되지 않는 별도 회원가입 페이지
6. **`lib/home/` 폴더** - `lib/screens/home_screen.dart`로 대체됨
   - `lib/home/home_page.dart`
   - `lib/home/create_post_page.dart`
   - `lib/home/comment_section.dart`

### 최적화 필요 Import:

많은 파일에서 사용하지 않는 import가 존재:
- `package:flutter/services.dart` - 일부 파일에서 미사용
- 중복된 theme 관련 import들

---

## 🚀 추가 개발 요구사항

### 1. 높은 우선순위 (긴급)

#### A. 전화번호 인증 시스템 구현
**관련 파일**: `lib/screens/login_screen.dart`, Firebase Phone Auth
```dart
// 새로 구현 필요
class PhoneLoginDialog extends StatefulWidget {
  // SMS 인증 UI 및 로직
}
```

#### B. Android Kakao 로그인 설정
**관련 파일**: 
- `android/app/src/main/AndroidManifest.xml`
- `lib/services/korean_auth_service.dart`

```xml
<!-- AndroidManifest.xml에 추가 필요 -->
<meta-data
    android:name="com.kakao.sdk.AppKey"
    android:value="3c7a8b482a7de8109be0c367da2eb33a" />
```

#### C. 로그인 버튼 UI 통일
**관련 파일**: `lib/screens/login_screen.dart`
- 모든 버튼 높이 52dp로 통일
- 상호배타적 로딩 상태 구현

### 2. 중간 우선순위

#### A. 커뮤니티 가입 플로우 완성
**관련 파일**: `lib/screens/community/profile_information_screen.dart`
- 가입 완료 후 적절한 리다이렉션
- 임시 저장 기능 구현
- 진행 상황 복원 기능

#### B. 에러 처리 개선
**관련 파일**: `lib/services/auth_service.dart`, `lib/widgets/error_handler_widget.dart`
- 사용자 친화적 에러 메시지
- 재시도 메커니즘
- 오프라인 상태 처리

#### C. 반응형 디자인 최적화
**관련 파일**: `lib/utils/responsive_asset_manager.dart`
- 태블릿 지원
- 다양한 화면 비율 대응

### 3. 낮은 우선순위 (향후 개선)

#### A. 성능 최적화
- 이미지 캐싱
- lazy loading 구현
- 메모리 사용량 최적화

#### B. 접근성 개선
- VoiceOver/TalkBack 지원
- 고대비 모드 지원
- 키보드 네비게이션

#### C. 국제화
- 다국어 지원
- 지역별 전화번호 형식
- 시간대 처리

---

## 📋 작업 우선순위 요약

### 🔥 즉시 수정 필요 (1-2일)
1. Android Kakao 로그인 설정
2. 전화번호 로그인 구현
3. 로그인 버튼 높이 통일
4. 사용하지 않는 파일 정리

### ⚠️ 주요 개선 사항 (1주일)
1. 커뮤니티 가입 플로우 완성
2. 에러 처리 개선
3. 로그인 버튼 상호작용 개선

### 📈 향후 개선 사항 (2-4주)
1. 반응형 디자인 최적화
2. 성능 최적화
3. 접근성 및 국제화

---

## 🔧 권장 해결 순서

1. **코드 정리** → 사용하지 않는 파일 제거
2. **Android 설정** → Kakao 로그인 Android 지원
3. **UI 통일** → 로그인 버튼 높이 및 상호작용 개선
4. **전화번호 로그인** → Firebase Phone Auth 구현
5. **커뮤니티 플로우** → 가입 완료 로직 수정
6. **에러 처리** → 사용자 경험 개선

이 순서로 진행하면 가장 큰 사용자 체험 개선을 빠르게 달성할 수 있습니다.