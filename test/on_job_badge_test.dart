import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/widgets/misc/on_job_badge.dart';
import 'package:skillserve_mobile/features/marketplace/models/provider_model.dart';

Map<String, dynamic> _provider([Map<String, dynamic> overrides = const {}]) => {
      'id': 3,
      'display_name': 'Juan Aircon Services',
      'verification_status': 'verified',
      ...overrides,
    };

void main() {
  test("a provider's job in progress is read from the API, off when absent", () {
    expect(ProviderModel.fromJson(_provider({'on_job_now': true})).onJobNow, isTrue);
    expect(ProviderModel.fromJson(_provider({'on_job_now': false})).onJobNow, isFalse);
    expect(ProviderModel.fromJson(_provider()).onJobNow, isFalse);
  });

  testWidgets('the badge says the provider is on a job, and that booking still works', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [OnJobBadge(), OnJobBadge(long: true)]))));

    expect(find.text('On a job now'), findsOneWidget);
    expect(find.text('On a job right now — you can still book or message'), findsOneWidget);
  });
}
