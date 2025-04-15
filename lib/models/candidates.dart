class Candidate {
  final String id;
  final String name;
  final String partyName;
  final String manifesto;
  final Socials socials;
  final String partyInfo;
  final String candidateInfo;
  final String candidatePhoto;
  final String partyPhoto;

  Candidate({
    required this.id,
    required this.name,
    required this.partyName,
    required this.manifesto,
    required this.socials,
    required this.partyInfo,
    required this.candidateInfo,
    required this.candidatePhoto,
    required this.partyPhoto,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['_id'],
      name: json['name'],
      partyName: json['partyName'],
      manifesto: json['manifesto'],
      socials: Socials.fromJson(json['socials']),
      partyInfo: json['partyInfo'],
      candidateInfo: json['candidateInfo'],
      candidatePhoto: json['candidatePhoto'],
      partyPhoto: json['partyPhoto'],
    );
  }
}

class Socials {
  final String facebook;
  final String instagram;
  final String youtube;
  final String linkedin;

  Socials({
    required this.facebook,
    required this.instagram,
    required this.youtube,
    required this.linkedin,
  });

  factory Socials.fromJson(Map<String, dynamic> json) {
    return Socials(
      facebook: json['facebook'],
      instagram: json['instagram'],
      youtube: json['youtube'],
      linkedin: json['linkedin'],
    );
  }
}
