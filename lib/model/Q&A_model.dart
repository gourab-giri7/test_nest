class QAModel {
  String id;
  String q;
  String a;
  String b;
  String c;
  String d;
  String ans;
  String? subject;
  String? chapter;

  QAModel({
    this.id = '',
    required this.q,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.ans,
    this.subject,
    this.chapter,
  });

  factory QAModel.fromJson(Map<String, dynamic> json) {
    return QAModel(
      id: (json['id'] ?? json['question_id'] ?? '').toString(),
      q: json['q']?.toString() ?? '',
      a: json['a']?.toString() ?? '',
      b: json['b']?.toString() ?? '',
      c: json['c']?.toString() ?? '',
      d: json['d']?.toString() ?? '',
      ans: json['ans']?.toString() ?? '',
      subject: json['subject']?.toString() ?? json['subject_name']?.toString(),
      chapter: json['chapter']?.toString() ?? json['chapter_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'q': q,
      'a': a,
      'b': b,
      'c': c,
      'd': d,
      'ans': ans,
      if (subject != null && subject!.isNotEmpty) 'subject': subject,
      if (chapter != null && chapter!.isNotEmpty) 'chapter': chapter,
    };
  }
}
