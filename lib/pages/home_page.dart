import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'write_post_page.dart';
import 'blog_detail_page.dart';
import '../services/auth_email_service.dart';
import '../services/blog_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final blogService = BlogService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          StreamBuilder<List<BlogPost>>(
            stream: blogService.getUserBlogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final blogs = snapshot.data ?? [];

              if (blogs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final blog = blogs[index];
                    return _BlogCard(
                      blog: blog,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlogDetailPage(blog: blog),
                          ),
                        );
                      },
                    );
                  }, childCount: blogs.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final auth = EmailSignInService();

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      toolbarHeight: 64,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Text(
        'Personal Blogs',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 12),
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true && context.mounted) {
              final navigator = Navigator.of(context);
              await auth.signOut();
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout_sharp, size: 24),
              SizedBox(width: 4),
              Text('Sign Out', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.4,
            child: Icon(
              Icons.article_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add your first article',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(30),
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const WritePostPage()),
        );
      },
      child: const Icon(
        Icons.add,
        size: 24,
        color: CupertinoColors.white,
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPost blog;
  final VoidCallback onTap;

  const _BlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(60),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      blog.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              
              Text(
                blog.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  blog.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
