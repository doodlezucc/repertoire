class KeyScale {
  ClampedPitch tonic;
  Scale scale;

  String get name => tonic.name + " " + scale.name;

  KeyScale(this.tonic, this.scale);
  KeyScale.cMajor() : this(ClampedPitch.c(), Scale.Major);

  KeyScale.fromJson(Map<String, dynamic> json)
      : tonic = ClampedPitch.parse(json["tonic"]),
        scale = Scale.find(json["scale"]);

  Map<String, dynamic> toJson() => {"tonic": tonic.name, "scale": scale.name};
}

class Scale {
  final String name;
  final List<bool> active;

  const Scale(this.name, this.active);

  static const Scale Major = const Scale("Major", const [
    false,
    true,
    false,
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true
  ]);
  static const Scale Minor = const Scale("Minor", const [
    false,
    true,
    true,
    false,
    true,
    false,
    true,
    true,
    false,
    true,
    false
  ]);

  static const List<Scale> values = [Major, Minor];

  static Scale find(String name) {
    return values.firstWhere((sc) => sc.name == name);
  }
}

class ChordType {
  final String name;
  final String abbreviation;

  const ChordType(this.name, this.abbreviation);

  static const ChordType Major = const ChordType("Major", "");
  static const ChordType Minor = const ChordType("Minor", "m");
  static const ChordType Maj7 = const ChordType("Major 7th", "maj7");
  static const ChordType Seventh = const ChordType("7th", "7");
  static const ChordType Min7 = const ChordType("Minor 7th", "m7");

  static const List<ChordType> values = [Major, Minor, Maj7, Seventh, Min7];

  static ChordType find(String abbreviation) {
    return values.firstWhere((ct) => ct.abbreviation == abbreviation);
  }
}

const allKeys = [
  ['C'],
  ['C#', 'Db'],
  ['D'],
  ['D#', 'Eb'],
  ['E'],
  ['F'],
  ['F#', 'Gb'],
  ['G'],
  ['G#', 'Ab'],
  ['A'],
  ['A#', 'Bb'],
  ['B'],
];

String transposeSymbol(String s, int transpose) {
  if (transpose == 0) return s;

  var slashIndex = s.indexOf('/') + 1;
  if (slashIndex > 0) {
    s = s.substring(0, slashIndex) +
        transposeSymbol(s.substring(slashIndex), transpose);
  }

  var pitch = RegExp(r'\S[#,b]?').firstMatch(s)!.group(0)!;
  var index = allKeys.indexWhere((p) => p.contains(pitch));

  if (index < 0) return s;

  var tPitch = allKeys[(index + transpose) % allKeys.length][0];

  return tPitch + s.substring(pitch.length);
}

final chordsRegExp = RegExp(
    r"([A-G](##?|bb?)?((maj|sus|m|min|aug|dim|add)?)\d?(add|\/[A-G])?)|N\.C\.|\s+");

bool isChordLine(String s) {
  if (s.isEmpty) return false;

  var matches = chordsRegExp.allMatches(s + ' ');
  var matchedChars = matches.fold<int>(0, (v, e) => v + e.end - e.start);

  var proportion = matchedChars / s.length;
  return proportion > 0.9;
}

class Chord {
  ClampedPitch root;
  ChordType type;

  String get nameAbbreviated => root.name + type.abbreviation;

  Chord(this.root, this.type);

  Chord.fromJson(Map<String, dynamic> json)
      : root = ClampedPitch.parse(json["root"]),
        type = ChordType.find(json["type"]);

  Map<String, dynamic> toJson() =>
      {"root": root.name, "type": type.abbreviation};

  @override
  String toString() {
    return nameAbbreviated;
  }
}

class Pitch extends ClampedPitch {
  int octave;
  String get name => "${super.name} ${octave.toString()}";

  Pitch(octIndex, mod, this.octave) : super(octIndex, mod);
}

enum Modification { SHARP, NONE, FLAT }

class ClampedPitch {
  static const whiteKeys = ["C", "D", "E", "F", "G", "A", "B"];

  int whiteIndex;
  Modification modification;

  String get name => whiteKeys[whiteIndex] + _modString();
  int get pitchInTwelve => (12 + whiteIndex + _modAdd()) % 12;

  ClampedPitch(this.whiteIndex, this.modification);

  ClampedPitch.c() : this(0, Modification.NONE);

  ClampedPitch.parse(String s)
      : whiteIndex = whiteKeys.indexOf(s[0]),
        modification = s.length < 2
            ? Modification.NONE
            : (s[1] == "#" ? Modification.SHARP : Modification.FLAT);

  String _modString() {
    return modification == Modification.SHARP
        ? "#"
        : (modification == Modification.FLAT ? "b" : "");
  }

  int _modAdd() {
    return modification == Modification.SHARP
        ? 1
        : (modification == Modification.FLAT ? -1 : 0);
  }
}
