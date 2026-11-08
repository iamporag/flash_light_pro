import 'package:equatable/equatable.dart';

class MorseResult extends Equatable {
  const MorseResult({required this.morse, required this.unsupported});

  /// Dots/dashes with spaces between letters and `/` between words.
  final String morse;
  final List<String> unsupported;

  bool get hasContent => morse.isNotEmpty;

  bool get isPlayable => hasContent && unsupported.isEmpty;

  @override
  List<Object?> get props => [morse, unsupported];
}

/// Standard International Morse code for A-Z and 0-9.
abstract final class MorseCodec {
  static const Map<String, String> table = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
  };

  static MorseResult encode(String input) {
    final unsupported = <String>{};
    final encodedWords = <String>[];

    for (final word in input.trim().toUpperCase().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;

      final encodedLetters = <String>[];
      for (final character in word.split('')) {
        final code = table[character];
        if (code != null) {
          encodedLetters.add(code);
        } else {
          unsupported.add(character);
        }
      }

      if (encodedLetters.isNotEmpty) {
        encodedWords.add(encodedLetters.join(' '));
      }
    }

    final sortedUnsupported = unsupported.toList()..sort();
    return MorseResult(
      morse: encodedWords.join(' / '),
      unsupported: sortedUnsupported,
    );
  }
}
