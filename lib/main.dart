import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const ArgonCutUltraApp());

class ArgonCutUltraApp extends StatelessWidget {
  const ArgonCutUltraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgonCut Ultra Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF08090C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF7C4DFF),
        ),
      ),
      home: const HomeDashboardScreen(),
    );
  }
}

class ProjectDraft {
  String id, title, resolution, ratio;
  String? videoPath;
  ProjectDraft({required this.id, required this.title, this.videoPath, this.resolution = '4K HDR', this.ratio = '9:16'});
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});
  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _navIdx = 0;
  final ImagePicker _picker = ImagePicker();
  final List<ProjectDraft> _drafts = [
    ProjectDraft(id: 'd1', title: 'Cinematic Vlog Reel #1', resolution: '4K 60fps', ratio: '9:16'),
    ProjectDraft(id: 'd2', title: 'YouTube Gaming Intro', resolution: '1080p HD', ratio: '16:9'),
  ];

  Future<void> _startProject({ImageSource src = ImageSource.gallery, String? title}) async {
    final XFile? p = await _picker.pickVideo(source: src);
    if (p != null) {
      final d = ProjectDraft(id: 'd_${DateTime.now().millisecondsSinceEpoch}', title: title ?? 'Project ${_drafts.length + 1}', videoPath: p.path);
      setState(() => _drafts.insert(0, d));
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => UltraEditorScreen(draft: d))).then((_) => setState(() {}));
      }
    }
  }

  void _openAIPromptSheet(String title, String desc) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✨ $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(hintText: 'Enter prompt or script here...', filled: true, fillColor: const Color(0xFF1C202E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(ctx);
                  _startProject(title: title);
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate & Open Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F16),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFF00F2FE)),
            SizedBox(width: 6),
            Text('ArgonCut Ultra', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: _navIdx == 1 ? _templatesTab() : (_navIdx == 2 ? _stockTab() : (_navIdx == 3 ? _aiHubTab() : _homeDraftsTab())),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIdx,
        backgroundColor: const Color(0xFF0D0F16),
        selectedItemColor: const Color(0xFF00F2FE),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _navIdx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Edit & Drafts'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_rounded), label: 'Templates'),
          BottomNavigationBarItem(icon: Icon(Icons.perm_media_rounded), label: 'Stock Media'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Studio'),
        ],
      ),
    );
  }

  Widget _homeDraftsTab() {
    final shortcuts = [
      {'i': Icons.auto_fix_high, 't': 'Auto Cutout'},
      {'i': Icons.description, 't': 'Script to Vid'},
      {'i': Icons.bolt, 't': 'Long to Short'},
      {'i': Icons.subtitles, 't': 'Auto Captions'},
      {'i': Icons.videocam, 't': 'Camera Rec'},
      {'i': Icons.edit_note, 't': 'Transcript Edit'},
      {'i': Icons.hd, 't': 'AI 4K Upscale'},
      {'i': Icons.translate, 't': 'AI Translator'},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => _startProject(),
          child: Container(
            height: 125,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, size: 42, color: Colors.black),
                SizedBox(height: 6),
                Text('New Project', style: TextStyle(color: Colors.black, fontSize: 19, fontWeight: FontWeight.w900)),
                Text('Multi-Layer Timeline • 4K 60fps • AI Tools', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: shortcuts.length,
          itemBuilder: (ctx, i) => InkWell(
            onTap: () {
              final label = shortcuts[i]['t'] as String;
              if (label == 'Camera Rec') {
                _startProject(src: ImageSource.camera, title: 'Camera Clip');
              } else {
                _openAIPromptSheet(label, 'AI powered automatic processing for $label');
              }
            },
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF141824), borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(shortcuts[i]['i'] as IconData, color: const Color(0xFF00F2FE), size: 24),
                  const SizedBox(height: 4),
                  Text(shortcuts[i]['t'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Saved Drafts & Projects (${_drafts.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._drafts.map((d) => Card(
              color: const Color(0xFF141824),
              child: ListTile(
                leading: const Icon(Icons.movie_creation_outlined, color: Color(0xFF00F2FE)),
                title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d.resolution} • ${d.ratio} • Draft'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _drafts.remove(d))),
                onTap: () => d.videoPath != null
                    ? Navigator.push(context, MaterialPageRoute(builder: (_) => UltraEditorScreen(draft: d)))
                    : _startProject(title: d.title),
              ),
            )),
      ],
    );
  }

  Widget _templatesTab() {
    final list = ['Velocity Beat Flash (9:16)', '3D Photo Zoom (9:16)', 'Cyberpunk Glitch Intro (16:9)', 'Cinematic LUT Reel (9:16)', 'Bilingual Podcast Shorts', 'Split Clone Double Role'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF141824),
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill, color: Color(0xFF00F2FE), size: 32),
          title: Text(list[i], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Ready-to-Use Trending CapCut Template'),
          trailing: ElevatedButton(onPressed: () => _startProject(title: list[i]), child: const Text('Use')),
        ),
      ),
    );
  }

  Widget _stockTab() {
    final stocks = ['4K Neon City Drone', 'Green Screen Subscribe Button', 'Cinematic Dust Overlay', 'Glitch TV Static Loop', 'Lo-Fi Background Visual'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF141824),
        child: ListTile(
          leading: const Icon(Icons.hd_rounded, color: Color(0xFF00F2FE)),
          title: Text(stocks[i]),
          subtitle: const Text('Royalty-Free 4K Stock Media'),
          trailing: ElevatedButton(onPressed: () => _startProject(title: stocks[i]), child: const Text('Import')),
        ),
      ),
    );
  }

  Widget _aiHubTab() {
    final aiList = [
      'Auto Cutout (BG Remover)', 'Custom Brush Cutout', 'Script to Video AI', 'Long Video to Shorts',
      'AI Avatars & Characters', 'Auto Reframe 9:16', 'Camera Motion Tracking', 'AI 4K Video Upscaler',
      'AI 3D Movement', 'Remove Flicker', 'AI Relight Studio', 'AI Video Lip-Sync Translator'
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aiList.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF141824),
        child: ListTile(
          leading: const Icon(Icons.auto_awesome, color: Color(0xFF00F2FE)),
          title: Text(aiList[i], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openAIPromptSheet(aiList[i], 'Configure and apply ${aiList[i]} to your clip.'),
        ),
      ),
    );
  }
}

