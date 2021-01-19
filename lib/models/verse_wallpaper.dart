import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerseWallpaper {
  final String id;
  final String medialUrl;
  final String thumbnail;
  final String book;
  final List<String> categories;
  final int downloads;
  final int chapter;
  final int verse;
  final int likes;
  final Timestamp timestamp;
  final bool isDailyVerse;
  final bool isFeatured;

  VerseWallpaper({
    @required this.id,
    @required this.medialUrl,
    @required this.thumbnail,
    @required this.book,
    this.categories,
    this.downloads,
    @required this.chapter,
    @required this.verse,
    this.likes,
    @required this.timestamp,
    @required this.isDailyVerse,
    @required this.isFeatured,
  });

  factory VerseWallpaper.fromDocument(DocumentSnapshot doc) {
    return VerseWallpaper(
      id: doc['id'],
      medialUrl: doc['mediaUrl'],
      thumbnail: doc['thumbnail'],
      book: doc['book'],
      categories: doc['categories'],
      downloads: doc['downloads'],
      chapter: doc['chapter'],
      verse: doc['verse'],
      likes: doc['likes'],
      timestamp: doc['timestamp'],
      isDailyVerse: doc['isDailyVerse'],
      isFeatured: doc['featured'],
    );
  }
}
