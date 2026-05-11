import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DocumentModel {
  final String path;
  final String name;
  final String category;
  final int pageCount;
  final DateTime createdAt;

  DocumentModel({
    required this.path,
    required this.name,
    required this.category,
    required this.pageCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'category': category,
    'pageCount': pageCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    path: json['path'],
    name: json['name'],
    category: json['category'],
    pageCount: json['pageCount'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class DocumentService {
  static const String _key = 'saved_documents';

  static Future<void> saveDocument({
    required String path,
    required String name,
    required String category,
    required int pageCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final docs = await getDocuments();
    docs.insert(0, DocumentModel(
      path: path,
      name: name,
      category: category,
      pageCount: pageCount,
      createdAt: DateTime.now(),
    ));
    final jsonList = docs.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  static Future<List<DocumentModel>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((j) => DocumentModel.fromJson(jsonDecode(j)))
        .where((d) => File(d.path).existsSync())
        .toList();
  }

  static Future<void> deleteDocument(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final docs = await getDocuments();
    docs.removeWhere((d) => d.path == path);
    try { File(path).deleteSync(); } catch (_) {}
    final jsonList = docs.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }
}