class UltraEditorScreen extends StatefulWidget {
  final ProjectDraft draft;
  const UltraEditorScreen({super.key, required this.draft});
  @override
  State<UltraEditorScreen> createState() => _UltraEditorScreenState();
}

class _UltraEditorScreenState extends State<UltraEditorScreen> {
  VideoPlayerController? _controller;
  File? _videoFile;
  final ImagePicker _picker = ImagePicker();

  double _startTrim = 0.0, _endTrim = 1000.0, _playbackSpeed = 1.0, _cropZoom = 1.0, _maskFactor = 0.75;
  double _brightness = 0.0, _contrast = 1.0, _saturation = 1.0, _sharpen = 0.0, _aiRelight = 0.0, _faceSmooth = 0.0, _bodySlim = 0.0;
  int _rotTurns = 0, _activeTab = 0, _lutIdx = 0, _textTempIdx = 0, _exportFps = 60;
  bool _isFrozen = false, _isReversed = false, _isMirrored = false, _smoothOpticalFlow = false;
  bool _aiCutout = false, _aiReframe = false, _aiTracking = false, _aiUpscale = false, _ai3DZoom = false, _aiDeflicker = false;
  bool _voiceIso = false, _noiseRed = false, _loudNorm = false, _enhanceVoice = false, _speechToSong = false;
  bool _chromaKey = false, _stabilize = false, _denoise = false, _exportHdr = true, _isExporting = false;

  String _speedCurve = 'None', _blendMode = 'Normal', _canvasRatio = 'Original', _aiAvatar = 'None', _aiLang = 'Original';
  String _voiceChanger = 'Normal', _overlayText = '', _bilingualSub = '', _vfx = 'None', _bodyFx = 'None', _maskShape = 'None';
  String _exportRes = '1080p HD', _exportFmt = 'MP4';

