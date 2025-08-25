import 'package:flutter/material.dart';

// 이동할 더미 페이지
class MyPetSelect extends StatelessWidget {
  const MyPetSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다음 페이지'),
      ),
      body: const Center(
        child: Text(
          '이것은 다음 페이지입니다!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// 기존 디자인 UI 위젯
class NameInputPage extends StatelessWidget {
  const NameInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 393,
          height: 852,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.06, 0.01),
              end: Alignment(0.95, 1.00),
              colors: [Color(0xFF5F37CF), Color(0xFF160C32)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 142,
                top: 237,
                child: Container(
                  width: 110,
                  height: 288,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/110x288"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 85,
                top: 595,
                child: Container(
                  width: 224,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF7F4FF),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF5F37CF),
                      ),
                      borderRadius: BorderRadius.circular(400),
                    ),
                  ),
                  child: const Stack(
                    children: [
                      Positioned(
                        left: 47,
                        top: 9,
                        child: Text(
                          '이름을 입력해주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD0C5ED),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            height: 1.39,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 107,
                top: 155,
                child: Text(
                  '이름을 지어주세요!',
                  style: TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 20,
                    fontFamily: 'DungGeunMo',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 707,
                child: GestureDetector(
                  onTap: () {
                    // 완료 버튼 클릭 시 MyPetSelect로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPetSelect(),
                      ),
                    );
                  },
                  child: Container(
                    width: 393,
                    height: 145,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 18,
                          top: 25,
                          child: Container(
                            width: 360,
                            height: 52,
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF44307A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Stack(
                              children: [
                                Positioned(
                                  left: 163,
                                  top: 14,
                                  child: Text(
                                    '완료',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF896ADD),
                                      fontSize: 18,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      height: 1.23,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}