import 'package:flutter/material.dart';

/// Improved photo gallery widget with better thumbnail display and modal viewing
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({
    required this.photoUrls,
    required this.onImageTap,
    this.maxCrossAxisCount = 3,
    this.aspectRatio = 1.0,
    super.key,
  });

  final List<String> photoUrls;
  final Function(int index, String url) onImageTap;
  final int maxCrossAxisCount;
  final double aspectRatio;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos (${widget.photoUrls.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.maxCrossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: widget.aspectRatio,
              ),
              itemCount: widget.photoUrls.length,
              itemBuilder: (context, index) {
                final url = widget.photoUrls[index];
                return _PhotoThumbnail(
                  url: url,
                  index: index,
                  onTap: () => widget.onImageTap(index, url),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.url,
    required this.index,
    required this.onTap,
  });

  final String url;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Index badge
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Expand icon overlay
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo viewer dialog for fullscreen image viewing
class PhotoViewerDialog extends StatefulWidget {
  const PhotoViewerDialog({
    required this.photoUrls,
    required this.initialIndex,
    super.key,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<PhotoViewerDialog> createState() => _PhotoViewerDialogState();

  static Future<void> show(
    BuildContext context, {
    required List<String> photoUrls,
    required int initialIndex,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => PhotoViewerDialog(
        photoUrls: photoUrls,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _PhotoViewerDialogState extends State<PhotoViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Photo ${_currentIndex + 1} of ${widget.photoUrls.length}',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemCount: widget.photoUrls.length,
          itemBuilder: (context, index) {
            return _FullscreenPhotoView(
              url: widget.photoUrls[index],
              onDownload: () => _showDownloadSnackbar(context),
            );
          },
        ),
      ),
    );
  }

  void _showDownloadSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo download functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _FullscreenPhotoView extends StatelessWidget {
  const _FullscreenPhotoView({
    required this.url,
    required this.onDownload,
  });

  final String url;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image
        Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),

        // Download button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white.withOpacity(0.9),
            onPressed: onDownload,
            child: const Icon(
              Icons.download,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
