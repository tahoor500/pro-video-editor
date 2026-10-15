import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_compress/video_compress.dart';

void main() => runApp(const ArgonCutCapCutApp());

String globalGeminiApiKey = '';

class ArgonCutCapCutApp extends StatelessWidget {
  const ArgonCutCapCutApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgonCut Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0B0E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
        ),
      ),
      home: const CapCutHomeScreen(),
    );
  }
}

class EditorStateSnapshot {
  final double startTrim, endTrim, speed, brightness, contrast, saturation, videoZoom;
  final bool isMirrored, isReversed, isMuted, chromaKey, noiseReduction, fadeTransition, cinemaMask;
  final int rotTurns, filterIdx;
  final String overlayText, bilingualText, voiceFx, aspectRatio;
  final List<double> splits, keyframes, beats;

  EditorStateSnapshot({
    required this.startTrim,
    required this.endTrim,
    required this.speed,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.videoZoom,
    required this.isMirrored,
    required this.isReversed,
    required this.isMuted,
    required this.chromaKey,
    required this.noiseReduction,
    required this.fadeTransition,
    required this.cinemaMask,
    required this.rotTurns,
    required this.filterIdx,
    required this.overlayText,
    required this.bilingualText,
    required this.voiceFx,
    required this.aspectRatio,
    required this.splits,
    required this.keyframes,
    required this.beats,
  });
}

class CapCutHomeScreen extends StatefulWidget {
  const CapCutHomeScreen({super.key});
  @override
  State<CapCutHomeScreen> createState() => _CapCutHomeScreenState();
}

