import 'dart:convert';

import '../models/scanned_national_id.dart';

/// Turns what the camera read off a Philippine National ID into fields.
///
/// - [parseFront] reads the text on the front of the PhilSys card or the
///   ePhilID. Every field there sits under a bilingual label
///   ("Apelyido/Last Name") with its value on the same line or the next.
/// - [parseQr] reads the QR code on the back, which holds the holder's details
///   as JSON. Versions name the keys differently, so it matches them loosely.
///
/// Pure Dart, so it is tested without a camera; the ML Kit calls that produce
/// its input live in [NationalIdReader].
class NationalIdParser {
  NationalIdParser._();

  // Order matters: a middle-name label ("Gitnang Apelyido") also contains the
  // last-name word, and place of birth ("Lugar ng Kapanganakan") the
  // birth-date word, so the more specific label is checked first.
  static final List<(_Field, RegExp)> _labels = [
    (_Field.ignored, RegExp(r'lugar\s*ng\s*kapanganakan|place\s*of\s*birth', caseSensitive: false)),
    (_Field.middleName, RegExp(r'gitnang\s*apelyido|middle\s*name', caseSensitive: false)),
    (_Field.givenNames, RegExp(r'mga\s*pangalan|given\s*names?|first\s*name', caseSensitive: false)),
    (_Field.lastName, RegExp(r'apelyido|last\s*name|surname', caseSensitive: false)),
    (_Field.birthdate, RegExp(r'petsa\s*ng\s*kapanganakan|kapanganakan|date\s*of\s*birth|birth\s*date|birthdate', caseSensitive: false)),
    (_Field.address, RegExp(r'tirahan|address', caseSensitive: false)),
    (_Field.sex, RegExp(r'kasarian|\bsex\b', caseSensitive: false)),
    (_Field.ignored, RegExp(r'petsa\s*ng\s*pagkakaloob|date\s*of\s*issue|blood\s*type|uri\s*ng\s*dugo|marital|kalagayang\s*sibil|republi|pambansang|pagkakakilanlan|identification|card\s*number|\bpcn\b|signature|lagda', caseSensitive: false)),
  ];

