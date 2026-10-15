import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const ArgonCutUltraApp());
}

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

// ==========================================
// 1. PROJECT / DRAFT MODEL & HOME DASHBOARD
// ==========================================
class ProjectDraft {
  String id;
  String title;
  String? videoPath;
  DateTime updatedAt;
  String resolution;
  String ratio;

  ProjectDraft({
    required this.id,
    required this.title,
    this.videoPath,
    required this.updatedAt,
    this.resolution = '1080p',
    this.ratio = '9:16',
  });
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _bottomNavIndex = 0; // 0: Edit & Drafts, 1: Templates, 2: Stock Media, 3: AI Hub
  final ImagePicker _picker = ImagePicker();

  final List<ProjectDraft> _drafts = [
    ProjectDraft(
      id: 'draft_1',
      title: 'Cinematic Vlog Reel #1',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      resolution: '4K HDR',
      ratio: '9:16',
    ),
    ProjectDraft(
      id: 'draft_2',
      title: 'YouTube Tech Intro',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      resolution: '1080p 60fps',
      ratio: '16:9',
    ),
  ];

  Future<void> _createNewProject({ImageSource source = ImageSource.gallery, String? presetTitle}) async {
    final XFile? picked = await _picker.pickVideo(source: source);
    if (picked != null) {
      final newDraft = ProjectDraft(
        id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
        title: presetTitle ?? 'Project ${_drafts.length + 1}',
        videoPath: picked.path,
        updatedAt: DateTime.now(),
      );
      setState(() => _drafts.insert(0, newDraft));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UltraEditorScreen(draft: newDraft)),
        ).then((_) => setState(() {}));
      }
    }
  }

  void _openQuickAIModal(String title, String desc, IconData icon) {
    final TextEditingController promptCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00F2FE), size: 28),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: promptCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'یہاں اپنا موضوع، اسکرپٹ یا ہدایت لکھیں...',
                filled: true,
                fillColor: const Color(0xFF1C202E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✨ $title ready! Select a base video clip to open in timeline.')),
                  );
                  _createNewProject(presetTitle: '$title Project');
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate & Open in Studio', style: TextStyle(fontWeight: FontWeight.bold)),
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
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFF00F2FE), size: 28),
            SizedBox(width: 6),
            Text('ArgonCut Ultra', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text('PRO UNLOCKED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
          ),
        ],
      ),
      body: _buildSelectedHomeBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        backgroundColor: const Color(0xFF0D0F16),
        selectedItemColor: const Color(0xFF00F2FE),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _bottomNavIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.VideoLibrary_rounded), label: 'Edit & Drafts'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_rounded), label: 'Templates'),
          BottomNavigationBarItem(icon: Icon(Icons.perm_media_rounded), label: 'Stock Media'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Studio'),
        ],
      ),
    );
  }

  Widget _buildSelectedHomeBody() {
    switch (_bottomNavIndex) {
      case 1:
        return _buildTemplatesView();
      case 2:
        return _buildStockLibraryView();
      case 3:
        return _buildAIStudioHubView();
      default:
        return _buildMainDraftsHome();
    }
  }

  Widget _buildMainDraftsHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big New Project Hero Banner
        GestureDetector(
          onTap: () => _createNewProject(source: ImageSource.gallery),
          child: Container(
            height: 135,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: const Color(0xFF00F2FE).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, size: 46, color: Colors.black),
                SizedBox(height: 8),
                Text('New Project', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Multi-Layer Timeline • 4K 60fps • AI Cutout', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Quick Action Grid (CapCut Shortcuts)
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            _quickShortcut(Icons.auto_fix_high, 'Auto Cutout', () => _createNewProject(presetTitle: 'Auto BG Cutout')),
            _quickShortcut(Icons.description_outlined, 'Script to Vid', () => _openQuickAIModal('AI Script to Video', 'Generate full video script, scenes & voiceover from a prompt.', Icons.description)),
            _quickShortcut(Icons.bolt, 'Long to Short', () => _openQuickAIModal('Long Video to Viral Shorts', 'AI detects best highlights & auto-reframes to 9:16.', Icons.bolt)),
            _quickShortcut(Icons.subtitles_outlined, 'Auto Captions', () => _createNewProject(presetTitle: 'Auto Captions')),
            _quickShortcut(Icons.videocam_outlined, 'Camera Rec', () => _createNewProject(source: ImageSource.camera, presetTitle: 'Camera Recording')),
            _quickShortcut(Icons.edit_note_rounded, 'Transcript Edit', () => _openQuickAIModal('Transcript-Based Editing', 'Edit video like a Word document—delete words to cut clips.', Icons.edit_note)),
            _quickShortcut(Icons.hd_outlined, 'AI Upscaler', () => _createNewProject(presetTitle: '4K AI Upscaled')),
            _quickShortcut(Icons.translate_rounded, 'AI Translator', () => _openQuickAIModal('AI Video Lip-Sync Translator', 'Translate spoken audio into Urdu, English, Arabic, Hindi with lip-sync.', Icons.translate)),
          ],
        ),
        const SizedBox(height: 22),

        // Drafts & Projects Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Drafts & Projects (${_drafts.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _createNewProject(),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18, color: Color(0xFF00F2FE)),
              label: const Text('Import', style: TextStyle(color: Color(0xFF00F2FE))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._drafts.map((d) => Card(
              color: const Color(0xFF141824),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22283A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.movie_creation_outlined, color: Color(0xFF00F2FE)),
                ),
                title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d.resolution} •${d.ratio} • Saved in Drafts', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54),
                      onPressed: () => setState(() => _drafts.remove(d)),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF00F2FE)),
                  ],
                ),
                onTap: () {
                  if (d.videoPath != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UltraEditorScreen(draft: d)));
                  } else {
                    _createNewProject(presetTitle: d.title);
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget _quickShortcut(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141824),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00F2FE), size: 26),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesView() {
    final templates = [
      {'title': 'Velocity Beat Flash', 'tag': 'Trending Reel • 9:16', 'clips': '6 Clips'},
      {'title': '3D Photo Zoom Montage', 'tag': 'AI Movement • 9:16', 'clips': '8 Photos'},
      {'title': 'Cyberpunk Glitch Intro', 'tag': 'YouTube 4K • 16:9', 'clips': '3 Clips'},
      {'title': 'Cinematic TravelLUT', 'tag': 'Color Graded • 9:16', 'clips': '10 Clips'},
      {'title': 'Bilingual Podcast Shorts', 'tag': 'Auto Captions • 9:16', 'clips': '1 Clip'},
      {'title': 'Split Clone Double Role', 'tag': 'Masking Pro • 16:9', 'clips': '2 Clips'},
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: templates.length,
      itemBuilder: (ctx, i) {
        final t = templates[i];
        return GestureDetector(
          onTap: () => _createNewProject(presetTitle: t['title']),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1B2234), const Color(0xFF0F131D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(t['clips']!, style: const TextStyle(fontSize: 10, color: Color(0xFF00F2FE))),
                  ),
                ),
                const Center(child: Icon(Icons.play_circle_fill_rounded, size: 48, color: Color(0xFF00F2FE))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t['tag']!, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockLibraryView() {
    final stocks = [
      '4K Neon City Drone Aerial',
      'Green Screen Subscribe & Bell Animation',
      'Cinematic Dust & Light Leaks Overlay',
      'Counting Timer 3-2-1 Transition Clip',
      'Lo-Fi Chill Background Loop Visual',
      'Glitch Static TV Noise Overlay',
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF141824),
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Icon(Icons.hd_rounded, color: Color(0xFF00F2FE), size: 32),
          title: Text(stocks[i], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Royalty-Free 4K Stock Media • Ready to Layer'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
            onPressed: () => _createNewProject(presetTitle: stocks[i]),
            child: const Text('Use'),
          ),
        ),
      ),
    );
  }

  Widget _buildAIStudioHubView() {
    final aiTools = [
      {'name': 'Auto Cutout (BG Remover)', 'desc': 'Remove background without green screen in 1 click'},
      {'name': 'Custom Brush Cutout', 'desc': 'Paint over any object to isolate or erase it'},
      {'name': 'Script to Video Generator', 'desc': 'Write a prompt and generate script + scenes'},
      {'name': 'Long Video to Shorts (Auto-Clip)', 'desc': 'Extract viral 9:16 highlights automatically'},
      {'name': 'AI Avatars & Digital Presenters', 'desc': 'Add realistic talking AI characters to your video'},
      {'name': 'Auto Reframe (Subject Tracking)', 'desc': 'Convert 16:9 landscape to 9:16 keeping subject centered'},
      {'name': 'Camera Motion Tracking', 'desc': 'Pin text, stickers, or blur to moving faces/objects'},
      {'name': 'AI 4K Video Upscaler', 'desc': 'Enhance low-res blurry videos to crisp Ultra HD'},
      {'name': 'AI Relight (Virtual Studio Light)', 'desc': 'Add directional neon or warm key lights after shooting'},
      {'name': 'AI Video Lip-Sync Translator', 'desc': 'Translate spoken language with natural lip synchronization'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aiTools.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF141824),
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF22283A),
            child: Icon(Icons.auto_awesome, color: Color(0xFF00F2FE)),
          ),
          title: Text(aiTools[i]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(aiTools[i]['desc']!, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF00F2FE)),
          onTap: () => _openQuickAIModal(aiTools[i]['name']!, aiTools[i]['desc']!, Icons.auto_awesome),
        ),
      ),
    );
  }
}