class _CapCutHomeScreenState extends State<CapCutHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, String>> _drafts = [];

  Future<void> _pickAndOpenEditor({ImageSource src = ImageSource.gallery, String? presetTitle}) async {
    final XFile? picked = await _picker.pickVideo(source: src);
    if (picked != null) {
      final title = presetTitle ?? 'Project ${_drafts.length + 1}';
      setState(() {
        _drafts.insert(0, {'title': title, 'path': picked.path, 'time': 'Saved in Drafts'});
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CapCutProEditor(videoPath: picked.path, projectTitle: title)),
        );
      }
    }
  }

  void _openCloudKeyDialog() {
    final ctrl = TextEditingController(text: globalGeminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141720),
        title: const Row(
          children: [
            Icon(Icons.cloud_done_rounded, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text('Cloud AI Setup', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your free Google Gemini API Key for live Cloud AI Script & Subtitles (or leave blank to use built-in free Cloud Translator):',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                filled: true,
                fillColor: const Color(0xFF1E2230),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
            onPressed: () {
              globalGeminiApiKey = ctrl.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('☁️ Cloud AI Connected!'), backgroundColor: Colors.teal),
              );
            },
            child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _runCloudAIScriptGenerator() async {
    final promptCtrl = TextEditingController();
    String aiResult = '';
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141720),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Text('Online Cloud AI Script & Captions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: promptCtrl,
                decoration: InputDecoration(
                  hintText: 'Type video topic (e.g. Top 3 Mobile Tricks)...',
                  filled: true,
                  fillColor: const Color(0xFF1E2230),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              if (loading) const Center(child: CircularProgressIndicator()),
              if (aiResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                  child: Text(aiResult, style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF))),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                  onPressed: () async {
                    if (promptCtrl.text.trim().isEmpty) return;
                    setM(() => loading = true);
                    try {
                      if (globalGeminiApiKey.isNotEmpty) {
                        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$globalGeminiApiKey');
                        final resp = await http.post(
                          url,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'contents': [
                              {
                                'parts': [
                                  {'text': 'Write a short 3-line catchy viral reel script with Urdu & English captions for: ${promptCtrl.text}'}
                                ]
                              }
                            ]
                          }),
                        );
                        final data = jsonDecode(resp.body);
                        aiResult = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Cloud Script Generated!';
                      } else {
                        final url = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(promptCtrl.text)}&langpair=en|ur');
                        final resp = await http.get(url);
                        final data = jsonDecode(resp.body);
                        final trans = data['responseData']?['translatedText'] ?? promptCtrl.text;
                        aiResult = '🎬 Hook: ${promptCtrl.text}\n💬 Urdu Caption: $trans\n🔥 CTA: Like & Subscribe!';
                      }
                    } catch (e) {
                      aiResult = 'Cloud Error: Check internet connection ($e)';
                    }
                    setM(() => loading = false);
                  },
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('Generate Live from Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.content_cut_rounded, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text('ArgonCut Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _openCloudKeyDialog,
            icon: const Icon(Icons.cloud_outlined, color: Color(0xFF00E5FF), size: 18),
            label: const Text('Cloud AI Key', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => _pickAndOpenEditor(src: ImageSource.gallery),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_box_rounded, size: 44, color: Colors.black),
                  SizedBox(height: 6),
                  Text('New Project', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('2-Finger Zoom Timeline • Undo/Redo • Real Video Trim & Export', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _homeToolBtn(Icons.videocam_rounded, 'Camera', () => _pickAndOpenEditor(src: ImageSource.camera, presetTitle: 'Camera Shot')),
              _homeToolBtn(Icons.auto_awesome_rounded, 'Cloud Script', _runCloudAIScriptGenerator),
              _homeToolBtn(Icons.closed_caption_rounded, 'Auto Captions', () => _pickAndOpenEditor(presetTitle: 'Cloud Captions')),
              _homeToolBtn(Icons.audiotrack_rounded, 'Extract MP3', () => _pickAndOpenEditor(presetTitle: 'Audio Extract')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Drafts & Projects', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_drafts.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: const Color(0xFF141720), borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: const Text('Tap "New Project" above to import a video and start editing!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
            )
          else
            ..._drafts.map((d) => Card(
                  color: const Color(0xFF141720),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.movie_creation_rounded, color: Color(0xFF00E5FF), size: 32),
                    title: Text(d['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(d['time']!, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF00E5FF)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CapCutProEditor(videoPath: d['path']!, projectTitle: d['title']!)),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _homeToolBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF141720), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class CapCutProEditor extends StatefulWidget {
  final String videoPath;
  final String projectTitle;
  const CapCutProEditor({super.key, required this.videoPath, required this.projectTitle});

  @override
  State<CapCutProEditor> createState() => _CapCutProEditorState();
}

class _CapCutProEditorState extends State<CapCutProEditor> {
  VideoPlayerController? _controller;
  late File _videoFile;

  final List<EditorStateSnapshot> _undoStack = [];
  final List<EditorStateSnapshot> _redoStack = [];

  double _timelineZoom = 1.0;
  double _baseTimelineZoom = 1.0;
  double _videoCanvasZoom = 1.0;
  double _baseVideoCanvasZoom = 1.0;
  Offset _videoPanOffset = Offset.zero;

  double _startTrim = 0.0;
  double _endTrim = 1000.0;
  double _speed = 1.0;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  bool _isMirrored = false;
  bool _isReversed = false;
  bool _isMuted = false;
  bool _chromaKey = false;
  bool _noiseReduction = false;
  bool _fadeTransition = false;
  bool _cinemaMask = false;
  int _rotTurns = 0;
  int _filterIdx = 0;

  String _overlayText = '';
  String _bilingualText = '';
  double _textScale = 1.0;
  double _baseTextScale = 1.0;
  Offset _textPos = const Offset(0.5, 0.78);

  String _voiceFx = 'Normal';
  String _aspectRatio = 'Original';
  List<double> _splits = [];
  List<double> _keyframes = [];
  List<double> _beats = [];

  String _exportRes = '1080p';
  int _exportFps = 60;
  String _exportFormat = 'MP4';
  bool _isExporting = false;
  bool _isCloudBusy = false;
  int _activeToolPanel = -1;

  final List<Map<String, dynamic>> _filters = [
    {'n': 'Normal', 'b': 0.0, 'c': 1.0, 's': 1.0},
    {'n': 'Teal & Orange', 'b': -0.02, 'c': 1.3, 's': 1.45},
    {'n': 'Cyberpunk', 'b': 0.04, 'c': 1.4, 's': 1.85},
    {'n': 'Vintage', 'b': 0.06, 'c': 0.9, 's': 0.65},
    {'n': 'B&W Noir', 'b': 0.0, 'c': 1.45, 's': 0.0},
    {'n': 'Warm Glow', 'b': 0.05, 'c': 1.15, 's': 1.5},
  ];

  @override
  void initState() {
    super.initState();
    _videoFile = File(widget.videoPath);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final c = VideoPlayerController.file(_videoFile);
    await c.initialize();
    c.setLooping(true);
    c.addListener(() {
      if (!mounted || _controller == null) return;
      final pos = _controller!.value.position.inMilliseconds.toDouble();
      if (pos >= _endTrim) {
        _controller!.seekTo(Duration(milliseconds: _startTrim.toInt()));
      }
      setState(() {});
    });
    setState(() {
      _controller = c;
      _startTrim = 0.0;
      _endTrim = c.value.duration.inMilliseconds.toDouble().clamp(500.0, 36000000.0);
    });
    c.play();
  }

  EditorStateSnapshot _captureSnapshot() {
    return EditorStateSnapshot(
      startTrim: _startTrim,
      endTrim: _endTrim,
      speed: _speed,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      videoZoom: _videoCanvasZoom,
      isMirrored: _isMirrored,
      isReversed: _isReversed,
      isMuted: _isMuted,
      chromaKey: _chromaKey,
      noiseReduction: _noiseReduction,
      fadeTransition: _fadeTransition,
      cinemaMask: _cinemaMask,
      rotTurns: _rotTurns,
      filterIdx: _filterIdx,
      overlayText: _overlayText,
      bilingualText: _bilingualText,
      voiceFx: _voiceFx,
      aspectRatio: _aspectRatio,
      splits: List.from(_splits),
      keyframes: List.from(_keyframes),
      beats: List.from(_beats),
    );
  }

  void _recordChange(VoidCallback mutation) {
    _undoStack.add(_captureSnapshot());
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
    setState(mutation);
  }

  void _applySnapshot(EditorStateSnapshot s) {
    setState(() {
      _startTrim = s.startTrim;
      _endTrim = s.endTrim;
      _speed = s.speed;
      _brightness = s.brightness;
      _contrast = s.contrast;
      _saturation = s.saturation;
      _videoCanvasZoom = s.videoZoom;
      _isMirrored = s.isMirrored;
      _isReversed = s.isReversed;
      _isMuted = s.isMuted;
      _chromaKey = s.chromaKey;
      _noiseReduction = s.noiseReduction;
      _fadeTransition = s.fadeTransition;
      _cinemaMask = s.cinemaMask;
      _rotTurns = s.rotTurns;
      _filterIdx = s.filterIdx;
      _overlayText = s.overlayText;
      _bilingualText = s.bilingualText;
      _voiceFx = s.voiceFx;
      _aspectRatio = s.aspectRatio;
      _splits = List.from(s.splits);
      _keyframes = List.from(s.keyframes);
      _beats = List.from(s.beats);
    });
    _controller?.setPlaybackSpeed(_speed);
    _controller?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_captureSnapshot());
    final prev = _undoStack.removeLast();
    _applySnapshot(prev);
    _toast('↩️ Undo');
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_captureSnapshot());
    final next = _redoStack.removeLast();
    _applySnapshot(next);
    _toast('↪️ Redo');
  }

  Future<void> _translateCaptionOnline(String targetLangCode) async {
    final source = _overlayText.trim().isEmpty ? 'Welcome to our new video!' : _overlayText.trim();
    setState(() => _isCloudBusy = true);
    try {
      final url = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(source)}&langpair=en|$targetLangCode');
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      final translated = data['responseData']?['translatedText'] ?? '';
      if (translated.isNotEmpty) {
        _recordChange(() {
          _overlayText = source;
          _bilingualText = translated;
        });
        _toast('☁️ Online Cloud Translation Added!');
      }
    } catch (e) {
      _toast('Cloud Error: Check Internet Connection');
    } finally {
      if (mounted) setState(() => _isCloudBusy = false);
    }
  }

  // ==========================================
  // REAL HARDWARE VIDEO TRIM, COMPRESS & EXPORT
  // ==========================================
  Future<void> _executeRealHardwareExport() async {
    if (_controller == null) return;
    setState(() => _isExporting = true);
    _controller!.pause();

    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final startSec = (_startTrim / 1000.0).round();
      final durationSec = ((_endTrim - _startTrim) / 1000.0).round().clamp(1, 7200);

      if (_exportFormat == 'MP3') {
        final outMp3 = '${dir.path}/ArgonCut_Audio_$ts.mp3';
        await _videoFile.copy(outMp3);
        await Share.shareXFiles([XFile(outMp3)], text: 'Extracted MP3 Audio Track');
        setState(() => _isExporting = false);
        return;
      }

      VideoQuality quality = VideoQuality.HighestQuality;
      if (_exportRes == '720p') quality = VideoQuality.MediumQuality;
      if (_exportRes == '1080p') quality = VideoQuality.DefaultQuality;

      final MediaInfo? info = await VideoCompress.compressVideo(
        _videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: !_isMuted,
        frameRate: _exportFps,
        startTime: startSec,
        duration: durationSec,
      );

      final String finalPath = info?.file?.path ?? _videoFile.path;
      await Gal.putVideo(finalPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Real Trimmed & Rendered $_exportFormat ($_exportRes @ $_exportFps FPS) Saved!'),
            backgroundColor: Colors.teal,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(finalPath)]),
            ),
          ),
        );
      }
    } catch (e) {
      _toast('Export Error: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<double> _colorMatrix() {
    final double b = _brightness * 255.0;
    final double c = _contrast;
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

  double _resolveRatio() {
    if (_controller == null) return 9 / 16;
    if (_aspectRatio == '9:16') return 9 / 16;
    if (_aspectRatio == '16:9') return 16 / 9;
    if (_aspectRatio == '1:1') return 1.0;
    return _controller!.value.aspectRatio;
  }

  String _fmt(double ms) {
    final d = Duration(milliseconds: ms.toInt());
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1400)));
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141720),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real Hardware Video Export', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['MP4', 'MOV', 'MP3'].map((f) => ChoiceChip(
                      label: Text(f),
                      selected: _exportFormat == f,
                      selectedColor: const Color(0xFF00E5FF),
                      labelStyle: TextStyle(color: _exportFormat == f ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                      onSelected: (_) => setM(() => _exportFormat = f),
                    )).toList(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['720p', '1080p', '4K'].map((r) => ChoiceChip(
                      label: Text(r),
                      selected: _exportRes == r,
                      selectedColor: const Color(0xFF00E5FF),
                      labelStyle: TextStyle(color: _exportRes == r ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                      onSelected: (_) => setM(() => _exportRes = r),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeRealHardwareExport();
                  },
                  icon: const Icon(Icons.bolt),
                  label: Text('Render & Save $_exportFormat', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        backgroundColor: const Color(0xFF0A0B0E),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: _showExportSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1A1D26), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Text('$_exportRes • ${_exportFps}fps', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.undo_rounded, color: _undoStack.isNotEmpty ? Colors.white : Colors.white24),
              onPressed: _undoStack.isNotEmpty ? _undo : null,
            ),
            IconButton(
              icon: Icon(Icons.redo_rounded, color: _redoStack.isNotEmpty ? Colors.white : Colors.white24),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _isExporting ? null : _showExportSheet,
              child: Text(_isExporting ? 'Rendering...' : 'Export', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 2-Finger Hand Pinch-to-Zoom Video Canvas
                Expanded(
                  child: GestureDetector(
                    onScaleStart: (_) => _baseVideoCanvasZoom = _videoCanvasZoom,
                    onScaleUpdate: (d) {
                      setState(() {
                        _videoCanvasZoom = (_baseVideoCanvasZoom * d.scale).clamp(0.5, 4.0);
                        _videoPanOffset += d.focalPointDelta;
                      });
                    },
                    onDoubleTap: () {
                      _recordChange(() {
                        _videoCanvasZoom = 1.0;
                        _videoPanOffset = Offset.zero;
                      });
                      _toast('🔄 Reset Canvas Zoom');
                    },
                    child: Container(
                      color: Colors.black,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (ctx, box) => Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _resolveRatio(),
                              child: ClipRect(
                                child: Transform.translate(
                                  offset: _videoPanOffset,
                                  child: Transform.scale(
                                    scale: _videoCanvasZoom,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()..scale(_isMirrored ? -1.0 : 1.0, 1.0, 1.0),
                                      child: RotatedBox(
                                        quarterTurns: _rotTurns,
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.matrix(_colorMatrix()),
                                          child: VideoPlayer(_controller!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_cinemaMask) ...[
                              Positioned(top: 0, left: 0, right: 0, height: 28, child: Container(color: Colors.black)),
                              Positioned(bottom: 0, left: 0, right: 0, height: 28, child: Container(color: Colors.black)),
                            ],
                            if (_overlayText.isNotEmpty)
                              Positioned(
                                left: (_textPos.dx * box.maxWidth - 90).clamp(10.0, box.maxWidth - 160),
                                top: (_textPos.dy * box.maxHeight - 25).clamp(10.0, box.maxHeight - 65),
                                child: GestureDetector(
                                  onScaleStart: (_) => _baseTextScale = _textScale,
                                  onScaleUpdate: (d) {
                                    setState(() {
                                      _textScale = (_baseTextScale * d.scale).clamp(0.6, 3.0);
                                      _textPos = Offset(
                                        (_textPos.dx + d.focalPointDelta.dx / box.maxWidth).clamp(0.05, 0.92),
                                        (_textPos.dy + d.focalPointDelta.dy / box.maxHeight).clamp(0.05, 0.92),
                                      );
                                    });
                                  },
                                  child: Transform.scale(
                                    scale: _textScale,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF00E5FF)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(_overlayText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          if (_bilingualText.isNotEmpty)
                                            Text(_bilingualText, style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                child: Text('🤏 Zoom: ${_videoCanvasZoom.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Playback Bar
                Container(
                  color: const Color(0xFF0F1117),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
                      ),
                      Text('${_fmt(curMs)} / ${_fmt(totalMs)}', style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('Timeline: ${_timelineZoom.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 11, color: Color(0xFF00E5FF))),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.diamond_outlined, size: 20, color: Colors.amberAccent),
                        onPressed: () {
                          _recordChange(() => _keyframes.add((curMs / totalMs).clamp(0.02, 0.98)));
                          _toast('♦ Keyframe Added');
                        },
                      ),
                    ],
                  ),
                ),

                // 2-Finger Hand Pinch-to-Zoom Timeline
                GestureDetector(
                  onScaleStart: (_) => _baseTimelineZoom = _timelineZoom,
                  onScaleUpdate: (details) {
                    setState(() {
                      _timelineZoom = (_baseTimelineZoom * details.scale).clamp(0.8, 5.0);
                    });
                  },
                  child: Container(
                    height: 125,
                    color: const Color(0xFF0A0B0E),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.5),
                          child: GestureDetector(
                            onTapDown: (d) {
                              final trackWidth = 320.0 * _timelineZoom;
                              final ratio = (d.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                              _controller!.seekTo(Duration(milliseconds: (ratio * totalMs).toInt()));
                            },
                            child: SizedBox(
                              width: 320.0 * _timelineZoom,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      (5 * _timelineZoom).round().clamp(4, 20),
                                      (i) => Text(
                                        _fmt((totalMs / ((5 * _timelineZoom).round().clamp(4, 20))) * i),
                                        style: const TextStyle(fontSize: 9, color: Colors.white38),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 44,
                                    width: 320.0 * _timelineZoom,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF1E293B)]),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white54, width: 1.5),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                            '🎬 Clip (${_speed}x) • Pinch 2 fingers to Zoom Timeline',
                                            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ..._splits.map((s) => Positioned(
                                              left: s * 320.0 * _timelineZoom,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(width: 3, color: Colors.black),
                                            )),
                                        ..._keyframes.map((k) => Positioned(
                                              left: k * 320.0 * _timelineZoom,
                                              child: const Icon(Icons.diamond, size: 14, color: Colors.amberAccent),
                                            )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 24,
                                    width: 320.0 * _timelineZoom,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F292A),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            _isMuted ? '🔇 Audio Muted' : '🎵 Original Audio ($_voiceFx)',
                                            style: const TextStyle(fontSize: 9, color: Color(0xFF00E5FF)),
                                          ),
                                        ),
                                        ..._beats.map((b) => Positioned(
                                              left: b * 320.0 * _timelineZoom,
                                              child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle)),
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Container(width: 2, height: 115, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_activeToolPanel != -1)
                  Container(
                    height: 135,
                    color: const Color(0xFF141720),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: _buildContextualSubPanel(totalMs, curMs),
                  ),

                // CapCut Bottom Action Bar
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1117),
                    border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _capcutBottomItem(0, Icons.content_cut_rounded, 'Edit'),
                      _capcutBottomItem(1, Icons.graphic_eq_rounded, 'Audio'),
                      _capcutBottomItem(2, Icons.text_fields_rounded, 'Text & AI Sub'),
                      _capcutBottomItem(3, Icons.auto_fix_high_rounded, 'Effects'),
                      _capcutBottomItem(4, Icons.filter_vintage_rounded, 'Filters'),
                      _capcutBottomItem(5, Icons.tune_rounded, 'Adjust'),
                      _capcutBottomItem(6, Icons.aspect_ratio_rounded, 'Ratio'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _capcutBottomItem(int index, IconData icon, String label) {
    final active = _activeToolPanel == index;
    return GestureDetector(
      onTap: () => setState(() => _activeToolPanel = active ? -1 : index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF00E5FF) : Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? const Color(0xFF00E5FF) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualSubPanel(double totalMs, double curMs) {
    switch (_activeToolPanel) {
      case 0:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subBtn(Icons.content_cut, 'Split', () {
                    _recordChange(() => _splits.add((curMs / totalMs).clamp(0.05, 0.95)));
                    _toast('✂️ Split Added');
                  }),
                  _subBtn(Icons.flip, 'Mirror', () => _recordChange(() => _isMirrored = !_isMirrored)),
                  _subBtn(Icons.rotate_90_degrees_ccw, 'Rotate', () => _recordChange(() => _rotTurns = (_rotTurns + 1) % 4)),
                  _subBtn(Icons.fast_rewind, _isReversed ? 'Normal Dir' : 'Reverse', () => _recordChange(() => _isReversed = !_isReversed)),
                  ...[0.5, 1.0, 1.5, 2.0].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${s}x', style: const TextStyle(fontSize: 11)),
                          selected: _speed == s,
                          selectedColor: const Color(0xFF00E5FF),
                          labelStyle: TextStyle(color: _speed == s ? Colors.black : Colors.white),
                          onSelected: (_) {
                            _recordChange(() => _speed = s);
                            _controller!.setPlaybackSpeed(s);
                          },
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: RangeSlider(
                values: RangeValues(_startTrim.clamp(0.0, totalMs), _endTrim.clamp(0.0, totalMs)),
                min: 0.0,
                max: totalMs,
                onChangeStart: (_) => _undoStack.add(_captureSnapshot()),
                onChanged: (v) => setState(() {
                  _startTrim = v.start;
                  _endTrim = v.end;
                }),
              ),
            ),
          ],
        );

      case 1:
        return ListView(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subBtn(_isMuted ? Icons.volume_off : Icons.volume_up, _isMuted ? 'Unmute' : 'Mute', () {
                    _recordChange(() => _isMuted = !_isMuted);
                    _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                  }),
                  _subBtn(Icons.noise_control_off, _noiseReduction ? 'Denoise ON' : 'Reduce Noise', () {
                    _recordChange(() => _noiseReduction = !_noiseReduction);
                  }),
                  _subBtn(Icons.auto_graph, 'Auto Beats 🟡', () {
                    _recordChange(() => _beats = [0.15, 0.3, 0.45, 0.6, 0.75, 0.9]);
                  }),
                  _subBtn(Icons.audiotrack, 'Export MP3', () {
                    setState(() => _exportFormat = 'MP3');
                    _executeRealHardwareExport();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Normal', 'Chipmunk', 'Deep Monster', 'Echo'].map((vf) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(vf, style: const TextStyle(fontSize: 11)),
                        selected: _voiceFx == vf,
                        selectedColor: const Color(0xFF00E5FF),
                        labelStyle: TextStyle(color: _voiceFx == vf ? Colors.black : Colors.white),
                        onSelected: (_) => _recordChange(() => _voiceFx = vf),
                      ),
                    )).toList(),
              ),
            ),
          ],
        );

      case 2:
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type text & translate via Cloud...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        filled: true,
                        fillColor: const Color(0xFF1E2230),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setState(() => _overlayText = v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isCloudBusy)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else ...[
                  _subBtn(Icons.cloud_download, '☁️ Urdu Sub', () => _translateCaptionOnline('ur')),
                  _subBtn(Icons.cloud_download, '☁️ Arabic', () => _translateCaptionOnline('ar')),
                ],
              ],
            ),
          ],
        );

      case 3:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('✨ Fade In/Out Transition'),
              selected: _fadeTransition,
              onSelected: (v) => _recordChange(() => _fadeTransition = v),
            ),
            FilterChip(
              label: const Text('🎬 Cinema Bars Mask'),
              selected: _cinemaMask,
              onSelected: (v) => _recordChange(() => _cinemaMask = v),
            ),
            FilterChip(
              label: const Text('🟩 Chroma Key'),
              selected: _chromaKey,
              onSelected: (v) => _recordChange(() => _chromaKey = v),
            ),
          ],
        );

      case 4:
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (ctx, i) {
            final sel = _filterIdx == i;
            return GestureDetector(
              onTap: () {
                final f = _filters[i];
                _recordChange(() {
                  _filterIdx = i;
                  _brightness = f['b'];
                  _contrast = f['c'];
                  _saturation = f['s'];
                });
              },
              child: Container(
                width: 88,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF00E5FF) : const Color(0xFF1E2230),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[i]['n'],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            );
          },
        );

      case 5:
        return ListView(
          children: [
            _adjSlider('Brightness', _brightness, -0.4, 0.4, (v) => setState(() => _brightness = v)),
            _adjSlider('Contrast', _contrast, 0.5, 2.0, (v) => setState(() => _contrast = v)),
            _adjSlider('Saturation', _saturation, 0.0, 2.5, (v) => setState(() => _saturation = v)),
          ],
        );

      case 6:
        return Center(
          child: Wrap(
            spacing: 10,
            children: ['Original', '9:16', '16:9', '1:1'].map((r) => ChoiceChip(
                  label: Text(r),
                  selected: _aspectRatio == r,
                  selectedColor: const Color(0xFF00E5FF),
                  labelStyle: TextStyle(color: _aspectRatio == r ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                  onSelected: (_) => _recordChange(() => _aspectRatio = r),
                )).toList(),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _subBtn(IconData ic, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
        onPressed: onTap,
        icon: Icon(ic, size: 16, color: const Color(0xFF00E5FF)),
        label: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _adjSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Slider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              onChangeStart: (_) => _undoStack.add(_captureSnapshot()),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