  static final RegExp _cardNumber = RegExp(r'(?<![0-9])([0-9OoIl]{4})[\s\-–.]?([0-9OoIl]{4})[\s\-–.]?([0-9OoIl]{4})[\s\-–.]?([0-9OoIl]{4})(?![0-9])');

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// The front of the card, from the text the camera recognised (one line
  /// per printed line).
  static ScannedNationalId parseFront(String text) {
    final lines = text.split(RegExp(r'\r?\n')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    final values = <_Field, String>{};

    for (var i = 0; i < lines.length; i++) {
      final field = _labelOf(lines[i]);
      if (field == null || field == _Field.ignored || values.containsKey(field)) continue;

      // "Last Name: DELA CRUZ" on one line, or the label alone with the
      // value on the next.
      final sameLine = _valueBesideLabel(lines[i]);
      final value = _hasContent(sameLine)
          ? sameLine
          : field == _Field.address
              ? _addressFrom(lines, i + 1)
              : (i + 1 < lines.length && _labelOf(lines[i + 1]) == null ? lines[i + 1] : null);

      if (value != null && _hasContent(value)) values[field] = value;
    }

    return ScannedNationalId(
      cardNumber: _findCardNumber(text),
      lastName: _name(values[_Field.lastName]),
      givenNames: _name(values[_Field.givenNames]),
      middleName: _name(values[_Field.middleName]),
      birthdate: parseDate(values[_Field.birthdate]),
      sex: _sex(values[_Field.sex]),
      address: values[_Field.address],
    );
  }

  /// The QR code on the back. Returns [ScannedNationalId.empty] for anything
  /// that is not the card's JSON, so a QR from elsewhere changes nothing.
  static ScannedNationalId parseQr(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return ScannedNationalId(cardNumber: _findCardNumber(raw));
    }
    if (decoded is! Map) return ScannedNationalId.empty;

    final flat = <String, String>{};
    void collect(Map<dynamic, dynamic> map) {
      map.forEach((key, value) {
        if (value is Map) {
          collect(value);
        } else if (value != null && '$value'.trim().isNotEmpty) {
          flat.putIfAbsent(_key('$key'), () => '$value'.trim());
        }
      });
    }

    collect(decoded);
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = flat[key];
        if (value != null) return value;
      }
      return null;
    }

    final pcn = pick(['pcn', 'cardnumber', 'philsyscardnumber', 'philsyscardno']);
    return ScannedNationalId(
      cardNumber: pcn == null ? null : _findCardNumber(pcn),
      lastName: _name(pick(['lname', 'lastname', 'surname'])),
      givenNames: _name(pick(['fname', 'firstname', 'givenname', 'givennames'])),
      middleName: _name(pick(['mname', 'middlename'])),
      suffix: _name(pick(['suffix', 'extension', 'nameextension'])),
      birthdate: parseDate(pick(['dob', 'dateofbirth', 'birthdate', 'birthday'])),
      sex: _sex(pick(['sex', 'gender'])),
      address: pick(['address', 'addr', 'permanentaddress']),
    );
  }

  /// "JANUARY 01, 1990", "JAN 1 1990", "01 JANUARY 1990", "1990-01-01" or
  /// "01/31/1990" (the card's month-first order). Null when it is not a
  /// plausible birth date.
  static DateTime? parseDate(String? text) {
    if (text == null) return null;
    final value = text.trim();
    DateTime? date;

    RegExpMatch? match;
    if ((match = RegExp(r'([A-Za-z]{3,9})\.?\s+(\d{1,2}),?\s+(\d{4})').firstMatch(value)) != null) {
      date = _date(int.parse(match!.group(3)!), _month(match.group(1)!), int.parse(match.group(2)!));
    } else if ((match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})').firstMatch(value)) != null) {
      date = _date(int.parse(match!.group(3)!), _month(match.group(2)!), int.parse(match.group(1)!));
    } else if ((match = RegExp(r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(value)) != null) {
      date = _date(int.parse(match!.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
    } else if ((match = RegExp(r'(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})').firstMatch(value)) != null) {
      date = _date(int.parse(match!.group(3)!), int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    if (date == null) return null;
    final now = DateTime.now();
    return date.year >= 1900 && date.isBefore(now) ? date : null;
  }

  static DateTime? _date(int year, int? month, int day) {
    if (month == null || month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // DateTime rolls 31 February into March; a real birth date never does.
    return date.month == month ? date : null;
  }

  static int? _month(String name) => _months[name.toLowerCase().substring(0, 3)];

  /// Label words as letters only, for recognising a label the camera
  /// misread ("Apelyldo", "Lasl Name"). Same order as [_labels].
  static const List<(_Field, List<String>)> _fuzzyLabels = [
    (_Field.ignored, ['lugarngkapanganakan', 'placeofbirth']),
    (_Field.middleName, ['gitnangapelyido', 'middlename']),
    (_Field.givenNames, ['mgapangalan', 'givennames']),
    (_Field.lastName, ['apelyido', 'lastname']),
    (_Field.birthdate, ['petsangkapanganakan', 'dateofbirth']),
    (_Field.address, ['tirahan', 'address']),
    (_Field.sex, ['kasarian']),
  ];

  static _Field? _labelOf(String line) {
    for (final (field, pattern) in _labels) {
      if (pattern.hasMatch(line)) return field;
    }
    // Blurry print: a label with a letter or two misread still counts. Only
    // lines with lower-case letters are tried — labels are printed in mixed
    // case, values in capitals, so a value is never taken for a label.
    if (!RegExp(r'[a-z]').hasMatch(line)) return null;
    final letters = line.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (final (field, words) in _fuzzyLabels) {
      for (final word in words) {
        if (_containsApprox(letters, word, word.length >= 10 ? 2 : 1)) return field;
      }
    }
    return null;
  }

  /// Whether [text] holds [word] with at most [allowed] wrong letters.
  static bool _containsApprox(String text, String word, int allowed) {
    if (text.length < word.length - allowed) return false;
    for (var start = 0; start + word.length - allowed <= text.length; start++) {
      for (var length = word.length - allowed; length <= word.length + allowed; length++) {
        if (start + length > text.length) break;
        if (_distance(text.substring(start, start + length), word) <= allowed) return true;
      }
    }
    return false;
  }

  static int _distance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = [previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }

  /// A value printed on the label's own line ("Last Name: DELA CRUZ"). The
  /// card prints values in capitals and labels in mixed case, so only the
  /// trailing words without lower-case letters count — leftover words of a
  /// misread label ("Apelyldo Lasl Name") are not taken for a value.
  static String _valueBesideLabel(String line) {
    final words = _withoutLabels(line).split(' ');
    var start = words.length;
    while (start > 0 && !RegExp(r'[a-z]').hasMatch(words[start - 1])) {
      start--;
    }
    return words.sublist(start).join(' ').trim();
  }

  static String _withoutLabels(String line) {
    var rest = line;
    for (final (_, pattern) in _labels) {
      rest = rest.replaceAll(pattern, ' ');
    }
    return rest.replaceAll(RegExp(r'[/:|]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// The address runs from the line after its label until the next label,
  /// over at most three printed lines.
  static String? _addressFrom(List<String> lines, int start) {
    final parts = <String>[];
    for (var i = start; i < lines.length && parts.length < 3; i++) {
      if (_labelOf(lines[i]) != null) break;
      parts.add(lines[i].replaceAll(RegExp(r',\s*$'), ''));
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static bool _hasContent(String value) => RegExp(r'[A-Za-z0-9].*[A-Za-z0-9]').hasMatch(value);

  static String? _findCardNumber(String text) {
    for (final match in _cardNumber.allMatches(text)) {
      final digits = [1, 2, 3, 4].map((g) => match.group(g)!).join().replaceAll(RegExp('[Oo]'), '0').replaceAll(RegExp('[Il]'), '1');
      if (RegExp(r'^\d{16}$').hasMatch(digits)) return digits;
    }
    return null;
  }

  /// "DELA CRUZ" → "Dela Cruz". Names are printed in capitals.
  static String? _name(String? value) {
    final text = value?.replaceAll(RegExp(r'[^A-Za-zÑñ\s\-.\x27]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text == null || text.isEmpty) return null;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word.split('-').map((part) => part.isEmpty ? part : part[0].toUpperCase() + part.substring(1).toLowerCase()).join('-');
    }).join(' ');
  }

  static String? _sex(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.startsWith('m') || text.startsWith('lalaki')) return 'male';
    if (text.startsWith('f') || text.startsWith('babae')) return 'female';
    return null;
  }

  static String _key(String key) => key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}

enum _Field { lastName, givenNames, middleName, birthdate, sex, address, ignored }