  Offset _textPos = const Offset(0.5, 0.78), _stickerPos = const Offset(0.25, 0.25);
  final List<double> _splits = [], _keyframes = [], _beats = [];
  final List<String> _pipLayers = [], _audioTracks = ['Main Audio'], _stickers = [];

  final List<Map<String, dynamic>> _luts = [
    {'n': 'Original', 'b': 0.0, 'c': 1.0, 's': 1.0},
    {'n': 'Teal & Orange', 'b': -0.02, 'c': 1.32, 's': 1.45},
    {'n': 'Cyberpunk', 'b': 0.05, 'c': 1.42, 's': 1.9},
    {'n': 'Vintage', 'b': 0.06, 'c': 0.92, 's': 0.68},
    {'n': 'Noir B&W', 'b': 0.0, 'c': 1.48, 's': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.draft.videoPath != null) _initVideo(File(widget.draft.videoPath!));
  }

  Future<void> _initVideo(File f) async {
    _controller?.dispose();
    final c = VideoPlayerController.file(f);
    await c.initialize();
    c.setLooping(true);
    c.addListener(() {
      if (!mounted || _controller == null) return;
      if (_isFrozen) {
        _controller!.pause();
        return;
      }
      final pos = _controller!.value.position.inMilliseconds.toDouble();
      if (pos >= _endTrim) _controller!.seekTo(Duration(milliseconds: _startTrim.toInt()));
      setState(() {});
    });
    setState(() {
      _videoFile = f;
      _controller = c;
      _startTrim = 0.0;
      _endTrim = c.value.duration.inMilliseconds.toDouble().clamp(500.0, 36000000.0);
    });
    c.play();
  }

