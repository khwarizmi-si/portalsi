import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/secure_storage.dart'; // Import file SecureStorage
import 'dashboard_page.dart'; // Import HomePage

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedMedia;
  bool _isVideo = false;
  bool _isLoading = false;
  int _userId = 0;
  String _token = '';

  // Color Palette
  static const Color peachSoft = Color(0xFFFFF0D0);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color mintFresh = Color(0xFFDFFEF8);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightGray = Color(0xFFECF0F1);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await SecureStorage.getUserId();
      final token = await SecureStorage.getToken();

      setState(() {
        _userId = userId!;
        _token = token ?? '';
      });
    } catch (e) {
      print('Error loading user data: $e');
      // Handle error, maybe redirect to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [peachSoft, pureWhite, mintFresh],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: pureWhite.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: lightGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: darkText),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Create New Post',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [accentBlue, Color(0xFF5BA0F2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: _isLoading ? null : _sharePost,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _isLoading ? 'Sharing...' : 'Share',
                          style: const TextStyle(
                            color: pureWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Media Selection Card
                        Container(
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 320,
                              width: double.infinity,
                              child: _selectedMedia != null
                                  ? Stack(
                                      children: [
                                        _isVideo
                                            ? Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      darkText,
                                                      Colors.black87,
                                                    ],
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.play_circle_outline,
                                                    size: 80,
                                                    color: pureWhite,
                                                  ),
                                                ),
                                              )
                                            : Image.file(
                                                _selectedMedia!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                        Positioned(
                                          top: 15,
                                          right: 15,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: pureWhite,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMedia = null;
                                                  _isVideo = false;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: _showMediaOptions,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              peachSoft.withOpacity(0.3),
                                              mintFresh.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: pureWhite,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 60,
                                                color: accentBlue,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              'Tap to add photo or video',
                                              style: TextStyle(
                                                color: darkText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Post Details Card
                        Container(
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Info
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [peachSoft, mintFresh],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.transparent,
                                        child: Icon(
                                          Icons.person,
                                          color: darkText,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userId > 0
                                              ? 'User $_userId'
                                              : 'Loading...',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: darkText,
                                          ),
                                        ),
                                        Text(
                                          'Creating a new post',
                                          style: TextStyle(
                                            color: darkText.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 25),

                                // Caption Input
                                Container(
                                  decoration: BoxDecoration(
                                    color: lightGray.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    controller: _captionController,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText: 'Write a caption...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(15),
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: darkText,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Location Input
                                GestureDetector(
                                  onTap: _showLocationDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: lightGray.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: accentBlue,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _locationController.text.isEmpty
                                                ? 'Add location'
                                                : _locationController.text,
                                            style: TextStyle(
                                              color: _locationController
                                                      .text.isEmpty
                                                  ? Colors.grey
                                                  : darkText,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (_locationController.text.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _locationController.clear();
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Additional Options
                                _buildOptionRow(
                                  Icons.people_outline,
                                  'Tag people',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Tag people feature coming soon',
                                        ),
                                        backgroundColor: accentBlue,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                _buildOptionRow(
                                  Icons.facebook,
                                  'Share to Facebook',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Facebook sharing feature coming soon',
                                        ),
                                        backgroundColor: accentBlue,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                _buildOptionRow(
                                  Icons.share,
                                  'Share to other apps',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Other app sharing feature coming soon',
                                        ),
                                        backgroundColor: accentBlue,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
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

  Widget _buildOptionRow(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            color: lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentBlue),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkText.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: pureWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMediaOption(
                    Icons.photo_library,
                    'Choose from Gallery',
                    () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.gallery);
                    },
                  ),
                  _buildMediaOption(Icons.camera_alt, 'Take Photo', () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.camera);
                  }),
                  _buildMediaOption(Icons.videocam, 'Record Video', () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  }),
                  _buildMediaOption(
                    Icons.video_library,
                    'Choose Video from Gallery',
                    () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentBlue),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedMedia = File(image.path);
          _isVideo = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);
      if (video != null) {
        setState(() {
          _selectedMedia = File(video.path);
          _isVideo = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking video: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController locationController = TextEditingController(
          text: _locationController.text,
        );

        return AlertDialog(
          backgroundColor: pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Location',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w700),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: locationController,
              decoration: const InputDecoration(
                hintText: 'Enter location...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(15),
              ),
              style: const TextStyle(color: darkText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: darkText.withOpacity(0.6)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentBlue, Color(0xFF5BA0F2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _locationController.text = locationController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add', style: TextStyle(color: pureWhite)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Salin dan ganti seluruh fungsi _sharePost di file create_post_page.dart

  Future<void> _sharePost() async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a photo or video'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_userId == 0 || _token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api-new.portalsi.com/api/posts'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';

      // Tambahkan data field
      request.fields['user_id'] = _userId.toString();
      request.fields['caption'] = _captionController.text;
      request.fields['location'] = _locationController.text;
      request.fields['is_archived'] = '0'; // Sesuai contoh pada Postman

      // --- [PERUBAHAN UTAMA DI SINI] ---
      // Tambahkan field 'is_video' jika media yang diupload adalah video
      if (_isVideo) {
        request.fields['is_video'] = '1';
      }
      // --- [AKHIR DARI PERUBAHAN] ---

      // Tambahkan file media
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          _selectedMedia!.path,
          filename: path.basename(_selectedMedia!.path),
        ),
      );

      // Kirim request
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post shared successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
              (route) => false,
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Error body: $responseBody');
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing post: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
