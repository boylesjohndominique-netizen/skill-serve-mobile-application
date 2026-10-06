import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/core/utils/age_requirement.dart';

void main() {
  final today = DateTime(2026, 10, 6);

  test('age counts full years only', () {
    expect(AgeRequirement.ageOn(DateTime(2008, 10, 6), today), 18);
    expect(AgeRequirement.ageOn(DateTime(2008, 10, 7), today), 17);
  });

  test('the latest birthday allowed is exactly 18 years ago', () {
    expect(AgeRequirement.latestBirthday(today), DateTime(2008, 10, 6));
  });

  test('experience is capped at the age minus 16', () {
    final now = DateTime.now();
    DateTime bornYearsAgo(int years) => DateTime(now.year - years, now.month, now.day);

    expect(AgeRequirement.maxExperienceYears(bornYearsAgo(18)), 2);
    expect(AgeRequirement.maxExperienceYears(bornYearsAgo(19)), 3);
    expect(AgeRequirement.maxExperienceYears(bornYearsAgo(20)), 4);
    expect(AgeRequirement.maxExperienceYears(null), AgeRequirement.maxExperience);
  });
}
