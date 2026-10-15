import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const ArgonCutProApp());
}

class ArgonCutProApp extends StatelessWidget {
  const ArgonCutProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgonCut Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF4FACFE),
        ),
      ),
      home: const CapCutEditorScreen(),
    );
  }
}

class TextTemplate {
  final String name;
  final TextStyle style;
  final Color bgColor;
  final Color borderColor;
  final double borderRadius;

  const TextTemplate({
    required this.name,
    required this.style,
    this.bgColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.borderRadius = 8.0,
  });
}

class CapCutEditorScreen extends StatefulWidget {
  const CapCutEditorScreen({super.key});

  @override
  State<CapCutEditorScreen> createState() => _CapCutEditorScreenState();
}

class _CapCutEditorScreenState extends State<CapCutEditorScreen> {
  VideoPlayerController? _controller;
  File? _videoFile;
  final ImagePicker _picker = ImagePicker();

  // Timeline & Trim
  double _startTrim = 0.0;
  double _endTrim = 1.0;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  bool _isReversed = false;
  bool _isMirrored = false;

  // Color & Adjustments
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _vignette = 0.0;
  int _selectedFilterIndex = 0;

  // CapCut Advanced Features
  String _selectedTransition = 'None'; // None, Fade In/Out, Flash White, Flash Black, Zoom In
  String _selectedMask = 'None';       // None, Circle, Rectangle, Cinema Bars, Split Top/Bottom
  double _maskSize = 0.75;
  bool _chromaKeyGreen = false;
  String _voiceEffect = 'Normal';      // Normal, Chipmunk, Deep Monster, Robot Echo
  String _canvasRatio = 'Original';    // Original, 9:16 (TikTok), 16:9 (YouTube), 1:1 (Insta)

  // Text & Templates (Draggable on Video)
  String _overlayText = '';
  int _selectedTextTemplate = 0;
  double _textScale = 1.0;
  Offset _textPosition = const Offset(0.5, 0.8); // Normalized 0.0 - 1.0

  // Export Settings
  String _exportResolution = '1080p'; // 720p, 1080p, 4K
  int _exportFps = 30;                // 30, 60
  String _exportFormat = 'MP4';       // MP4, MOV, MKV, MP3 (Audio Only), GIF
  bool _isExporting = false;

