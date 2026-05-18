import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/program.dart';
import '../models/article.dart';
import '../models/live_stream.dart';

class ApiService {
  static const String _baseUrl = 'https://makkah-backend.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<List<Program>> getPrograms() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/programs?activeOnly=true'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return Program.samples;
  }

  static Future<List<Article>> getArticles({int limit = 10}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/articles?publicOnly=true&limit=$limit'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List articles = decoded is List ? decoded : ((decoded as Map)['articles'] as List? ?? []);
        return articles.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<LiveStream> getLiveStream() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/live?activeOnly=true'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List items = decoded is List ? decoded : [decoded];
        if (items.isNotEmpty) {
          return LiveStream.fromJson(items[0] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return LiveStream.fallback;
  }
}
