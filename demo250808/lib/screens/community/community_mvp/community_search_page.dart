import 'package:flutter/material.dart';

class ExploreSearchPage extends StatefulWidget {
  const ExploreSearchPage({super.key});

  @override
  State<ExploreSearchPage> createState() => _ExploreSearchPageState();
}

class _ExploreSearchPageState extends State<ExploreSearchPage> {
  List<String> _recentKeywords = [
    '멘탈케어',
    '인간관계',
    '취직',
    '자존감',
  ];

  final List<String> _popularKeywordsLeft = [
    '1   연애', '2   인간관계', '3   회사에서 상사랑', '4   사업실패', '5   취업 준비',
  ];

  final List<String> _popularKeywordsRight = [
    '6   사랑', '7   건강하게', '8   회사일', '9   연인관계', '10  퇴사관련',
  ];

  @override
  Widget build(BuildContext context) {
    // 1. 현재 화면 사이즈 가져오기
    final screenSize = MediaQuery.of(context).size;
    
    // 2. 디자인 시안(393x852) 기준 비율 계산
    final widthRatio = screenSize.width / 393;
    final heightRatio = screenSize.height / 852;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildSearchAppBar(widthRatio),
      body: SingleChildScrollView(
        child: Padding(
          // 수평 패딩을 화면 비율에 맞게 조정
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 28 * heightRatio),
              _buildRecentSearches(widthRatio, heightRatio),
              SizedBox(height: 32 * heightRatio),
              _buildPopularSearches(widthRatio, heightRatio),
              SizedBox(height: 32 * heightRatio),
              _buildAdSection(widthRatio, heightRatio),
              SizedBox(height: 40 * heightRatio),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(double widthRatio) {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFA),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 24 * widthRatio),
      title: TextField(
        style: TextStyle(fontSize: 16 * widthRatio), // 폰트 크기도 비율 적용
        decoration: InputDecoration(
          hintText: '관심있는 키워드를 입력해주세요.',
          hintStyle: TextStyle(
            color: const Color(0xFFC7C7C7),
            fontSize: 16 * widthRatio, // 폰트 크기도 비율 적용
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: const Color(0xFFC7C7C7), size: 24 * widthRatio),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(double widthRatio, double heightRatio) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 검색어',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _recentKeywords.clear()),
              child: Text(
                '전체 삭제',
                style: TextStyle(
                  color: const Color(0xFF595959),
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * heightRatio),
        Wrap(
          spacing: 8.0 * widthRatio,
          runSpacing: 8.0 * heightRatio,
          children: _recentKeywords.map((keyword) {
            return Chip(
              label: Text(
                keyword,
                style: TextStyle(
                  color: const Color(0xFFFAFAFA),
                  fontSize: 13.37 * widthRatio,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: const Color(0xFF5F37CF).withOpacity(0.3),
              onDeleted: () => setState(() => _recentKeywords.remove(keyword)),
              deleteIconColor: const Color(0xFFFAFAFA),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFA5A5A5), width: 1.34),
                borderRadius: BorderRadius.circular(13.37 * widthRatio),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * widthRatio,
                vertical: 6 * heightRatio,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularSearches(double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '인기 검색어',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                '접기',
                style: TextStyle(
                  color: const Color(0xFFBBBBBB),
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * heightRatio),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: 12.0 * heightRatio,
            horizontal: 16.0 * widthRatio,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6 * widthRatio),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildPopularKeywordColumn(_popularKeywordsLeft, widthRatio)),
                SizedBox(width: 16 * widthRatio),
                const VerticalDivider(color: Color(0xFFF4F4F4), thickness: 1),
                SizedBox(width: 16 * widthRatio),
                Expanded(child: _buildPopularKeywordColumn(_popularKeywordsRight, widthRatio)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPopularKeywordColumn(List<String> keywords, double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keywords.map((keyword) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          child: Text(
            keyword,
            style: TextStyle(
              color: const Color(0xFF121212),
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdSection(double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '광고',
          style: TextStyle(
            color: const Color(0xFF606060),
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 8 * heightRatio),
        Container(
          height: 105 * heightRatio,
          decoration: BoxDecoration(
            color: const Color(0xFFE9E9E9),
            borderRadius: BorderRadius.circular(6 * widthRatio),
          ),
          child: const Center(child: Text("Ad Banner 1")),
        ),
        SizedBox(height: 16 * heightRatio),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 105 * heightRatio,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(6 * widthRatio),
                ),
                child: const Center(child: Text("Ad Banner 2")),
              ),
            ),
            SizedBox(width: 12 * widthRatio),
            Expanded(
              child: Container(
                height: 105 * heightRatio,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(4 * widthRatio),
                ),
                child: const Center(child: Text("Ad Banner 3")),
              ),
            ),
          ],
        )
      ],
    );
  }
}
