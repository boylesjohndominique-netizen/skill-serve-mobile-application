import 'package:dio/dio.dart';

import '../../auth/models/user_model.dart';
import '../../../core/services/api_client.dart';

/// Service for the signed-in account's own profile.
///
/// Endpoints:
/// - GET    /api/client/v1/auth/me
/// - PATCH  /api/client/v1/auth/me
/// - POST   /api/client/v1/auth/me/photo
/// - DELETE /api/client/v1/auth/me/photo
/// - POST   /api/client/v1/auth/change-password
class ProfileService {
  // GET /api/client/v1/auth/me
  Future<UserModel> getProfile(UserModel current) async {
    final response = await ApiClient.instance.dio.get('/client/v1/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Saves the editable profile fields and, when the photo changed, the
  /// photo as well.
  ///
  /// The photo is a separate multipart endpoint, so it is only called when
  /// there is something to do: [profilePicture] holds a newly picked local
  /// file, and [clearProfilePicture] removes the stored one. The user from
  /// the last successful call is returned, so the caller always gets the
  /// freshest state.
  Future<UserModel> updateProfile(
    UserModel current, {
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? profilePicture,
    bool clearProfilePicture = false,
  }) async {
    final response =
        await ApiClient.instance.dio.patch('/client/v1/auth/me', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
    var user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);

    if (clearProfilePicture) {
      user = await removePhoto();
    } else if (profilePicture != null && _isLocalFile(profilePicture)) {
      user = await uploadPhoto(profilePicture);
    }

    return user;
  }

  // POST /api/client/v1/auth/me/photo
  Future<UserModel> uploadPhoto(String filePath) async {
    final path = filePath.replaceFirst('file://', '');
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        path,
        filename: _basename(path),
        contentType: _mediaTypeFor(path),
      ),
    });

    final response =
        await ApiClient.instance.dio.post('/client/v1/auth/me/photo', data: form);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // DELETE /api/client/v1/auth/me/photo
  Future<UserModel> removePhoto() async {
    final response =
        await ApiClient.instance.dio.delete('/client/v1/auth/me/photo');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // POST /api/client/v1/auth/change-password
  Future<void> changePassword(
      {required String current, required String next}) async {
    await ApiClient.instance.dio
        .post('/client/v1/auth/change-password', data: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }

  /// A value from the image picker is a device path; anything already saved
  /// comes back from the API as an https URL and needs no re-upload.
  bool _isLocalFile(String value) =>
      !value.startsWith('http://') && !value.startsWith('https://');

  String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  /// The API only accepts JPG, PNG and WebP, so the part is labelled from
  /// the file's own extension rather than sent as octet-stream — which the
  /// server would reject as a non-image.
  DioMediaType _mediaTypeFor(String path) {
    final name = _basename(path).toLowerCase();
    if (name.endsWith('.png')) return DioMediaType('image', 'png');
    if (name.endsWith('.webp')) return DioMediaType('image', 'webp');
    return DioMediaType('image', 'jpeg');
  }
}
