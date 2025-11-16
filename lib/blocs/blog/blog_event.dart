import 'package:equatable/equatable.dart';

abstract class BlogEvent extends Equatable {
  const BlogEvent();

  @override
  List<Object?> get props => [];
}

class BlogLoadRequested extends BlogEvent {
  const BlogLoadRequested();
}

class BlogPublishRequested extends BlogEvent {
  final String title;
  final String subtitle;
  final String content;

  const BlogPublishRequested({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  List<Object?> get props => [title, subtitle, content];
}

class BlogDeleteRequested extends BlogEvent {
  final String blogId;

  const BlogDeleteRequested(this.blogId);

  @override
  List<Object?> get props => [blogId];
}

class BlogUpdateRequested extends BlogEvent {
  final String blogId;
  final String title;
  final String subtitle;
  final String content;

  const BlogUpdateRequested({
    required this.blogId,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  List<Object?> get props => [blogId, title, subtitle, content];
}