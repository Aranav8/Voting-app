import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/candidates.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.31.83:3000';

  Future<List<Candidate>> getAllCandidates() async {
    final response = await http.get(Uri.parse('$baseUrl/api/candidates'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Candidate.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load candidates');
    }
  }

  Future<Candidate> getCandidateById(String id) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/candidates/id/$id'));
    if (response.statusCode == 200) {
      return Candidate.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load candidate');
    }
  }

  Future<Candidate> getCandidateByName(String name) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/candidates/name/$name'));
    if (response.statusCode == 200) {
      return Candidate.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load candidate');
    }
  }
}
