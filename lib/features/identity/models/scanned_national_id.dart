/// What was read off a Philippine National ID (the plastic PhilSys card or
/// the printed ePhilID) at sign-up: the text on the front and the QR code on
/// the back.
///
/// Everything is optional: a camera misses things, and the user confirms and
/// corrects the fields before they are used. Held in memory only, never
/// written to storage, and dropped once the ID has been submitted.
class ScannedNationalId {
  /// The 16-digit PhilSys Card Number (PCN), digits only.
  final String? cardNumber;
  final String? lastName;

  /// "Mga Pangalan / Given Names": one or more first names.
  final String? givenNames;
  final String? middleName;
  final String? suffix;
  final DateTime? birthdate;

  /// `male` or `female`.
  final String? sex;

  /// The address exactly as printed, e.g.
  /// "123 RIZAL ST, BRGY BAGONG PAG-ASA, QUEZON CITY, METRO MANILA".
  final String? address;

  const ScannedNationalId({
    this.cardNumber,
    this.lastName,
    this.givenNames,
    this.middleName,
    this.suffix,
    this.birthdate,
    this.sex,
    this.address,
  });

  static const empty = ScannedNationalId();

  bool get isEmpty =>
      cardNumber == null &&
      lastName == null &&
      givenNames == null &&
      middleName == null &&
      birthdate == null &&
      address == null;

  /// The name as it reads on the card, for the identity review:
  /// "JUAN SANTOS DELA CRUZ JR.".
  String get fullName => [givenNames, middleName, lastName, suffix]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' ');

  /// The card number grouped as printed: "1234-5678-9012-3456".
  String? get formattedCardNumber {
    final digits = cardNumber;
    if (digits == null || digits.length != 16) return digits;
    return [for (var i = 0; i < 16; i += 4) digits.substring(i, i + 4)].join('-');
  }

  /// This reading, with every field [other] has taking precedence. Used to
  /// let the QR code (machine-written) correct what the camera read off the
  /// front, while the address, which only the front carries, is kept.
  ScannedNationalId overriddenBy(ScannedNationalId other) => ScannedNationalId(
        cardNumber: other.cardNumber ?? cardNumber,
        lastName: other.lastName ?? lastName,
        givenNames: other.givenNames ?? givenNames,
        middleName: other.middleName ?? middleName,
        suffix: other.suffix ?? suffix,
        birthdate: other.birthdate ?? birthdate,
        sex: other.sex ?? sex,
        address: other.address ?? address,
      );
}
