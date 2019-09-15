class MetricTime {
  final double _beats;

  const MetricTime(
      {int whole = 0, int half = 0, int quarter = 0, int eight = 0})
      : _beats = whole / 4.0 + half / 2.0 + quarter + eight * 2.0;

  const MetricTime.beats(this._beats);
}

class Timeable {
  MetricTime start;
  MetricTime length;

  Timeable({this.start, this.length}) {
    if (start == null) {
      start = const MetricTime();
    }
    if (length == null) {
      length = const MetricTime(quarter: 1);
    }
  }
  Timeable.fromJson(Map<String, dynamic> json)
      : start = MetricTime.beats(json["start"].toDouble()),
        length = MetricTime.beats(json["length"].toDouble());

  Map<String, dynamic> toJson() =>
      {"start": start._beats, "length": length._beats};
}

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

class Chord extends Timeable {
  ClampedPitch root;
  ChordType type;

  String get nameAbbreviated => root.name + type.abbreviation;

  Chord(this.root, this.type, {MetricTime start, MetricTime length})
      : super(start: start, length: length);

  Chord.fromJson(Map<String, dynamic> json)
      : root = ClampedPitch.parse(json["root"]),
        type = ChordType.find(json["type"]),
        super.fromJson(json);

  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({"root": root.name, "type": type.abbreviation});
}

class Pitch extends ClampedPitch {
  int octave;
  String get name => "${super.name} ${octave.toString()}";

  Pitch(octIndex, mod, this.octave) : super(octIndex, mod);
}

enum Modification { SHARP, NONE, FLAT }

class ClampedPitch {
  static const _namesWhite = ["C", "D", "E", "F", "G", "A", "B"];

  int whiteIndex;
  Modification modification;

  String get name => _namesWhite[whiteIndex] + _modString();
  int get pitchInTwelve => (12 + whiteIndex + _modAdd()) % 12;

  ClampedPitch(this.whiteIndex, this.modification);

  ClampedPitch.c() : this(0, Modification.NONE);

  ClampedPitch.parse(String s) {
    whiteIndex = _namesWhite.indexOf(s[0]);
    modification = s.length < 2
        ? Modification.NONE
        : (s[1] == "#" ? Modification.SHARP : Modification.FLAT);
  }

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
