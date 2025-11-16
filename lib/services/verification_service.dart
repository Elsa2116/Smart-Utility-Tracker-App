import 'dart:io';

class VerificationService {
  // Mock function for demo, replace with real verification
  static Future<bool> verifyIdAndFace(File idPhoto) async {
    // TODO: call ML model or backend API here
    await Future.delayed(const Duration(seconds: 1));
    return true; // return true if verified
  }
}
