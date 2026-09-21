import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/provider/controllers/verification_controller.dart';
import 'package:skilllink_mobile/features/provider/models/verification_document_model.dart';
import 'package:skilllink_mobile/features/provider/services/verification_service.dart';

Map<String, dynamic> _payload(String status, {Map<String, dynamic>? request, bool canSubmit = false}) => {
      'verification_status': status,
      'verified_at': null,
      'can_submit': canSubmit,
      'request': request,
    };

class _FakeService extends VerificationService {
  ProviderVerification state = ProviderVerification.fromJson(_payload('unverified', canSubmit: true));
  List<PendingVerificationDocument>? sent;
  bool fail = false;

  @override
  Future<ProviderVerification> get() async => state;

  @override
  Future<ProviderVerification> submit(List<PendingVerificationDocument> documents,
      {String? notes, void Function(double progress)? onProgress}) async {
    if (fail) throw Exception('offline');
    sent = documents;
    onProgress?.call(1);
    return state = ProviderVerification.fromJson(_payload('pending', request: {
      'id': 7,
      'status': 'pending',
      'documents': [
        for (var i = 0; i < documents.length; i++)
          {'id': i + 1, 'document_type': documents[i].type, 'file_name': documents[i].fileName},
      ],
    }));
  }
}

PendingVerificationDocument _doc(String name, {int size = 10}) =>
    PendingVerificationDocument(type: 'government_id', fileName: name, bytes: Uint8List(size));

void main() {
  group('ProviderVerification.fromJson', () {
    test('reads the status, the reviewer message and the documents without storage paths', () {
      final verification = ProviderVerification.fromJson(_payload('additional_info_required', canSubmit: true, request: {
        'id': 3,
        'status': 'additional_info_required',
        'additional_info_request': 'Please add the back of your ID.',
        'submitted_at': '2026-09-20T02:00:00+00:00',
        'documents': [
          {'id': 1, 'document_type': 'government_id', 'file_name': 'id.jpg', 'file_mime_type': 'image/jpeg', 'file_size': 1024},
        ],
      }));

      expect(verification.needsMoreInfo, isTrue);
      expect(verification.canSubmit, isTrue);
      expect(verification.request!.additionalInfoRequest, 'Please add the back of your ID.');
      expect(verification.request!.documents.single.typeLabel, 'Government-issued ID');
      expect(verification.request!.documents.single.isPdf, isFalse);
    });
  });

  group('VerificationController', () {
    test('refuses files the API would refuse, before uploading', () {
      final controller = VerificationController(service: _FakeService());

      expect(controller.add(_doc('notes.txt')), 'Choose a JPG, PNG or PDF file.');
      expect(controller.add(_doc('huge.pdf', size: PendingVerificationDocument.maxBytes + 1)), 'That file is larger than 10 MB.');
      for (var i = 0; i < VerificationController.maxPerSubmission; i++) {
        expect(controller.add(_doc('id$i.jpg')), isNull);
      }
      expect(controller.add(_doc('extra.jpg')), contains('up to 5'));
    });

    test('submits the picked files with their types and shows the new status', () async {
      final service = _FakeService();
      final controller = VerificationController(service: service);
      await controller.load();
      controller.add(_doc('id.jpg'));
      controller.add(_doc('tesda.pdf'));
      controller.setType(1, 'certificate');

      expect(await controller.submit(notes: 'NC II'), isTrue);
      expect(service.sent!.map((d) => d.type), ['government_id', 'certificate']);
      expect(controller.picked, isEmpty);
      expect(controller.verification!.isPending, isTrue);
      expect(controller.verification!.canSubmit, isFalse);
      expect(controller.verification!.request!.documents, hasLength(2));
    });

    test('a failed upload keeps the files so the provider can retry', () async {
      final service = _FakeService()..fail = true;
      final controller = VerificationController(service: service);
      controller.add(_doc('id.jpg'));

      expect(await controller.submit(), isFalse);
      expect(controller.picked, hasLength(1));
      expect(controller.errorMessage, isNotNull);
      expect(controller.isSubmitting, isFalse);
    });
  });
}
