/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:image_picker/image_picker.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';

/// Evidence photos: weighing tickets, POD captures, supplier documents.
///
/// The API stores URL-shaped strings (`photoUrl`, `fileUrl`) but cannot take
/// pictures — upload goes through the shared `v1/file/uploadImage` endpoint
/// (multipart field `fileName`, responds `{ path }`) and the returned path is
/// what gets attached. Picking lives here so no screen touches Dio or the
/// picker directly.
class JhatkaMedia {
  JhatkaMedia({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;
  final ImagePicker _picker = ImagePicker();

  /// Pick from the camera without uploading. Returns the local file path, or
  /// null when the user backs out.
  Future<String?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return photo?.path;
  }

  /// Upload a previously captured photo. Returns the stored path, or null on
  /// failure.
  Future<String?> uploadPhoto(String filePath) async {
    final String filename = filePath.split(RegExp(r'[/\\]')).last;
    final String resolvedName = filename.isEmpty
        ? 'evidence-${DateTime.now().millisecondsSinceEpoch}.jpg'
        : filename;
    final DioApiResponse response = await ApiRequestService.uploadFile(
      'v1/file/uploadImage',
      filePath: filePath,
      filename: resolvedName,
      token: await _authRepository.authToken(),
    );
    if (response.errorType != NetErrorType.none) return null;
    final Map<String, dynamic> body = decodeBody(response);
    final String? path = (body['path'] ?? body['fileUrl'])?.toString();
    return (path == null || path.isEmpty) ? null : path;
  }

  /// Pick from the camera and upload. Returns the stored path, or null when
  /// the user backs out or the upload fails. Callers show their own message.
  Future<String?> takeAndUploadPhoto() async {
    final String? path = await takePhoto();
    if (path == null) return null;
    return uploadPhoto(path);
  }
}