// =========================================================
// 2. ULTRA EDITOR SCREEN (ALL 60+ CAPCUT PRO FEATURES)
// =========================================================
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

  // Basic Editing & Multi-Layer Timeline
  double _startTrim = 0.0;
  double _endTrim = 1000.0;
  List<double> _splitPoints = [];
  List<double> _keyframes = [];
  List<double> _beatMarkers = [];
  bool _isFrozen = false;
  bool _isReversed = false;
  bool _isMirrored = false;
  int _rotationQuarterTurns = 0;
  double _cropZoom = 1.0;
  String _canvasRatio = 'Original';
  String _blendMode = 'Normal'; // Normal, Multiply, Screen, Overlay
  List<String> _pipLayers = [];
  List<String> _audioLayers = ['Original Video Audio'];

  // Speed (Normal + Curve + Smooth Optical Flow)
  double _playbackSpeed = 1.0;
  String _speedCurve = 'None'; // None, Montage, Hero, Bullet, Jump Cut, Flash In
  bool _smoothSlowMoOpticalFlow = false;

  // AI & Smart Features State
  bool _aiAutoCutout = false;
  bool _aiCustomBrushCutout = false;
  bool _aiAutoReframe = false;
  bool _aiMotionTracking = false;
  bool _aiUpscale4K = false;
  bool _ai3DZoomMovement = false;
  bool _aiRemoveFlicker = false;
  double _aiRelightWarmth = 0.0;
  String _aiAvatar = 'None';
  String _aiTranslatedLang = 'Original';

  // Audio & Sound Tools State
  bool _isMuted = false;
  bool _voiceIsolation = false;
  bool _noiseReduction = false;
  bool _loudnessNormalize = false;
  bool _enhanceVoiceStudio = false;
  bool _speechToSong = false;
  bool _isRecordingVoiceover = false;
  String _voiceChanger = 'Normal'; // Normal, Robot, Chipmunk, Deep Monster, Echo, Helium

  // Text, Captions, Lyrics & Stickers
  String _overlayText = '';
  String _bilingualSecondLine = '';
  int _selectedTextTemplate = 0;
  String _selectedTextAnimation = 'None'; // None, Typewriter, Bounce, Glitch, FadePop
  String _selectedFontFamily = 'Default';
  double _textScale = 1.0;
  Offset _textPos = const Offset(0.5, 0.78);
  List<String> _activeStickers = [];
  Offset _stickerPos = const Offset(0.25, 0.25);

  // Visual Effects (VFX), Filters, Masking & Transitions
  String _videoEffect = 'None'; // None, Glitch, Blur, Retro VHS, Spark, Camera Shake
  String _bodyEffect = 'None';  // None, Neon Outline, Soul Clone, Electric Lightning
  String _transition = 'None';  // None, Fade Black, Flash White, Spin Zoom, Glitch Cut
  String _clipAnimation = 'None'; // None, In: Zoom, Out: Slide, Combo: Pendulum
  String _maskShape = 'None';   // None, Circle, Split, Rectangle, Cinema Bars, Custom Pen
  double _maskFactor = 0.75;
  bool _chromaKey = false;
  bool _videoStabilization = false;
  bool _denoiseGrain = false;
  double _motionBlur = 0.0;

  // Color Grading, HSL, Curves & Face/Body Retouch
  int _selectedLutIndex = 0;
  String? _customCubeLutName;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _exposure = 0.0;
  double _sharpen = 0.0;
  double _highlights = 0.0;
  int _activeHslColorIndex = 0; // Red, Orange, Yellow, Green, Blue, Purple
  final List<double> _hslHueShift = [0, 0, 0, 0, 0, 0];
  bool _aiColorMatch = false;
  double _faceSmooth = 0.0;
  double _teethWhiten = 0.0;
  double _bodySlim = 0.0;

  // Export Settings
  String _exportRes = '1080p (Full HD)';
  int _exportFps = 60;
  bool _exportHdr = true;
  String _exportFormat = 'MP4'; // MP4, MOV, MKV, MP3, WAV, GIF
  bool _isExporting = false;

  int _activeCategoryTab = 0;

  final List<Map<String, dynamic>> _luts = [
    {'name': 'Original', 'b': 0.0, 'c': 1.0, 's': 1.0},
    {'name': 'Teal & Orange', 'b': -0.02, 'c': 1.32, 's': 1.45},
    {'name': 'Cyberpunk Neon', 'b': 0.05, 'c': 1.42, 's': 1.9},
    {'name': 'Vintage Kodak', 'b': 0.06, 'c': 0.92, 's': 0.68},
    {'name': 'Moody Matte', 'b': -0.07, 'c': 1.35, 's': 0.72},
    {'name': 'Noir B&W', 'b': 0.0, 'c': 1.48, 's': 0.0},
    {'name': 'Golden Sunset', 'b': 0.05, 'c': 1.18, 's': 1.6},
  ];

  final List<Map<String, dynamic>> _textTemplates = [
    {'name': 'Classic Shadow', 'color': Colors.white, 'bg': Colors.transparent},
    {'name': 'Vlog Yellow', 'color': Colors.yellowAccent, 'bg': Colors.black87},
    {'name': 'Neon Cyber', 'color': const Color(0xFF00F2FE), 'bg': Colors.black54},
    {'name': 'YouTube Subscribe', 'color': Colors.white, 'bg': const Color(0xFFE50914)},
    {'name': 'Breaking Lower 3rd', 'color': Colors.white, 'bg': const Color(0xFF0D47A1)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.draft.videoPath != null) {
      _loadVideoFile(File(widget.draft.videoPath!));
    }
  }

  Future<void> _loadVideoFile(File file) async {
    _controller?.dispose();
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.addListener(_onVideoTick);
    setState(() {
      _videoFile = file;
      _controller = ctrl;
      _startTrim = 0.0;
      _endTrim = ctrl.value.duration.inMilliseconds.toDouble().clamp(500.0, 36000000.0);
    });
    ctrl.play();
  }

  void _onVideoTick() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isFrozen) {
      _controller!.pause();
      return;
    }
    final pos = _controller!.value.position.inMilliseconds.toDouble();
    if (pos >= _endTrim) {
      _controller!.seekTo(Duration(milliseconds: _startTrim.toInt()));
    }
    if (mounted) setState(() {});
  }

  List<double> _buildColorMatrix() {
    final double b = (_brightness + _exposure * 0.5 + _aiRelightWarmth * 0.15) * 255.0;
    final double c = _contrast + (_sharpen * 0.25);
    final double s = _saturation;
    final double invSat = 1.0 - s;
    final double R = 0.2126 * invSat;
    final double G = 0.7152 * invSat;
    final double B = 0.0722 * invSat;
    final double t = (1.0 - c) * 128.0 + b;

    return [
      c * (R + s) + (_aiRelightWarmth * 0.2), c * G, c * B, 0, t,
      c * R, c * (G + s), c * B, 0, t,
      c * R, c * G, c * (B + s) - (_aiRelightWarmth * 0.15), 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  double _resolveAspectRatio() {
    if (_controller == null) return 9 / 16;
    if (_aiAutoReframe) return 9 / 16;
    switch (_canvasRatio) {
      case '9:16 (TikTok)':
        return 9 / 16;
      case '16:9 (YouTube)':
        return 16 / 9;
      case '1:1 (Insta)':
        return 1.0;
      case '4:5 (Portrait)':
        return 4 / 5;
      default:
        return _controller!.value.aspectRatio;
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A2130),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openTranscriptEditorModal() {
    List<String> words = [
      'Assalam-o-Alaikum', 'dosto!', '[umm]', 'Aaj', 'hum', 'ArgonCut', 'Ultra',
      'mein', '[uhh]', '4K', 'AI', 'video', 'editing', 'seekhenge.'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📝 Transcript-Based Editing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
                  TextButton.icon(
                    onPressed: () {
                      setModal(() => words.removeWhere((w) => w.startsWith('[')));
                      _showToast('🧹 Removed filler words ("umm", "uhh") & synced cuts!');
                    },
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.amberAccent),
                    label: const Text('Remove Fillers', style: TextStyle(color: Colors.amberAccent)),
                  ),
                ],
              ),
              const Text('Tap any word to delete it and automatically cut that video segment:', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: words.map((w) {
                  final isFiller = w.startsWith('[');
                  return InputChip(
                    label: Text(w),
                    backgroundColor: isFiller ? Colors.redAccent.withOpacity(0.25) : const Color(0xFF22283A),
                    onDeleted: () {
                      setModal(() => words.remove(w));
                      setState(() => _splitPoints.add(0.45));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
                  onPressed: () {
                    setState(() => _overlayText = words.join(' '));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Transcript Cuts & Subtitles', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ultra Export Studio (4K / HDR / Audio)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
                  Icon(Icons.high_quality_rounded, color: Color(0xFF00F2FE)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Export Format:', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['MP4', 'MOV', 'MKV', 'MP3 (Audio)', 'WAV (Lossless)', 'GIF'].map((f) {
                  final sel = _exportFormat == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    selectedColor: const Color(0xFF00F2FE),
                    labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    onSelected: (_) {
                      setModal(() => _exportFormat = f);
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              if (!_exportFormat.contains('MP3') && !_exportFormat.contains('WAV')) ...[
                const SizedBox(height: 12),
                const Text('Resolution & Bitrate:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['720p', '1080p (Full HD)', '2K QHD', '4K (Ultra HD)'].map((r) {
                    final sel = _exportRes == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: sel,
                      selectedColor: const Color(0xFF00F2FE),
                      labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      onSelected: (_) {
                        setModal(() => _exportRes = r);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [24, 30, 60].map((fps) {
                        final sel = _exportFps == fps;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$fps FPS'),
                            selected: sel,
                            selectedColor: const Color(0xFF00F2FE),
                            labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 11),
                            onSelected: (_) => setModal(() => _exportFps = fps),
                          ),
                        );
                      }).toList(),
                    ),
                    FilterChip(
                      label: const Text('Smart HDR', style: TextStyle(fontSize: 11)),
                      selected: _exportHdr,
                      selectedColor: Colors.amberAccent,
                      labelStyle: TextStyle(color: _exportHdr ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                      onSelected: (v) => setModal(() => _exportHdr
