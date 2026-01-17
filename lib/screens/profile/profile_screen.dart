import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../services/biometric_service.dart';
import '../../config/theme.dart';
import '../../config/config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AppProvider>().currentUser;
    _displayNameController = TextEditingController(text: currentUser?.displayName ?? '');
    _bioController = TextEditingController(text: currentUser?.bio ?? '');
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final biometrics = await _biometricService.getAvailableBiometrics();
    
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _biometricType = _biometricService.getBiometricTypeDisplay(biometrics);
      });
    }
  }

  void _showScreenshotAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text('Screenshot Detected!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'A screenshot of your profile was just taken.\n\nYour privacy matters. Please be cautious about sharing personal information.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Verify your identity to enable $_biometricType authentication',
      );
      
      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() {
          _isBiometricEnabled = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_biometricType authentication enabled')),
          );
        }
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      setState(() {
        _isBiometricEnabled = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_biometricType authentication disabled')),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('🔧 ProfileScreen._pickImage() - Picked file: ${pickedFile.path}');
        print('🔧 ProfileScreen._pickImage() - File name: ${pickedFile.name}');
        print('🔧 ProfileScreen._pickImage() - File mimeType: ${pickedFile.mimeType}');
        
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        
        // Auto-upload the image
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    final appProvider = context.read<AppProvider>();
    final result = await appProvider.userService.uploadProfilePicture(_selectedImage!);

    if (mounted) {
      setState(() {
        _isUploadingImage = false;
      });

      if (result['success']) {
        print('🔧 ProfileScreen._uploadProfilePicture() - Upload success! Result: $result');
        final newUser = result['user'] as UserModel;
        print('🔧 ProfileScreen._uploadProfilePicture() - New user profilePicture: ${newUser.profilePicture}');
        
        // Clear old image from cache if it exists
        if (appProvider.currentUser?.profilePicture != null) {
          print('🔧 ProfileScreen._uploadProfilePicture() - Evicting old cache: ${appProvider.currentUser!.profilePicture}');
          await CachedNetworkImage.evictFromCache(
            '${Config.baseUrl}${appProvider.currentUser!.profilePicture}',
          );
        }
        
        // Update the current user in AuthService
        print('🔧 ProfileScreen._uploadProfilePicture() - Calling updateCurrentUser');
        await appProvider.authService.updateCurrentUser(result['user']);
        
        // Notify listeners to refresh UI
        print('🔧 ProfileScreen._uploadProfilePicture() - Notifying listeners');
        appProvider.notifyListeners();
        
        // Clear selected image and rebuild
        setState(() {
          _selectedImage = null;
        });
        print('🔧 ProfileScreen._uploadProfilePicture() - State cleared, currentUser.profilePicture: ${appProvider.currentUser?.profilePicture}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to upload picture')),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    final appProvider = context.read<AppProvider>();
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await appProvider.userService.deleteProfilePicture();

      if (mounted) {
        if (result['success']) {
          // Clear image from cache
          if (appProvider.currentUser?.profilePicture != null) {
            await CachedNetworkImage.evictFromCache(
              '${Config.baseUrl}${appProvider.currentUser!.profilePicture}',
            );
          }
          
          // Update the current user in AuthService
          await appProvider.authService.updateCurrentUser(result['user']);
          
          // Notify listeners to refresh UI
          appProvider.notifyListeners();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture removed')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to delete picture')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final appProvider = context.read<AppProvider>();
    final result = await appProvider.userService.updateProfile(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (result['success'] && mounted) {
      // Update the current user in AuthService
      await appProvider.authService.updateCurrentUser(result['user']);
      
      setState(() {
        _isEditing = false;
      });
      
      // Notify listeners to refresh UI
      appProvider.notifyListeners();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentUser = appProvider.currentUser;
    print('🔧 ProfileScreen.build() - currentUser: ${currentUser?.displayName}, profilePicture: ${currentUser?.profilePicture}');

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile picture
              Stack(
                key: ValueKey(currentUser.profilePicture),
                children: [
                  currentUser.profilePicture != null && _selectedImage == null
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: '${Config.baseUrl}${currentUser.profilePicture}',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Text(
                                currentUser.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null && currentUser.profilePicture == null
                              ? Text(
                                  currentUser.displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                )
                              : null,
                        ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.accentColor,
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                color: Colors.white,
                                onPressed: _pickImage,
                              ),
                      ),
                    ),
                  if (currentUser.profilePicture != null && _isEditing)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.white,
                          onPressed: _deleteProfilePicture,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Display name
              TextFormField(
                controller: _displayNameController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'Minimum 3 characters',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Display name must be at least 3 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Display name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                enabled: _isEditing,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              // Biometric Authentication Toggle
              if (_isBiometricAvailable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            color: AppTheme.accentColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_biometricType Authentication',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unlock app with $_biometricType',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isBiometricEnabled,
                            onChanged: _toggleBiometric,
                            activeColor: AppTheme.accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_isBiometricAvailable)
                const SizedBox(height: 24),
              // Privacy notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Privacy Information',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Your email is never shown to other users\n'
                      '• Messages auto-delete after ${Config.messageExpiryHours} hours\n'
                      '• No online status or last seen\n'
                      '• No read receipts or typing indicators\n'
                      '• Screenshot detection enabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // User ID (for debugging)
              const SizedBox(height: 16),
              Text(
                'User ID: ${currentUser.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
