import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/ui_helpers.dart';
import '../controllers/browser_controller.dart';
import '../models/download_item.dart';
import '../models/video_source.dart';
import '../services/browser_url_service.dart';
import '../services/video_download_service.dart';
import '../widgets/video_download_confirm_dialog.dart';

/// Full-screen native player for an ordinary direct video link.
class NativeVideoPlayerPage extends StatefulWidget {
  const NativeVideoPlayerPage({super.key, required this.source});

  final VideoSource source;

  @override
  State<NativeVideoPlayerPage> createState() => _NativeVideoPlayerPageState();
}

class _NativeVideoPlayerPageState extends State<NativeVideoPlayerPage>
    with WidgetsBindingObserver {
  static const _urlService = BrowserUrlService();
  static const _downloadService = VideoDownloadService();

  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _initializing = true;
      _hasError = false;
    });
    final uri = Uri.tryParse(widget.source.url);
    if (uri == null) {
      _fail();
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(_onValueChanged);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _initializing = false);
      await controller.play();
    } catch (e) {
      debugPrint('NativeVideoPlayer: init failed: $e');
      _fail();
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _hasError = true;
    });
  }

  void _onValueChanged() {
    if (!mounted) return;
    final value = _controller?.value;
    if (value != null && value.hasError && !_hasError) {
      _fail();
      return;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Pause when leaving the foreground; never auto-resume.
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onValueChanged);
    _controller?.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.source.title.trim().isNotEmpty) return widget.source.title;
    final name = _urlService.fileNameFromUrl(widget.source.url);
    if (name.isNotEmpty) return name;
    final domain = _urlService.extractDomain(widget.source.url);
    return domain.isEmpty ? '视频' : domain;
  }

  Future<void> _retry() => _initialize();

  Future<void> _download() async {
    final domain = _urlService.extractDomain(widget.source.url);
    final fileName = _urlService.fileNameFromUrl(widget.source.url);
    final confirmed = await VideoDownloadConfirmDialog.show(
      context,
      fileName: fileName,
      domain: domain,
      url: widget.source.url,
      fileType: widget.source.mimeType,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<BrowserController>();
    final ok = await _downloadService.openExternally(widget.source.url);
    if (!mounted) return;
    if (ok) {
      controller.addDownloadRecord(
        DownloadItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          fileName: fileName.isEmpty ? _title : fileName,
          url: widget.source.url,
          sourcePageUrl: widget.source.sourcePageUrl,
          status: DownloadStatus.completed,
        ),
      );
      showMessage(context, '已在外部应用打开下载');
    } else {
      await Clipboard.setData(ClipboardData(text: widget.source.url));
      if (mounted) showMessage(context, '无法外部打开，已复制链接');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrowserController>();
    final showDownload = controller.settings.showDownloadButton &&
        widget.source.isDownloadSupported;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              _urlService.extractDomain(widget.source.url),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '重试',
            icon: const Icon(Icons.refresh),
            onPressed: _retry,
          ),
          if (showDownload)
            IconButton(
              tooltip: '下载',
              icon: const Icon(Icons.download_outlined),
              onPressed: _download,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            const Text(
              '视频播放失败',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '该视频可能不受支持或暂时无法访问。',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  _PlayPauseOverlay(controller: controller),
                ],
              ),
            ),
          ),
        ),
        _ControlsBar(controller: controller),
      ],
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final ended =
        value.duration.inMilliseconds > 0 && value.position >= value.duration;
    return GestureDetector(
      onTap: () {
        if (ended) {
          controller.seekTo(Duration.zero);
          controller.play();
        } else {
          value.isPlaying ? controller.pause() : controller.play();
        }
      },
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimatedOpacity(
          opacity: value.isPlaying && !ended ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              ended
                  ? Icons.replay
                  : (value.isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({required this.controller});
  final VideoPlayerController controller;

  String _fmt(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final hasDuration = duration.inMilliseconds > 0;
    final maxMs = duration.inMilliseconds.toDouble();
    final posMs =
        position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          if (hasDuration)
            Slider(
              value: posMs,
              max: maxMs,
              onChanged: (v) =>
                  controller.seekTo(Duration(milliseconds: v.round())),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () =>
                    value.isPlaying ? controller.pause() : controller.play(),
              ),
              Text(
                _fmt(position),
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                hasDuration ? _fmt(duration) : '--:--',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
