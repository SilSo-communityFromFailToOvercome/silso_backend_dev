import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChoosePetPage extends StatefulWidget {
  final String? currentPetId;
  
  const ChoosePetPage({super.key, this.currentPetId});

  @override
  State<ChoosePetPage> createState() => _ChoosePetPageState();
}

class _ChoosePetPageState extends State<ChoosePetPage> {
  String? selectedPetId;
  bool isLoading = false;
  
  // List of all available pets
  final List<String> availablePets = [
    'pet1', 'pet2', 'pet3', 'pet4', 'pet5', 'pet6',
    'pet7', 'pet8', 'pet9', 'pet10', 'pet11'
  ];

  @override
  void initState() {
    super.initState();
    selectedPetId = widget.currentPetId ?? 'pet5'; // Default to pet5
  }

  Future<void> _savePetSelection() async {
    if (selectedPetId == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save pet selection to user's profile in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'selectedPet': selectedPetId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (mounted) {
          // Return the selected pet ID to the previous screen
          Navigator.of(context).pop(selectedPetId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('펫 선택 저장에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF121212),
            size: 20 * widthRatio,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '펫 선택',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(16 * widthRatio),
              child: SizedBox(
                width: 20 * widthRatio,
                height: 20 * widthRatio,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: selectedPetId != null ? _savePetSelection : null,
              child: Text(
                '저장',
                style: TextStyle(
                  fontSize: 16 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: selectedPetId != null 
                      ? const Color(0xFF5F37CF) 
                      : const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20 * heightRatio),
              
              // Instructions
              Text(
                '나만의 펫을 선택해주세요',
                style: TextStyle(
                  fontSize: 20 * widthRatio,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 8 * heightRatio),
              
              Text(
                '선택한 펫이 프로필 화면에 표시됩니다',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 30 * heightRatio),
              
              // Pet Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16 * widthRatio,
                  mainAxisSpacing: 16 * heightRatio,
                  childAspectRatio: 1.0,
                ),
                itemCount: availablePets.length,
                itemBuilder: (context, index) {
                  final petId = availablePets[index];
                  final isSelected = selectedPetId == petId;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPetId = petId;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16 * widthRatio),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF5F37CF) 
                              : const Color(0xFFE0E0E0),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Pet Image
                          Center(
                            child: Image.asset(
                              'images/pets/$petId.png',
                              width: 80 * widthRatio,
                              height: 80 * widthRatio,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80 * widthRatio,
                                  height: 80 * widthRatio,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8E3FF),
                                    borderRadius: BorderRadius.circular(40 * widthRatio),
                                  ),
                                  child: Icon(
                                    Icons.pets,
                                    size: 40 * widthRatio,
                                    color: const Color(0xFF5F37CF),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Selection Indicator
                          if (isSelected)
                            Positioned(
                              top: 8 * widthRatio,
                              right: 8 * widthRatio,
                              child: Container(
                                width: 24 * widthRatio,
                                height: 24 * widthRatio,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5F37CF),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16 * widthRatio,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40 * heightRatio),
            ],
          ),
        ),
      ),
    );
  }
}