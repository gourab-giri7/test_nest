class QAModel {
  String q;
  String a;
  String b;
  String c;
  String d;
  String ans;

  QAModel({
    required this.q,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.ans,
  });

  factory QAModel.fromJson(Map<String, dynamic> json) {
    return QAModel(
      q: json['q']?.toString() ?? '',
      a: json['a']?.toString() ?? '',
      b: json['b']?.toString() ?? '',
      c: json['c']?.toString() ?? '',
      d: json['d']?.toString() ?? '',
      ans: json['ans']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'q': q,
      'a': a,
      'b': b,
      'c': c,
      'd': d,
      'ans': ans,
    };
  }
}