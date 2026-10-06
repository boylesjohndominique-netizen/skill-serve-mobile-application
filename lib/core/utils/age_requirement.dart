/// SkillServe is for adults: customers and providers must be at least
/// [minimumAge], and a provider's years of experience are counted from
/// [workStartAge] at the earliest — 2 years at 18, 3 at 19, 4 at 20, and so
/// on. Mirrors the API's `AgeRequirement`, which has the final say.
class AgeRequirement {
  AgeRequirement._();

  static const minimumAge = 18;
  static const workStartAge = 16;

  /// The cap when no birthday is known (accounts made before birthdays were
  /// collected).
  static const maxExperience = 80;

  static const tooYoungMessage = 'You must be at least $minimumAge years old to use SkillServe.';

  /// Full years between [birthdate] and [today].
  static int ageOn(DateTime birthdate, [DateTime? today]) {
    final now = today ?? DateTime.now();
    var age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) age--;
    return age;
  }

  /// The latest birthday that is old enough today.
  static DateTime latestBirthday([DateTime? today]) {
    final now = today ?? DateTime.now();
    return DateTime(now.year - minimumAge, now.month, now.day);
  }

  static bool isOldEnough(DateTime birthdate) => ageOn(birthdate) >= minimumAge;

  static int maxExperienceYears(DateTime? birthdate) {
    if (birthdate == null) return maxExperience;
    return (ageOn(birthdate) - workStartAge).clamp(0, maxExperience);
  }
}
