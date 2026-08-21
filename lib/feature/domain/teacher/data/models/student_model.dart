class StudentModel {
  final String name;
  final String batch;
  final String id;
  final String password;
  StudentModel({
    required this.name,
    required this.batch,
    required this.id,
    required this.password,
  });
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      name: json['name'],
      batch: json['batch'],
      id: json['id'],
      password: json['password'],
    );
  }
  static Map<String, dynamic> tojson(StudentModel data) {
    return {
      "name": data.name,
      'batch': data.batch,
      "id": data.id,
      "password": data.password,
    };
  }
}
