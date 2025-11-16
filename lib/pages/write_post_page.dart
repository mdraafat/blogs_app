import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blog/blog_bloc.dart';
import '../blocs/blog/blog_event.dart';
import '../blocs/blog/blog_state.dart';

class WritePostPage extends StatefulWidget {
  const WritePostPage({super.key});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isPublished = false;
  int _previousBlogCount = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _publishPost() {
    if (!_formKey.currentState!.validate()) return;

    if (_titleController.text.trim().isEmpty ||
        _subtitleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<BlogBloc>().add(BlogPublishRequested(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      content: _contentController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BlogBloc, BlogState>(
      listener: (context, state) {
        // Store the blog count when publishing starts
        if (state is BlogLoaded && state.operation == BlogOperation.publishing) {
          _previousBlogCount = state.blogs.length;
        }
        
        // Mark as published when the operation state is set
        if (state is BlogLoaded && state.operation == BlogOperation.published) {
          _isPublished = true;
        }
        
        // Wait for the new blog to appear in the list (stream update)
        if (_isPublished && state is BlogLoaded && state.operation == null) {
          if (state.blogs.length > _previousBlogCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Blog published successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
        
        if (state is BlogError) {
          _isPublished = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<BlogBloc, BlogState>(
        builder: (context, state) {
          final isPublishing = state is BlogLoaded && 
                               state.operation == BlogOperation.publishing;

          return Scaffold(
            appBar: AppBar(
              title: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Write Post'),
              ),
              automaticallyImplyLeading: false,
              actions: [
                if (isPublishing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TitleField(controller: _titleController),
                    const SizedBox(height: 16),
                    _SubtitleField(controller: _subtitleController),
                    const SizedBox(height: 24),
                    _ContentField(controller: _contentController),
                    const SizedBox(height: 32),
                    _PublishButton(
                      isPublishing: isPublishing,
                      onPressed: _publishPost,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  final TextEditingController controller;

  const _TitleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: 'Post Title',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }
}

class _SubtitleField extends StatelessWidget {
  final TextEditingController controller;

  const _SubtitleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: 'Subtitle or brief description',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a subtitle';
        }
        return null;
      },
    );
  }
}

class _ContentField extends StatelessWidget {
  final TextEditingController controller;

  const _ContentField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Write your content here...',
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 20,
      minLines: 10,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter some content';
        }
        return null;
      },
    );
  }
}

class _PublishButton extends StatelessWidget {
  final bool isPublishing;
  final VoidCallback onPressed;

  const _PublishButton({
    required this.isPublishing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isPublishing ? null : onPressed,
        child: isPublishing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Publish', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
