import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlogPost {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String authorId;  
  final DateTime? createdAt;  

  BlogPost({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.authorId,
    this.createdAt,
  });

  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'authorId': authorId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  Future<bool> publishBlog({
    required String title,
    required String subtitle,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('blogs').add({
        'title': title,
        'subtitle': subtitle,
        'content': content,
        'authorId': user.uid,  
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      log('Error publishing blog: $e');
      return false;
    }
  }

  
  Stream<List<BlogPost>> getUserBlogs() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('blogs')
        .where('authorId', isEqualTo: user.uid)  
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
    });
  }

  
  Future<bool> deleteBlog(String blogId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      
      final doc = await _firestore.collection('blogs').doc(blogId).get();
      if (doc.data()?['authorId'] != user.uid) {
        throw Exception('Unauthorized: You can only delete your own blogs');
      }

      await _firestore.collection('blogs').doc(blogId).delete();
      return true;
    } catch (e) {
      log('Error deleting blog: $e');
      return false;
    }
  }

  
  Future<bool> updateBlog({
    required String blogId,
    required String title,
    required String subtitle,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      
      final doc = await _firestore.collection('blogs').doc(blogId).get();
      if (doc.data()?['authorId'] != user.uid) {
        throw Exception('Unauthorized: You can only update your own blogs');
      }

      await _firestore.collection('blogs').doc(blogId).update({
        'title': title,
        'subtitle': subtitle,
        'content': content,
      });
      return true;
    } catch (e) {
      log('Error updating blog: $e');
      return false;
    }
  }
}