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
  int selectedOutfit = 0; // 0 means default (no outfit)
  bool isLoading = false;
  
  // List of all available pets (now using silpets)
  final List<int> availablePets = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  
  // List of available outfits (based on silpets outfit folder)
  final List<int> availableOutfits = [0, 1, 2, 3, 4, 5, 6]; // 0 = default, 1-6 = outfits

  @override
  void initState() {
    super.initState();
    _initializePetSelection();
  }

  void _initializePetSelection() {
    if (widget.currentPetId != null) {
      // Parse current pet ID to extract pet and outfit
      final parts = widget.currentPetId!.split('.');
      if (parts.length == 2) {
        selectedPetId = parts[0]; // e.g., "5"
        selectedOutfit = int.tryParse(parts[1]) ?? 0; // e.g., "4" -> 4
      } else {
        // Handle legacy format (e.g., "pet5")
        final petNumber = widget.currentPetId!.replaceAll('pet', '');
        selectedPetId = petNumber.isNotEmpty ? petNumber : '5';
        selectedOutfit = 0;
      }
    } else {
      selectedPetId = '5'; // Default to silpet 5
      selectedOutfit = 0;
    }
  }

  Future<void> _savePetSelection() async {
    if (selectedPetId == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create the combined pet ID (e.g., "5.0" or "5.4")
        final combinedPetId = '$selectedPetId.$selectedOutfit';
        
        // Save pet selection to user's profile in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'selectedPet': combinedPetId,
          'selectedPetNumber': int.parse(selectedPetId!), // Store pet number separately
          'selectedOutfit': selectedOutfit, // Store outfit separately
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (mounted) {
          // Return the combined pet ID to the previous screen
          Navigator.of(context).pop(combinedPetId);
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

  String _buildPetImagePath(String petNumber, int outfitNumber) {
    final folderName = _getPetFolderName(petNumber);
    return 'images/silpets/$folderName/$petNumber.$outfitNumber.png';
  }

  String _getPetFolderName(String petNumber) {
    switch (petNumber) {
      case '1':
        return '1_red';
      case '2':
        return '2_blue';
      case '3':
        return '3_green';
      case '4':
        return '4_cyan';
      case '5':
        return '5_yellow';
      case '6':
        return '6_green';
      case '7':
        return '7_pink';
      case '8':
        return '8_orange';
      case '9':
        return '9_grey';
      case '10':
        return '10_purple';
      case '11':
        return '11_purplish';
      default:
        return '5_yellow';
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
                  final petNumber = availablePets[index];
                  final isSelected = selectedPetId == petNumber.toString();
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPetId = petNumber.toString();
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
                              _buildPetImagePath(petNumber.toString(), selectedOutfit),
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
              
              // Outfit Selection Section
              if (selectedPetId != null) ...[
                Text(
                  '의상 선택',
                  style: TextStyle(
                    fontSize: 18 * widthRatio,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121212),
                    fontFamily: 'Pretendard',
                  ),
                ),
                
                SizedBox(height: 8 * heightRatio),
                
                Text(
                  '선택한 펫에 입힐 의상을 고르세요',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                
                SizedBox(height: 20 * heightRatio),
                
                // Outfit Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12 * widthRatio,
                    mainAxisSpacing: 12 * heightRatio,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: availableOutfits.length,
                  itemBuilder: (context, index) {
                    final outfitNumber = availableOutfits[index];
                    final isSelected = selectedOutfit == outfitNumber;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOutfit = outfitNumber;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * widthRatio),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF5F37CF) 
                                : const Color(0xFFE0E0E0),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Outfit Image
                            Center(
                              child: outfitNumber == 0
                                  ? Container(
                                      width: 50 * widthRatio,
                                      height: 50 * widthRatio,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(25 * widthRatio),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: const Color(0xFF8E8E8E),
                                        size: 20 * widthRatio,
                                      ),
                                    )
                                  : Image.asset(
                                      'images/silpets_outfit/$outfitNumber.png',
                                      width: 50 * widthRatio,
                                      height: 50 * widthRatio,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50 * widthRatio,
                                          height: 50 * widthRatio,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8E3FF),
                                            borderRadius: BorderRadius.circular(25 * widthRatio),
                                          ),
                                          child: Icon(
                                            Icons.style,
                                            size: 25 * widthRatio,
                                            color: const Color(0xFF5F37CF),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            
                            // Selection Indicator
                            if (isSelected)
                              Positioned(
                                top: 4 * widthRatio,
                                right: 4 * widthRatio,
                                child: Container(
                                  width: 18 * widthRatio,
                                  height: 18 * widthRatio,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5F37CF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12 * widthRatio,
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
            ],
          ),
        ),
      ),
    );
  }
}