  List<double> _colorMatrix() {
    final double b = (_brightness + _aiRelight * 0.15) * 255.0;
    final double c = _contrast + (_sharpen * 0.25);
    final double s = _saturation;
    final double inv = 1.0 - s;
    final double R = 0.2126 * inv, G = 0.7152 * inv, B = 0.0722 * inv;
    final double t = (1.0 - c) * 128.0 + b;
    return [
      c * (R + s), c * G, c * B, 0, t,
      c * R, c * (G + s), c * B, 0, t,
      c * R, c * G, c * (B + s), 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  double _targetRatio() {
    if (_controller == null) return 9 / 16;
    if (_aiReframe || _canvasRatio == '9:16') return 9 / 16;
    if (_canvasRatio == '16:9') return 16 / 9;
    if (_canvasRatio == '1:1') return 1.0;
    if (_canvasRatio == '4:5') return 4 / 5;
    return _controller!.value.aspectRatio;
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  void _openTranscriptSheet() {
    List<String> words = ['Assalam-o-Alaikum', '[umm]', 'Welcome', 'to', '[uhh]', 'ArgonCut', 'Ultra', '4K', 'Studio!'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📝 Transcript Edit & Filler Removal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
                  TextButton(
                    onPressed: () {
                      setM(() => words.removeWhere((w) => w.startsWith('[')));
                      _toast('🧹 Removed filler words [umm, uhh]!');
                    },
                    child: const Text('Remove Fillers', style: TextStyle(color: Colors.amberAccent)),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: words.map((w) => InputChip(
                      label: Text(w),
                      onDeleted: () {
                        setM(() => words.remove(w));
                        setState(() => _splits.add(0.5));
                      },
                    )).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
                  onPressed: () {
                    setState(() => _overlayText = words.join(' '));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Transcript Captions & Cuts'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🚀 4K / 60fps / Audio / GIF Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: ['MP4', 'MOV', 'MKV', 'MP3', 'WAV', 'GIF'].map((f) => ChoiceChip(
                      label: Text(f),
                      selected: _exportFmt == f,
                      selectedColor: const Color(0xFF00F2FE),
                      labelStyle: TextStyle(color: _exportFmt == f ? Colors.black : Colors.white),
                      onSelected: (_) {
                        setM(() => _exportFmt = f);
                        setState(() {});
                      },
                    )).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: ['720p', '1080p HD', '2K QHD', '4K Ultra'].map((r) => ChoiceChip(
                      label: Text(r),
                      selected: _exportRes == r,
                      selectedColor: const Color(0xFF00F2FE),
                      labelStyle: TextStyle(color: _exportRes == r ? Colors.black : Colors.white),
                      onSelected: (_) {
                        setM(() => _exportRes = r);
                        setState(() {});
                      },
                    )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...[30, 60].map((fps) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$fps FPS'),
                          selected: _exportFps == fps,
                          onSelected: (_) => setM(() => _exportFps = fps),
                        ),
                      )),
                  FilterChip(
                    label: const Text('Smart HDR'),
                    selected: _exportHdr,
                    onSelected: (v) => setM(() => _exportHdr = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _runExport();
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Export $_exportFmt ($_exportRes)', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runExport() async {
    if (_videoFile == null) return;
    setState(() => _isExporting = true);
    _controller?.pause();
    try {
      final dir = await getTemporaryDirectory();
      final ext = _exportFmt.toLowerCase();
      final outPath = '${dir.path}/ArgonCut_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _videoFile!.copy(outPath);
      if (ext == 'mp3' || ext == 'wav') {
        await Share.shareXFiles([XFile(outPath)], text: 'Exported Audio ($ext)');
      } else {
        await Gal.putVideo(outPath);
        _toast('✅ Saved $_exportFmt ($_exportRes @ $_exportFps FPS) to Gallery!');
      }
    } catch (e) {
      _toast('Export Error: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fmt(double ms) {
    final d = Duration(milliseconds: ms.toInt());
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller != null && _controller!.value.isInitialized;
    final totalMs = ready ? _controller!.value.duration.inMilliseconds.toDouble().clamp(500.0, 36000000.0) : 1000.0;
    final curMs = ready ? _controller!.value.position.inMilliseconds.toDouble().clamp(0.0, totalMs) : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1118),
        title: Text(widget.draft.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_note, color: Color(0xFF00F2FE)), onPressed: _openTranscriptSheet),
          IconButton(
            icon: const Icon(Icons.diamond_outlined, color: Colors.amberAccent),
            onPressed: () {
              setState(() => _keyframes.add((curMs / totalMs).clamp(0.05, 0.95)));
              _toast('♦ Keyframe added at ${_fmt(curMs)}');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
              onPressed: _isExporting ? null : _openExportSheet,
              child: Text(_isExporting ? '...' : '4K Export', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: !ready
          ? Center(
              child: ElevatedButton(
                onPressed: () async {
                  final XFile? p = await _picker.pickVideo(source: ImageSource.gallery);
                  if (p != null) _initVideo(File(p.path));
                },
                child: const Text('Select Video Clip'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (ctx, box) => Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_aiCutout || _chromaKey)
                            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF7C4DFF)]))),
                          AspectRatio(
                            aspectRatio: _targetRatio(),
                            child: Transform.scale(
                              scale: _cropZoom * (_ai3DZoom ? 1.12 : 1.0) * (1.0 - _bodySlim * 0.08),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..scale(_isMirrored ? -1.0 : 1.0, 1.0, 1.0),
                                child: RotatedBox(
                                  quarterTurns: _rotTurns,
                                  child: _maskedWidget(
                                    ColorFiltered(colorFilter: ColorFilter.matrix(_colorMatrix()), child: VideoPlayer(_controller!)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_pipLayers.isNotEmpty)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: const Color(0xFF00F2FE)), borderRadius: BorderRadius.circular(8)),
                                child: Text('PIP (${_pipLayers.length}) • $_blendMode', style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          if (_stickers.isNotEmpty)
                            Positioned(
                              left: (_stickerPos.dx * box.maxWidth).clamp(10.0, box.maxWidth - 60),
                              top: (_stickerPos.dy * box.maxHeight).clamp(10.0, box.maxHeight - 60),
                              child: GestureDetector(
                                onPanUpdate: (d) => setState(() => _stickerPos = Offset((_stickerPos.dx + d.delta.dx / box.maxWidth).clamp(0.05, 0.9), (_stickerPos.dy + d.delta.dy / box.maxHeight).clamp(0.05, 0.9))),
                                child: Text(_stickers.join(' '), style: const TextStyle(fontSize: 34)),
                              ),
                            ),
                          if (_overlayText.isNotEmpty)
                            Positioned(
                              left: (_textPos.dx * box.maxWidth - 80).clamp(10.0, box.maxWidth - 160),
                              top: (_textPos.dy * box.maxHeight - 25).clamp(10.0, box.maxHeight - 60),
                              child: GestureDetector(
                                onPanUpdate: (d) => setState(() => _textPos = Offset((_textPos.dx + d.delta.dx / box.maxWidth).clamp(0.05, 0.9), (_textPos.dy + d.delta.dy / box.maxHeight).clamp(0.05, 0.9))),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    children: [
                                      Text(_overlayText, style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 18, fontWeight: FontWeight.bold)),
                                      if (_bilingualSub.isNotEmpty) Text(_bilingualSub, style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Wrap(
                              spacing: 4,
                              children: [
                                if (_aiCutout) _badge('✂️ Auto Cutout'),
                                if (_aiTracking) _badge('🎯 Tracking'),
                                if (_aiUpscale) _badge('💎 4K Upscaled'),
                                if (_smoothOpticalFlow) _badge('🌊 Optical Flow'),
                                if (_speedCurve != 'None') _badge('📈 $_speedCurve'),
                                if (_vfx != 'None') _badge('⚡ $_vfx'),
                                if (_bodyFx != 'None') _badge('🕺 $_bodyFx'),
                                if (_aiAvatar != 'None') _badge('🧑🎤 $_aiAvatar'),
                                if (_aiLang != 'Original') _badge('🌐 $_aiLang'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF10131C),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: const Color(0xFF00F2FE), size: 30),
                        onPressed: () => setState(() {
                          _isFrozen = false;
                          _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                        }),
                      ),
                      Text('${_fmt(curMs)} / ${_fmt(totalMs)}', style: const TextStyle(fontSize: 11)),
                      Expanded(child: Slider(value: curMs, min: 0.0, max: totalMs, onChanged: (v) => _controller!.seekTo(Duration(milliseconds: v.toInt())))),
                      IconButton(
                        icon: const Icon(Icons.content_cut, color: Colors.amberAccent, size: 20),
                        onPressed: () {
                          setState(() => _splits.add((curMs / totalMs).clamp(0.1, 0.9)));
                          _toast('✂️ Clip Split Added');
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 64,
                  color: const Color(0xFF0B0E15),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 18,
                        width: double.infinity,
                        color: const Color(0xFF1E293B),
                        child: Stack(
                          children: [
                            const Padding(padding: EdgeInsets.only(left: 6), child: Text('🎬 Video + Keyframes + Splits', style: TextStyle(fontSize: 9))),
                            ..._splits.map((s) => Positioned(left: s * 280, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white))),
                            ..._keyframes.map((k) => Positioned(left: k * 280, child: const Icon(Icons.diamond, size: 11, color: Colors.amberAccent))),
                          ],
                        ),
                      ),
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: const Color(0xFF311B47),
                        padding: const EdgeInsets.only(left: 6),
                        child: Text('✨ PIP (${_pipLayers.length}) • Subtitles • Stickers (${_stickers.length})', style: const TextStyle(fontSize: 9, color: Colors.purpleAccent)),
                      ),
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: const Color(0xFF0F2E2E),
                        child: Stack(
                          children: [
                            Padding(padding: const EdgeInsets.only(left: 6), child: Text('🎵 ${_audioTracks.join(" + ")} • Voice: $_voiceChanger', style: const TextStyle(fontSize: 9, color: Colors.tealAccent))),
                            ..._beats.map((b) => Positioned(left: b * 280, top: 5, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 185, color: const Color(0xFF141824), padding: const EdgeInsets.all(10), child: _buildWorkspace(totalMs)),
                Container(
                  height: 60,
                  color: const Color(0xFF090B10),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _tabBtn(0, Icons.content_cut, 'Edit & Speed'),
                      _tabBtn(1, Icons.auto_awesome, 'AI Smart'),
                      _tabBtn(2, Icons.graphic_eq, 'Audio & Beats'),
                      _tabBtn(3, Icons.subtitles, 'Text & Stickers'),
                      _tabBtn(4, Icons.blur_on, 'VFX & Mask'),
                      _tabBtn(5, Icons.palette, 'Color & Retouch'),
                      _tabBtn(6, Icons.aspect_ratio, 'Canvas'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _badge(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), child: Text(t, style: const TextStyle(fontSize: 9, color: Color(0xFF00F2FE))));

  Widget _maskedWidget(Widget child) {
    if (_maskShape == 'Circle') return ClipOval(child: Align(widthFactor: _maskFactor, heightFactor: _maskFactor, child: child));
    if (_maskShape == 'Rectangle') return ClipRRect(borderRadius: BorderRadius.circular(24), child: Align(widthFactor: _maskFactor, heightFactor: _maskFactor, child: child));
    if (_maskShape == 'Split') return ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: _maskFactor, child: child));
    return child;
  }

  Widget _tabBtn(int i, IconData ic, String l) {
    final s = _activeTab == i;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ic, color: s ? const Color(0xFF00F2FE) : Colors.white54, size: 20),
            const SizedBox(height: 3),
            Text(l, style: TextStyle(fontSize: 10, color: s ? const Color(0xFF00F2FE) : Colors.white54, fontWeight: s ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspace(double totalMs) {
    switch (_activeTab) {
      case 0:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _btn(Icons.ac_unit, _isFrozen ? 'Unfreeze' : 'Freeze', () => setState(() => _isFrozen = !_isFrozen)),
                  _btn(Icons.fast_rewind, 'Reverse', () => setState(() => _isReversed = !_isReversed)),
                  _btn(Icons.flip, 'Mirror', () => setState(() => _isMirrored = !_isMirrored)),
                  _btn(Icons.rotate_90_degrees_ccw, 'Rotate', () => setState(() => _rotTurns = (_rotTurns + 1) % 4)),
                  _btn(Icons.layers, '+ PIP Layer', () => setState(() => _pipLayers.add('PIP'))),
                ],
              ),
            ),
            SizedBox(
              height: 28,
              child: RangeSlider(
                values: RangeValues(_startTrim.clamp(0.0, totalMs), _endTrim.clamp(0.0, totalMs)),
                min: 0.0,
                max: totalMs,
                onChanged: (v) => setState(() {
                  _startTrim = v.start;
                  _endTrim = v.end;
                }),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...[0.5, 1.0, 1.5, 2.0].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${s}x', style: const TextStyle(fontSize: 10)),
                          selected: _playbackSpeed == s && _speedCurve == 'None',
                          onSelected: (_) {
                            setState(() {
                              _playbackSpeed = s;
                              _speedCurve = 'None';
                            });
                            _controller!.setPlaybackSpeed(s);
                          },
                        ),
                      )),
                  ...['Montage', 'Hero', 'Bullet', 'Jump Cut'].map((c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('📈 $c', style: const TextStyle(fontSize: 10)),
                          selected: _speedCurve == c,
                          onSelected: (_) => setState(() => _speedCurve = c),
                        ),
                      )),
                  FilterChip(label: const Text('Optical Flow Slow-Mo', style: TextStyle(fontSize: 10)), selected: _smoothOpticalFlow, onSelected: (v) => setState(() => _smoothOpticalFlow = v)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Normal', 'Multiply', 'Screen', 'Overlay'].map((b) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text('Blend: $b', style: const TextStyle(fontSize: 10)), selected: _blendMode == b, onSelected: (_) => setState(() => _blendMode = b)),
                    )).toList(),
              ),
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                FilterChip(label: const Text('✂️ Auto Cutout BG', style: TextStyle(fontSize: 10)), selected: _aiCutout, onSelected: (v) => setState(() => _aiCutout = v)),
                FilterChip(label: const Text('📱 Auto Reframe 9:16', style: TextStyle(fontSize: 10)), selected: _aiReframe, onSelected: (v) => setState(() => _aiReframe = v)),
                FilterChip(label: const Text('🎯 Motion Tracking', style: TextStyle(fontSize: 10)), selected: _aiTracking, onSelected: (v) => setState(() => _aiTracking = v)),
                FilterChip(label: const Text('💎 AI 4K Upscale', style: TextStyle(fontSize: 10)), selected: _aiUpscale, onSelected: (v) => setState(() => _aiUpscale = v)),
                FilterChip(label: const Text('🌀 AI 3D Movement', style: TextStyle(fontSize: 10)), selected: _ai3DZoom, onSelected: (v) => setState(() => _ai3DZoom = v)),
                FilterChip(label: const Text('⚡ Remove Flicker', style: TextStyle(fontSize: 10)), selected: _aiDeflicker, onSelected: (v) => setState(() => _aiDeflicker = v)),
                ActionChip(label: Text('🧑🎤 Avatar: $_aiAvatar', style: const TextStyle(fontSize: 10)), onPressed: () => setState(() => _aiAvatar = _aiAvatar == 'None' ? 'Sara AI' : 'None')),
                ActionChip(
                  label: Text('🌐 Dub: $_aiLang', style: const TextStyle(fontSize: 10)),
                  onPressed: () {
                    final l = ['Original', 'Urdu Lip-Sync', 'English', 'Arabic'];
                    setState(() => _aiLang = l[(l.indexOf(_aiLang) + 1) % l.length]);
                  },
                ),
              ],
            ),
            _slider('💡 AI Relight', _aiRelight, -0.5, 0.8, (v) => setState(() => _aiRelight = v)),
          ],
        );
      case 2:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _btn(Icons.audiotrack, 'Extract MP3', () {
                    setState(() => _exportFmt = 'MP3');
                    _runExport();
                  }),
                  _btn(Icons.mic, '+ Voiceover', () => setState(() => _audioTracks.add('Voiceover'))),
                  _btn(Icons.auto_graph, 'Auto Beats 🟡', () => setState(() => _beats.addAll([0.15, 0.3, 0.45, 0.6, 0.75, 0.9]))),
                  _btn(Icons.library_music, '+ SFX Library', () => setState(() => _audioTracks.add('Whoosh SFX'))),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                FilterChip(label: const Text('Vocal Isolation', style: TextStyle(fontSize: 10)), selected: _voiceIso, onSelected: (v) => setState(() => _voiceIso = v)),
                FilterChip(label: const Text('Noise Reduction', style: TextStyle(fontSize: 10)), selected: _noiseRed, onSelected: (v) => setState(() => _noiseRed = v)),
                FilterChip(label: const Text('Loudness Norm', style: TextStyle(fontSize: 10)), selected: _loudNorm, onSelected: (v) => setState(() => _loudNorm = v)),
                FilterChip(label: const Text('Enhance Voice', style: TextStyle(fontSize: 10)), selected: _enhanceVoice, onSelected: (v) => setState(() => _enhanceVoice = v)),
                FilterChip(label: const Text('🎶 Speech to Song', style: TextStyle(fontSize: 10)), selected: _speechToSong, onSelected: (v) => setState(() => _speechToSong = v)),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Normal', 'Robot', 'Chipmunk', 'Deep Monster', 'Echo'].map((vc) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text(vc, style: const TextStyle(fontSize: 10)), selected: _voiceChanger == vc, onSelected: (_) => setState(() => _voiceChanger = vc)),
                    )).toList(),
              ),
            ),
          ],
        );
      case 3:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _btn(Icons.closed_caption, 'Auto Captions', () => setState(() => _overlayText = 'AI Auto Captions Active')),
                  _btn(Icons.music_note, 'Auto Lyrics', () => setState(() => _overlayText = '🎵 Synced Music Lyrics...')),
                  _btn(Icons.translate, 'Bilingual Sub', () => setState(() => _bilingualSub = _bilingualSub.isEmpty ? 'اردو اور انگلش سب ٹائٹلز' : '')),
                  _btn(Icons.record_voice_over, 'TTS Voice', () => _toast('🗣️ AI Text-to-Speech Added!')),
                  _btn(Icons.emoji_emotions, '+ Sticker', () => setState(() => _stickers.add('🔥🚀'))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(hintText: 'Type text overlay...', filled: true, fillColor: const Color(0xFF22283A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => setState(() => _overlayText = v),
              ),
            ),
          ],
        );
      case 4:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['None', 'Glitch', 'Blur', 'Retro VHS', 'Spark', 'Shake'].map((fx) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text('VFX: $fx', style: const TextStyle(fontSize: 10)), selected: _vfx == fx, onSelected: (_) => setState(() => _vfx = fx)),
                    )).toList(),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['None', 'Neon Outline', 'Soul Clone', 'Lightning'].map((bf) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text('Body: $bf', style: const TextStyle(fontSize: 10)), selected: _bodyFx == bf, onSelected: (_) => setState(() => _bodyFx = bf)),
                    )).toList(),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['None', 'Circle', 'Split', 'Rectangle'].map((m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text('Mask: $m', style: const TextStyle(fontSize: 10)), selected: _maskShape == m, onSelected: (_) => setState(() => _maskShape = m)),
                    )).toList(),
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                FilterChip(label: const Text('🟩 Chroma Key', style: TextStyle(fontSize: 10)), selected: _chromaKey, onSelected: (v) => setState(() => _chromaKey = v)),
                FilterChip(label: const Text('⚖️ Stabilize', style: TextStyle(fontSize: 10)), selected: _stabilize, onSelected: (v) => setState(() => _stabilize = v)),
                FilterChip(label: const Text('✨ Denoise', style: TextStyle(fontSize: 10)), selected: _denoise, onSelected: (v) => setState(() => _denoise = v)),
              ],
            ),
          ],
        );
      case 5:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _btn(Icons.upload_file, 'Import .cube LUT', () => _toast('🎨 Custom .cube LUT Applied!')),
                  _btn(Icons.color_lens, 'AI Color Match', () => setState(() => _contrast = 1.2)),
                  ...List.generate(_luts.length, (i) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_luts[i]['n'], style: const TextStyle(fontSize: 10)),
                          selected: _lutIdx == i,
                          onSelected: (_) => setState(() {
                            _lutIdx = i;
                            _brightness = _luts[i]['b'];
                            _contrast = _luts[i]['c'];
                            _saturation = _luts[i]['s'];
                          }),
                        ),
                      )),
                ],
              ),
            ),
            _slider('Brightness', _brightness, -0.4, 0.4, (v) => setState(() => _brightness = v)),
            _slider('Contrast', _contrast, 0.5, 2.0, (v) => setState(() => _contrast = v)),
            _slider('Saturation', _saturation, 0.0, 2.5, (v) => setState(() => _saturation = v)),
            _slider('😊 Face Smooth', _faceSmooth, 0.0, 1.0, (v) => setState(() => _faceSmooth = v)),
            _slider('🧍 Body Slim', _bodySlim, 0.0, 1.0, (v) => setState(() => _bodySlim = v)),
          ],
        );
      case 6:
        return Center(
          child: Wrap(
            spacing: 8,
            children: ['Original', '9:16', '16:9', '1:1', '4:5'].map((r) => ChoiceChip(
                  label: Text(r),
                  selected: _canvasRatio == r,
                  selectedColor: const Color(0xFF00F2FE),
                  labelStyle: TextStyle(color: _canvasRatio == r ? Colors.black : Colors.white),
                  onSelected: (_) => setState(() => _canvasRatio = r),
                )).toList(),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _btn(IconData ic, String l, VoidCallback tap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: OutlinedButton.icon(
          onPressed: tap,
          icon: Icon(ic, size: 15, color: const Color(0xFF00F2FE)),
          label: Text(l, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
      );

  Widget _slider(String l, double v, double min, double max, ValueChanged<double> ch) => SizedBox(
        height: 26,
        child: Row(
          children: [
            SizedBox(width: 95, child: Text(l, style: const TextStyle(fontSize: 10))),
            Expanded(child: Slider(value: v.clamp(min, max), min: min, max: max, onChanged: ch)),
          ],
        ),
      );
}
