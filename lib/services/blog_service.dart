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
        log('Error: User not authenticated');
        return false;
      }

      await _firestore.collection('blogs').add({
        'title': title,
        'subtitle': subtitle,
        'content': content,
        'authorId': user.uid,  
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      log('Blog published successfully');
      return true;
    } catch (e) {
      log('Error publishing blog: $e');
      return false;
    }
  }

  Stream<List<BlogPost>> getUserBlogs() {
    final user = _auth.currentUser;
    if (user == null) {
      log('Error: User not authenticated');
      return Stream.value([]);
    }

    return _firestore
        .collection('blogs')
        .where('authorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      log('Received ${snapshot.docs.length} blogs from Firestore');
      final blogs = snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
      blogs.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return blogs;
    });
  }

  Future<bool> deleteBlog(String blogId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log('Error: User not authenticated');
        return false;
      }

      log('Attempting to delete blog: $blogId');
      
      final doc = await _firestore.collection('blogs').doc(blogId).get();
      
      if (!doc.exists) {
        log('Error: Blog document does not exist');
        return false;
      }

      final authorId = doc.data()?['authorId'];
      log('Blog authorId: $authorId, Current user: ${user.uid}');
      
      if (authorId != user.uid) {
        log('Error: Unauthorized - user can only delete own blogs');
        return false;
      }

      await _firestore.collection('blogs').doc(blogId).delete();
      log('Blog deleted successfully: $blogId');
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
        log('Error: User not authenticated');
        return false;
      }

      final doc = await _firestore.collection('blogs').doc(blogId).get();
      
      if (!doc.exists) {
        log('Error: Blog document does not exist');
        return false;
      }
      
      if (doc.data()?['authorId'] != user.uid) {
        log('Error: Unauthorized - user can only update own blogs');
        return false;
      }

      await _firestore.collection('blogs').doc(blogId).update({
        'title': title,
        'subtitle': subtitle,
        'content': content,
      });
      
      log('Blog updated successfully');
      return true;
    } catch (e) {
      log('Error updating blog: $e');
      return false;
    }
  }
}