import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:messaging/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  File? _selectedImage;
  String? _verificationId;
  bool _isVerifying = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
}

  void _verifyPhone() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      await _firebase.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebase.signInWithCredential(credential);
          _uploadUserData();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification failed: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isVerifying = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isVerifying = false;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending OTP: ${e.toString()}")));
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: _otpController.text);

      await _firebase.signInWithCredential(credential);
      _uploadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error verifying OTP: ${e.toString()}")));
    }
  }

  void _uploadUserData() async {
    final user = _firebase.currentUser;
    if (user != null && _selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phoneNumber': user.phoneNumber,
        'image_url': imageUrl
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserImagePicker(
                      onPickImage: (pickedImage) {
                        _selectedImage = pickedImage;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    if (_verificationId != null)
                      TextFormField(
                        controller: _otpController,
                        decoration: const InputDecoration(labelText: 'OTP'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 12),
                    if (_isVerifying)
                      const CircularProgressIndicator()
                    else if (_verificationId == null)
                      ElevatedButton(
                        onPressed: _verifyPhone,
                        child: const Text('Send OTP'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _verifyOTP,
                        child: const Text('Verify OTP'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}