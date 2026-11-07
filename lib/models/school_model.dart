class SchoolModel {
  final int? id;
  final String name;
  final String? schoolName;
  final String? location;
  final String? npsn;

  SchoolModel({
    this.id,
    required this.name,
    this.schoolName,
    this.location,
    this.npsn,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'],
      name: json['name'] ?? '',
      schoolName: json['school_name'],
      location: json['location'],
      npsn: json['npsn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'school_name': schoolName,
    'location': location,
    'npsn': npsn,
  };
}

