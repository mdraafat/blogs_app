import 'package:equatable/equatable.dart';

import '../../services/blog_service.dart';

abstract class BlogState extends Equatable {
  const BlogState();

  @override
  List<Object?> get props => [];
}

class BlogInitial extends BlogState {
  const BlogInitial();
}

class BlogLoading extends BlogState {
  const BlogLoading();
}

class BlogLoaded extends BlogState {
  final List<BlogPost> blogs;
  final BlogOperation? operation;

  const BlogLoaded(this.blogs, {this.operation});

  @override
  List<Object?> get props => [blogs, operation];
}

class BlogError extends BlogState {
  final String message;
  final List<BlogPost>? blogs;

  const BlogError(this.message, {this.blogs});

  @override
  List<Object?> get props => [message, blogs];
}

enum BlogOperation {
  publishing,
  published,
  deleting,
  deleted,
}