  int _activeTab = 0;

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'b': 0.0, 'c': 1.0, 's': 1.0},
    {'name': 'CapCut Pro', 'b': 0.03, 'c': 1.2, 's': 1.35},
    {'name': 'Cyberpunk', 'b': 0.05, 'c': 1.4, 's': 1.9},
    {'name': 'Teal & Orange', 'b': -0.02, 'c': 1.3, 's': 1.4},
    {'name': 'Moody Dark', 'b': -0.08, 'c': 1.35, 's': 0.7},
    {'name': 'Vintage 90s', 'b': 0.06, 'c': 0.9, 's': 0.65},
    {'name': 'B&W Noir', 'b': 0.0, 'c': 1.45, 's': 0.0},
    {'name': 'Golden Hour', 'b': 0.05, 'c': 1.15, 's': 1.55},
  ];

  final List<TextTemplate> _textTemplates = [
    const TextTemplate(
      name: 'Classic Shadow',
      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black)]),
    ),
    const TextTemplate(
      name: 'Vlog Yellow',
      style: TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))]),
      bgColor: Colors.black54,
    ),
    const TextTemplate(
      name: 'Neon Cyber',
      style: TextStyle(color: Color(0xFF00F2FE), fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 16, color: Color(0xFF00F2FE)), Shadow(blurRadius: 30, color: Colors.purpleAccent)]),
    ),
    const TextTemplate(
      name: 'YouTube Sub',
      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      bgColor: Color(0xFFE50914),
      borderRadius: 6,
    ),
    const TextTemplate(
      name: 'Breaking News',
      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
      bgColor: Color(0xFFB71C1C),
      borderColor: Colors.amberAccent,
      borderRadius: 0,
    ),
    const TextTemplate(
      name: 'Minimal Box',
      style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      bgColor: Colors.white,
      borderRadius: 20,
    ),
  ];

  Future<void> _pickOrRecordVideo({required ImageSource source}) async {
    final XFile? picked = await _picker.pickVideo(source: source);
    if (picked != null) {
      _controller?.dispose();
      final file = File(picked.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      controller.addListener(_videoListener);
      setState(() {
        _videoFile = file;
        _controller = controller;
        _startTrim = 0.0;
        _endTrim = controller.value.duration.inMilliseconds.toDouble();
        if (_endTrim <= 0) _endTrim = 1000.0;
      });
      controller.play();
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final pos = _controller!.value.position.inMilliseconds.toDouble();
    if (pos >= _endTrim) {
      _controller!.seekTo(Duration(milliseconds: _startTrim.toInt()));
    }
    if (mounted) setState(() {});
  }

  List<double> _buildColorMatrix() {
    final double b = _brightness * 255.0;
    final double c = _contrast;
    final double s = _saturation;
    final double invSat = 1.0 - s;
    final double R = 0.2126 * invSat;
    final double G = 0.7152 * invSat;
    final double B = 0.0722 * invSat;
    final double t = (1.0 - c) * 128.0 + b;

    return [
      c * (R + s), c * G,       c * B,       0, t,
      c * R,       c * (G + s), c * B,       0, t,
      c * R,       c * G,       c * (B + s), 0, t,
      0,           0,           0,           1, 0,
    ];
  }

  void _openExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151821),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CapCut Pro Export Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00F2FE))),
                      Icon(Icons.hd_outlined, color: Color(0xFF00F2FE)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Format (ویڈیو یا آڈیو فارمیٹ):', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['MP4', 'MOV', 'MKV', 'MP3 (Audio)', 'GIF'].map((fmt) {
                      final sel = _exportFormat == fmt;
                      return ChoiceChip(
                        label: Text(fmt),
                        selected: sel,
                        selectedColor: const Color(0xFF00F2FE),
                        labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                        onSelected: (_) {
                          setModalState(() => _exportFormat = fmt);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  if (_exportFormat != 'MP3 (Audio)') ...[
                    const SizedBox(height: 14),
                    const Text('Resolution (کوالٹی):', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['720p', '1080p (HD)', '4K (Ultra HD)'].map((res) {
                        final sel = _exportResolution == res;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(res),
                            selected: sel,
                            selectedColor: const Color(0xFF00F2FE),
                            labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                            onSelected: (_) {
                              setModalState(() => _exportResolution = res);
                              setState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Frame Rate (FPS):', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [30, 60].map((fps) {
                        final sel = _exportFps == fps;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('$fps FPS'),
                            selected: sel,
                            selectedColor: const Color(0xFF00F2FE),
                            labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                            onSelected: (_) {
                              setModalState(() => _exportFps = fps);
                              setState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F2FE),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _runFFmpegExport();
                      },
                      icon: const Icon(Icons.bolt),
                      label: Text('Start Export ($_exportFormat)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runFFmpegExport() async {
    if (_videoFile == null || _controller == null) return;
    setState(() => _isExporting = true);
    _controller!.pause();

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final startSec = (_startTrim / 1000.0).toStringAsFixed(2);
      final durationDouble = (_endTrim - _startTrim) / 1000.0;
      final durationSec = durationDouble.toStringAsFixed(2);

      // 1. Export as MP3 (Audio Extract)
      if (_exportFormat == 'MP3 (Audio)') {
        final outMp3 = '${dir.path}/ArgonCut_Audio_$timestamp.mp3';
        final cmd = '-y -ss $startSec -t $durationSec -i "${_videoFile!.path}" -vn -acodec libmp3lame -q:a 2 "$outMp3"';
        final session = await FFmpegKit.execute(cmd);
        if (ReturnCode.isSuccess(await session.getReturnCode())) {
          await Share.shareXFiles([XFile(outMp3)], text: 'Exported MP3 Audio from ArgonCut Pro');
        } else {
          throw Exception('MP3 extraction failed');
        }
        setState(() => _isExporting = false);
        return;
      }

      // 2. Determine File Extension
      String ext = 'mp4';
      if (_exportFormat == 'MOV') ext = 'mov';
      if (_exportFormat == 'MKV') ext = 'mkv';
      if (_exportFormat == 'GIF') ext = 'gif';
      final outPath = '${dir.path}/ArgonCut_${timestamp}.$ext';

      // 3. Build Video Filter Chain
      List<String> vf = [];
      vf.add('eq=brightness=$_brightness:contrast=$_contrast:saturation=$_saturation');

      if (_isMirrored) vf.add('hflip');
      if (_isReversed) vf.add('reverse');
      if (_vignette > 0.1) vf.add('vignette=PI/4');
      if (_chromaKeyGreen) vf.add('chromakey=0x00FF00:0.15:0.1');

      // Masking (Cinema Bars)
      if (_selectedMask == 'Cinema Bars') {
        vf.add('drawbox=x=0:y=0:w=iw:h=ih*0.12:color=black:t=fill,drawbox=x=0:y=ih*0.88:w=iw:h=ih*0.12:color=black:t=fill');
      } else if (_selectedMask == 'Split Top/Bottom') {
        vf.add('drawbox=x=0:y=ih*0.5:w=iw:h=ih*0.5:color=black:t=fill');
      }

      // Transitions
      if (_selectedTransition == 'Fade In/Out') {
        final fadeOutStart = (durationDouble - 1.0).clamp(0.0, durationDouble).toStringAsFixed(2);
        vf.add('fade=t=in:st=0:d=1,fade=t=out:st=$fadeOutStart:d=1');
      } else if (_selectedTransition == 'Flash White') {
        vf.add('fade=t=in:st=0:d=0.6:color=white');
      } else if (_selectedTransition == 'Flash Black') {
        vf.add('fade=t=in:st=0:d=0.8:color=black');
      }

      // Playback Speed
      if (_playbackSpeed != 1.0) {
        final pts = (1.0 / _playbackSpeed).toStringAsFixed(2);
        vf.add('setpts=$pts*PTS');
      }

      // Target Resolution
      if (_exportFormat != 'GIF') {
        if (_exportResolution.startsWith('720p')) {
          vf.add('scale=-2:720');
        } else if (_exportResolution.startsWith('1080p')) {
          vf.add('scale=-2:1080');
        } else if (_exportResolution.startsWith('4K')) {
          vf.add('scale=-2:2160');
        }
      }

      // 4. Build Audio Filter Chain
      List<String> af = [];
      if (_isReversed) af.add('areverse');
      if (_playbackSpeed != 1.0) af.add('atempo=$_playbackSpeed');
      if (_voiceEffect == 'Chipmunk') af.add('asetrate=44100*1.4,aresample=44100');
      if (_voiceEffect == 'Deep Monster') af.add('asetrate=44100*0.7,aresample=44100');
      if (_voiceEffect == 'Robot Echo') af.add('aecho=0.8:0.88:60:0.4');

      final vfArg = vf.isNotEmpty ? '-vf "${vf.join(',')}"' : '';
      final afArg = _isMuted
          ? '-an'
          : (af.isNotEmpty ? '-af "${af.join(',')}" -c:a aac' : '-c:a aac');

      String cmd;
      if (_exportFormat == 'GIF') {
        cmd = '-y -ss $startSec -t $durationSec -i "${_videoFile!.path}" -vf "${vf.join(',')},fps=15,scale=480:-1" "$outPath"';
      } else {
        cmd = '-y -ss $startSec -t $durationSec -i "${_videoFile!.path}" $vfArg $afArg -r $_exportFps -c:v libx264 -preset ultrafast "$outPath"';
      }

      final session = await FFmpegKit.execute(cmd);
      if (ReturnCode.isSuccess(await session.getReturnCode())) {
        await Gal.putVideo(outPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $_exportFormat ($_exportResolution) گیلری میں سیو ہو گئی!'),
              backgroundColor: Colors.teal,
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () => Share.shareXFiles([XFile(outPath)]),
              ),
            ),
          );
        }
      } else {
        throw Exception('FFmpeg encode failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatMs(double ms) {
    final d = Duration(milliseconds: ms.toInt());
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double _getTargetAspectRatio() {
    if (_controller == null) return 16 / 9;
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller != null && _controller!.value.isInitialized;
    final totalMs = isReady
        ? _controller!.value.duration.inMilliseconds.toDouble().clamp(1.0, 36000000.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141C),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.movie_filter_rounded, color: Color(0xFF00F2FE), size: 24),
            SizedBox(width: 8),
            Text('ArgonCut Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.redAccent),
            tooltip: 'Record Camera / Screen Clip',
            onPressed: () => _pickOrRecordVideo(source: ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Import Video',
            onPressed: () => _pickOrRecordVideo(source: ImageSource.gallery),
          ),
          if (isReady)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _isExporting ? null : _openExportModal,
                icon: _isExporting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(_isExporting ? 'Rendering...' : 'HD Export', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: !isReady
          ? _buildHomeLauncher()
          : Column(
              children: [
                // 1. Live Studio Preview Canvas (With Masking, Transitions, Draggable Text)
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Aspect Ratio & Mirror Transform
                            AspectRatio(
                              aspectRatio: _getTargetAspectRatio(),
                              child: Container(
                                color: const Color(0xFF0E1015),
                                alignment: Alignment.center,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..scale(_isMirrored ? -1.0 : 1.0, 1.0, 1.0),
                                  child: _buildMaskedVideo(
                                    ColorFiltered(
                                      colorFilter: ColorFilter.matrix(_buildColorMatrix()),
                                      child: VideoPlayer(_controller!),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Vignette Overlay
                            if (_vignette > 0)
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [Colors.transparent, Colors.black.withOpacity(_vignette.clamp(0.0, 0.9))],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                            // Draggable Text Template Layer
                            if (_overlayText.isNotEmpty)
                              Positioned(
                                left: (_textPosition.dx * constraints.maxWidth - 90).clamp(8.0, constraints.maxWidth - 150),
                                top: (_textPosition.dy * constraints.maxHeight - 25).clamp(8.0, constraints.maxHeight - 60),
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final nx = (_textPosition.dx + details.delta.dx / constraints.maxWidth).clamp(0.05, 0.95);
                                      final ny = (_textPosition.dy + details.delta.dy / constraints.maxHeight).clamp(0.05, 0.95);
                                      _textPosition = Offset(nx, ny);
                                    });
                                  },
                                  child: Transform.scale(
                                    scale: _textScale,
                                    child: _buildStyledTextWidget(),
                                  ),
                                ),
                              ),

                            // Active Badges (Chroma / Transition / Voice)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Wrap(
                                spacing: 6,
                                children: [
                                  if (_selectedTransition != 'None') _badge('✨ $_selectedTransition'),
                                  if (_selectedMask != 'None') _badge('🎭 Mask: $_selectedMask'),
                                  if (_chromaKeyGreen) _badge('🟩 Chroma Key ON'),
                                  if (_voiceEffect != 'Normal') _badge('🎙️ $_voiceEffect'),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // 2. CapCut Style Playback & Timecode Bar
                Container(
                  color: const Color(0xFF12141C),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          size: 34,
                          color: const Color(0xFF00F2FE),
                        ),
                        onPressed: () {
                          setState(() {
                            _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                          });
                        },
                      ),
                      Text(
                        '${_formatMs(_controller!.value.position.inMilliseconds.toDouble())} / ${_formatMs(totalMs)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _controller!.value.position.inMilliseconds.toDouble().clamp(0.0, totalMs),
                          min: 0.0,
                          max: totalMs,
                          onChanged: (val) => _controller!.seekTo(Duration(milliseconds: val.toInt())),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: _isMuted ? Colors.redAccent : Colors.white70),
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                            _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Active Tool Dock
                Container(
                  height: 175,
                  color: const Color(0xFF171A24),
                  padding: const EdgeInsets.all(12),
                  child: _buildActiveToolWorkspace(totalMs),
                ),

                // 4. CapCut Scrollable Bottom Toolbar
                Container(
                  height: 68,
                  color: const Color(0xFF0B0D13),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _toolTab(0, Icons.content_cut_rounded, 'Edit / Trim'),
                      _toolTab(1, Icons.text_fields_rounded, 'Text & Temp'),
                      _toolTab(2, Icons.filter_vintage_rounded, 'Filters'),
                      _toolTab(3, Icons.auto_awesome_motion, 'Transitions'),
                      _toolTab(4, Icons.vignette_rounded, 'Mask & Key'),
                      _toolTab(5, Icons.tune_rounded, 'Adjust'),
                      _toolTab(6, Icons.graphic_eq_rounded, 'Audio & FX'),
                      _toolTab(7, Icons.aspect_ratio_rounded, 'Canvas'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHomeLauncher() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: const Color(0xFF00F2FE).withOpacity(0.35), blurRadius: 24)],
              ),
              child: const Icon(Icons.add_box_rounded, size: 54, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text('New CapCut Project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'HD Export • Text Templates • Masking • Transitions • MP3 Extract',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  onPressed: () => _pickOrRecordVideo(source: ImageSource.gallery),
                  icon: const Icon(Icons.video_library_rounded),
                  label: const Text('Import Video', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF00F2FE)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  onPressed: () => _pickOrRecordVideo(source: ImageSource.camera),
                  icon: const Icon(Icons.fiber_manual_record, color: Colors.redAccent),
                  label: const Text('Record Clip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStyledTextWidget() {
    final t = _textTemplates[_selectedTextTemplate];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: t.bgColor,
        borderRadius: BorderRadius.circular(t.borderRadius),
        border: t.borderColor != Colors.transparent ? Border.all(color: t.borderColor, width: 2) : null,
      ),
      child: Text(_overlayText, style: t.style),
    );
  }

  Widget _buildMaskedVideo(Widget child) {
    switch (_selectedMask) {
      case 'Circle':
        return ClipOval(
          child: Align(
            alignment: Alignment.center,
            widthFactor: _maskSize,
            heightFactor: _maskSize,
            child: child,
          ),
        );
      case 'Rectangle':
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Align(
            alignment: Alignment.center,
            widthFactor: _maskSize,
            heightFactor: _maskSize,
            child: child,
          ),
        );
      case 'Cinema Bars':
        return Stack(
          children: [
            child,
            Positioned(top: 0, left: 0, right: 0, height: 32, child: Container(color: Colors.black)),
            Positioned(bottom: 0, left: 0, right: 0, height: 32, child: Container(color: Colors.black)),
          ],
        );
      case 'Split Top/Bottom':
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _maskSize,
            child: child,
          ),
        );
      default:
        return child;
    }
  }

  Widget _toolTab(int index, IconData icon, String label) {
    final sel = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel ? const Color(0xFF00F2FE) : Colors.white60, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? const Color(0xFF00F2FE) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToolWorkspace(double totalMs) {
    switch (_activeTab) {
      case 0: // Edit, Trim, Speed, Reverse, Mirror
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('In: ${_formatMs(_startTrim)}', style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12)),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Mirror Flip', style: TextStyle(fontSize: 11)),
                        selected: _isMirrored,
                        onSelected: (v) => setState(() => _isMirrored = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Reverse ⏪', style: TextStyle(fontSize: 11)),
                        selected: _isReversed,
                        onSelected: (v) => setState(() => _isReversed = v),
                      ),
                    ],
                  ),
                  Text('Out: ${_formatMs(_endTrim)}', style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12)),
                ],
              ),
              RangeSlider(
                values: RangeValues(_startTrim.clamp(0.0, totalMs), _endTrim.clamp(0.0, totalMs)),
                min: 0.0,
                max: totalMs,
                onChanged: (val) {
                  setState(() {
                    _startTrim = val.start;
                    _endTrim = val.end;
                  });
                  _controller!.seekTo(Duration(milliseconds: _startTrim.toInt()));
                },
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                    final sel = _playbackSpeed == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text('${s}x'),
                        selected: sel,
                        selectedColor: const Color(0xFF00F2FE),
                        labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 12),
                        onSelected: (_) {
                          setState(() => _playbackSpeed = s);
                          _controller!.setPlaybackSpeed(s);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );

      case 1: // Text & CapCut Text Templates
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ٹیکسٹ لکھیں اور ویڈیو پر انگلی سے ہلائیں...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: const Color(0xFF232736),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setState(() => _overlayText = v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Size', style: TextStyle(fontSize: 11)),
                SizedBox(
                  width: 90,
                  child: Slider(
                    value: _textScale,
                    min: 0.6,
                    max: 2.2,
                    onChanged: (v) => setState(() => _textScale = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _textTemplates.length,
                itemBuilder: (ctx, i) {
                  final sel = _selectedTextTemplate == i;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedTextTemplate = i;
                      if (_overlayText.isEmpty) _overlayText = _textTemplates[i].name;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232736),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? const Color(0xFF00F2FE) : Colors.white12, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(_textTemplates[i].name, style: _textTemplates[i].style.copyWith(fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 2: // Filters
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (ctx, i) {
            final sel = _selectedFilterIndex == i;
            return GestureDetector(
              onTap: () {
                final f = _filters[i];
                setState(() {
                  _selectedFilterIndex = i;
                  _brightness = f['b'];
                  _contrast = f['c'];
                  _saturation = f['s'];
                });
              },
              child: Container(
                width: 95,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)]) : null,
                  color: sel ? null : const Color(0xFF232736),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[i]['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            );
          },
        );

      case 3: // Transitions
        final transitions = ['None', 'Fade In/Out', 'Flash White', 'Flash Black'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Video Transition Effect:', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: transitions.map((tr) {
                final sel = _selectedTransition == tr;
                return ChoiceChip(
                  label: Text(tr),
                  selected: sel,
                  selectedColor: const Color(0xFF00F2FE),
                  labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                  onSelected: (_) => setState(() => _selectedTransition = tr),
                );
              }).toList(),
            ),
          ],
        );

      case 4: // Masking & Chroma Key
        final masks = ['None', 'Circle', 'Rectangle', 'Cinema Bars', 'Split Top/Bottom'];
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: masks.map((m) {
                    final sel = _selectedMask == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: sel,
                        selectedColor: const Color(0xFF00F2FE),
                        labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 12),
                        onSelected: (_) => setState(() => _selectedMask = m),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Row(
                children: [
                  const Text('Mask Size:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _maskSize,
                      min: 0.3,
                      max: 1.0,
                      onChanged: (v) => setState(() => _maskSize = v),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Chroma Key (Green Screen)', style: TextStyle(fontSize: 11)),
                    selected: _chromaKeyGreen,
                    selectedColor: Colors.greenAccent,
                    labelStyle: TextStyle(color: _chromaKeyGreen ? Colors.black : Colors.white),
                    onSelected: (v) => setState(() => _chromaKeyGreen = v),
                  ),
                ],
              ),
            ],
          ),
        );

      case 5: // Adjust Sliders
        return SingleChildScrollView(
          child: Column(
            children: [
              _miniSlider('Brightness', _brightness, -0.4, 0.4, (v) => setState(() => _brightness = v)),
              _miniSlider('Contrast', _contrast, 0.5, 2.0, (v) => setState(() => _contrast = v)),
              _miniSlider('Saturation', _saturation, 0.0, 2.5, (v) => setState(() => _saturation = v)),
              _miniSlider('Vignette', _vignette, 0.0, 0.85, (v) => setState(() => _vignette = v)),
            ],
          ),
        );

      case 6: // Audio & Voice FX + Quick MP3 Export
        final voices = ['Normal', 'Chipmunk', 'Deep Monster', 'Robot Echo'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CapCut Voice Effects:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _exportFormat = 'MP3 (Audio)');
                    _runFFmpegExport();
                  },
                  icon: const Icon(Icons.audiotrack, color: Color(0xFF00F2FE), size: 18),
                  label: const Text('Extract MP3 Now', style: TextStyle(color: Color(0xFF00F2FE))),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: voices.map((vf) {
                final sel = _voiceEffect == vf;
                return ChoiceChip(
                  label: Text(vf),
                  selected: sel,
                  selectedColor: const Color(0xFF00F2FE),
                  labelStyle: TextStyle(color: sel ? Colors.black : Colors.white),
                  onSelected: (_) => setState(() => _voiceEffect = vf),
                );
              }).toList(),
            ),
          ],
        );

      case 7: // Canvas / Aspect Ratio
        final ratios = ['Original', '9:16 (TikTok)', '16:9 (YouTube)', '1:1 (Insta)', '4:5 (Portrait)'];
        return Center(
          child: Wrap(
            spacing: 10,
            children: ratios.map((r) {
              final sel = _canvasRatio == r;
              return ChoiceChip(
                label: Text(r),
                selected: sel,
                selectedColor: const Color(0xFF00F2FE),
                labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                onSelected: (_) => setState(() => _canvasRatio = r),
              );
            }).toList(),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _miniSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(width: 75, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(child: Slider(value: val, min: min, max: max, onChanged: onChanged)),
        ],
      ),
    );
  }
}
