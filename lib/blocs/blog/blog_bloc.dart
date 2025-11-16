import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/blog_service.dart';
import 'blog_event.dart';
import 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final BlogService _blogService;
  StreamSubscription<List<BlogPost>>? _blogsSubscription;

  BlogBloc({required BlogService blogService})
      : _blogService = blogService,
        super(const BlogInitial()) {
    on<BlogLoadRequested>(_onLoadBlogs);
    on<BlogPublishRequested>(_onPublishBlog);
    on<BlogDeleteRequested>(_onDeleteBlog);
    on<BlogUpdateRequested>(_onUpdateBlog);
    on<_BlogsUpdated>(_onBlogsUpdated);
  }

  Future<void> _onLoadBlogs(
    BlogLoadRequested event,
    Emitter<BlogState> emit,
  ) async {
    if (state is! BlogLoaded) {
      emit(const BlogLoading());
    }
    
    await _blogsSubscription?.cancel();
    
    _blogsSubscription = _blogService.getUserBlogs().listen(
      (blogs) {
        if (!isClosed) {
          add(_BlogsUpdated(blogs));
        }
      },
    );
  }

  void _onBlogsUpdated(
    _BlogsUpdated event,
    Emitter<BlogState> emit,
  ) {
    final currentState = state;
    if (currentState is BlogLoaded && currentState.operation != null) {
      emit(BlogLoaded(event.blogs));
    } else {
      emit(BlogLoaded(event.blogs));
    }
  }

  Future<void> _onPublishBlog(
    BlogPublishRequested event,
    Emitter<BlogState> emit,
  ) async {
    final currentState = state;
    final currentBlogs = currentState is BlogLoaded ? currentState.blogs : <BlogPost>[];
    
    emit(BlogLoaded(currentBlogs, operation: BlogOperation.publishing));
    
    try {
      final success = await _blogService.publishBlog(
        title: event.title,
        subtitle: event.subtitle,
        content: event.content,
      );
      
      if (success) {
        // ✅ Emit published state and let the Firestore stream update the list
        emit(BlogLoaded(currentBlogs, operation: BlogOperation.published));
        // The stream will automatically add the new blog to the list
      } else {
        emit(BlogError('Failed to publish blog', blogs: currentBlogs));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BlogLoaded(currentBlogs));
      }
    } catch (e) {
      emit(BlogError('Error: $e', blogs: currentBlogs));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(BlogLoaded(currentBlogs));
    }
  }

  Future<void> _onDeleteBlog(
    BlogDeleteRequested event,
    Emitter<BlogState> emit,
  ) async {
    final currentState = state;
    final currentBlogs = currentState is BlogLoaded ? currentState.blogs : <BlogPost>[];
    
    emit(BlogLoaded(currentBlogs, operation: BlogOperation.deleting));
    
    try {
      final success = await _blogService.deleteBlog(event.blogId);
      
      if (success) {
        // ✅ Remove the deleted blog from the current list immediately
        final updatedBlogs = currentBlogs.where((blog) => blog.id != event.blogId).toList();
        emit(BlogLoaded(updatedBlogs, operation: BlogOperation.deleted));
        
        // Clear the operation state after a short delay
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BlogLoaded(updatedBlogs));
      } else {
        emit(BlogError('Failed to delete blog', blogs: currentBlogs));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BlogLoaded(currentBlogs));
      }
    } catch (e) {
      emit(BlogError('Error: $e', blogs: currentBlogs));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(BlogLoaded(currentBlogs));
    }
  }

  Future<void> _onUpdateBlog(
    BlogUpdateRequested event,
    Emitter<BlogState> emit,
  ) async {
    final currentState = state;
    final currentBlogs = currentState is BlogLoaded ? currentState.blogs : <BlogPost>[];
    
    try {
      final success = await _blogService.updateBlog(
        blogId: event.blogId,
        title: event.title,
        subtitle: event.subtitle,
        content: event.content,
      );
      if (!success) {
        emit(BlogError('Failed to update blog', blogs: currentBlogs));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BlogLoaded(currentBlogs));
      }
    } catch (e) {
      emit(BlogError('Error: $e', blogs: currentBlogs));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(BlogLoaded(currentBlogs));
    }
  }

  @override
  Future<void> close() {
    _blogsSubscription?.cancel();
    return super.close();
  }
}

class _BlogsUpdated extends BlogEvent {
  final List<BlogPost> blogs;

  const _BlogsUpdated(this.blogs);

  @override
  List<Object?> get props => [blogs];
}