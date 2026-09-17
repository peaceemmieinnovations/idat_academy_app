import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/gamification_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class CrossMatchScreen extends StatefulWidget {
  final int? lessonId;
  final String? lessonTitle;
  final String? lessonTopic;
  final String? lessonContent;

  const CrossMatchScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
    this.lessonTopic,
    this.lessonContent,
  });

  @override
  State<CrossMatchScreen> createState() => _CrossMatchScreenState();
}

class _CrossMatchScreenState extends State<CrossMatchScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<_Pair> _pairs = [];
  List<int> _termOrder = [];
  List<int> _defOrder = [];
  int? _selectedTermIndex;
  int? _selectedDefIndex;
  final Set<int> _matchedTerms = {};
  final Set<int> _matchedDefs = {};
  int _mistakes = 0;
  bool _completed = false;

  // Animation for matches
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadPairs();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _matchedCount => _matchedTerms.length;

  Future<void> _loadPairs() async {
    setState(() {
      _loading = true;
      _error = null;
      _completed = false;
      _matchedTerms.clear();
      _matchedDefs.clear();
      _selectedTermIndex = null;
      _selectedDefIndex = null;
      _mistakes = 0;
    });

    final res = await ApiService.getLessonAiCrossmatch(
      lessonId: widget.lessonId,
      lessonTitle: widget.lessonTitle,
      lessonTopic: widget.lessonTopic,
      lessonContent: widget.lessonContent,
    );

    if (!mounted) return;

    // Prefer server-generated pairs; fall back to the local bank when the
    // /ai/crossmatch endpoint is not deployed yet so the feature still works.
    var pairs = _parseServerPairs(res);
    if (pairs.length < 2) {
      pairs = _localPairs();
    }

    if (pairs.length < 2) {
      setState(() {
        _error = 'Not enough matching pairs to play. Try a different lesson.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _pairs = pairs;
      _termOrder = List<int>.generate(pairs.length, (i) => i)
        ..shuffle();
      _defOrder = List<int>.generate(pairs.length, (i) => i)
        ..shuffle();
      _loading = false;
    });
  }

  List<_Pair> _parseServerPairs(Map<String, dynamic> res) {
    if (res['error'] != null) return const [];
    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    final rawPairs = data['pairs'];
    if (rawPairs is! List) return const [];
    var pairs = rawPairs
        .whereType<Map>()
        .map((m) => _Pair(
              term: (m['term'] ?? '').toString(),
              definition: (m['definition'] ?? m['match'] ?? '').toString(),
            ))
        .where((p) => p.term.isNotEmpty && p.definition.isNotEmpty)
        .toList();
    pairs.shuffle();
    if (pairs.length > 8) pairs = pairs.sublist(0, 8);
    return pairs;
  }

  /// Local topic-aware bank used as an offline fallback until the server
  /// exposes POST /ai/crossmatch.
  List<_Pair> _localPairs() {
    final topic = '${widget.lessonTopic} ${widget.lessonTitle}'.toLowerCase();
    final all = <String, List<_Pair>>{
      'cybersecurity': const [
        _Pair(
            term: 'Phishing',
            definition:
                'A deceptive attempt to steal credentials or data via fake messages'),
        _Pair(
            term: 'Firewall',
            definition:
                'Filters traffic between a trusted network and untrusted networks'),
        _Pair(
            term: 'Malware',
            definition:
                'Software written to damage or gain unauthorized access to a device'),
        _Pair(
            term: 'Encryption',
            definition:
                'Scrambles data so only the intended recipient can read it'),
        _Pair(
            term: 'Multi-factor authentication',
            definition:
                'Requires two or more proofs of identity before granting access'),
        _Pair(
            term: 'VPN',
            definition:
                'Creates a secure tunnel for traffic over a public network'),
      ],
      'artificial intelligence': const [
        _Pair(
            term: 'Model',
            definition:
                'A trained algorithm that maps inputs to predictions'),
        _Pair(
            term: 'Training data',
            definition: 'The examples used to teach a model its patterns'),
        _Pair(
            term: 'Overfitting',
            definition:
                'When a model memorizes training data instead of generalizing'),
        _Pair(
            term: 'Neural network',
            definition:
                'Layers of connected units loosely inspired by the brain'),
        _Pair(
            term: 'Prompt',
            definition: 'The instruction or input given to an AI model'),
        _Pair(
            term: 'Inference',
            definition:
                'Running the trained model to get an output for new input'),
      ],
      'web development': const [
        _Pair(
            term: 'HTML',
            definition: 'The markup language that structures a web page'),
        _Pair(
            term: 'CSS',
            definition: 'Styles the look and layout of a web page'),
        _Pair(
            term: 'JavaScript',
            definition: 'Adds interactivity and logic to web pages'),
        _Pair(
            term: 'API',
            definition:
                'A contract that lets two software systems exchange data'),
        _Pair(
            term: 'Responsive design',
            definition:
                'Layouts that adapt to any screen size from phone to desktop'),
        _Pair(
            term: 'Version control',
            definition:
                'Tracks changes to code so teams can collaborate safely'),
      ],
      'data analysis': const [
        _Pair(
            term: 'Dataset',
            definition: 'A structured collection of records for analysis'),
        _Pair(
            term: 'Outlier',
            definition:
                'A data point that differs greatly from the rest of the data'),
        _Pair(
            term: 'Visualization',
            definition: 'Charts and graphs that make data patterns visible'),
        _Pair(
            term: 'Correlation',
            definition:
                'A statistical relationship between two variables'),
        _Pair(
            term: 'Cleaning',
            definition:
                'Fixing missing, duplicate or malformed values in data'),
        _Pair(
            term: 'Dashboard',
            definition:
                'A single view that summarizes key metrics at a glance'),
      ],
      'digital marketing': const [
        _Pair(
            term: 'Conversion',
            definition:
                'When a visitor completes a desired action like a purchase'),
        _Pair(
            term: 'Funnel',
            definition:
                'The stages a customer moves through toward a purchase'),
        _Pair(
            term: 'CTR',
            definition:
                'The share of people who clicked an ad or link out of those who saw it'),
        _Pair(
            term: 'SEO',
            definition:
                'Improving a site to rank higher in search engine results'),
        _Pair(
            term: 'Persona',
            definition: 'A detailed profile of a target customer segment'),
        _Pair(
            term: 'Retargeting',
            definition:
                'Showing ads to people who already visited your site'),
      ],
    };

    for (final entry in all.entries) {
      if (_topicMatch(topic, entry.key)) return List.of(entry.value)..shuffle();
    }

    const generic = [
      _Pair(
          term: 'Machine learning',
          definition: 'Systems that improve at a task from data'),
      _Pair(
          term: 'Algorithm',
          definition: 'A step-by-step set of rules for solving a problem'),
      _Pair(
          term: 'Data structure',
          definition: 'A way of organizing data for efficient use'),
      _Pair(
          term: 'Debugging',
          definition: 'Finding and fixing errors in code'),
      _Pair(
          term: 'Version control',
          definition: 'Tracking code changes for safe collaboration'),
      _Pair(
          term: 'Open source',
          definition: 'Software whose source code anyone can view and modify'),
      _Pair(
          term: 'Backup',
          definition: 'A copy of data kept in case the original is lost'),
      _Pair(
          term: 'Latency',
          definition: 'The delay before data transfers from source to target'),
    ];
    return List.of(generic)..shuffle();
  }

  bool _topicMatch(String haystack, String needle) {
    for (final part in needle.split(' ')) {
      if (haystack.contains(part)) return true;
    }
    return false;
  }

  void _onTermTap(int index) {
    if (_matchedTerms.contains(index)) return;
    setState(() {
      _selectedTermIndex = index;
      _checkMatch();
    });
  }

  void _onDefTap(int index) {
    if (_matchedDefs.contains(index)) return;
    setState(() {
      _selectedDefIndex = index;
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedTermIndex == null || _selectedDefIndex == null) return;
    if (_selectedTermIndex == _selectedDefIndex) {
      // Correct match
      _matchedTerms.add(_selectedTermIndex!);
      _matchedDefs.add(_selectedDefIndex!);
      _selectedTermIndex = null;
      _selectedDefIndex = null;

      if (_matchedCount == _pairs.length) {
        _completed = true;
        GamificationService.recordActivity('crossmatch');
        NotificationService.showActivityNotification(
          title: 'Cross-match complete',
          body: 'You matched all ${_pairs.length} pairs and earned 30 XP.',
          screen: 'gamification',
        );
      }
      _pulseCtrl.forward(from: 0);
    } else {
      // Wrong match — clear both selections so the user can try again.
      _mistakes++;
      _selectedTermIndex = null;
      _selectedDefIndex = null;
    }
  }

  void _resetGame() {
    setState(() {
      _matchedTerms.clear();
      _matchedDefs.clear();
      _selectedTermIndex = null;
      _selectedDefIndex = null;
      _mistakes = 0;
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross-Match'),
        actions: [
          if (!_loading && _pairs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'New pairs',
              onPressed: _loadPairs,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.secondary),
                    SizedBox(height: 20),
                    Text('Loading matching pairs…',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadPairs,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _completed
                  ? _buildCompleteScreen()
                  : _buildGameBody(),
    );
  }

  Widget _buildGameBody() {
    final termIndices = _termOrder;
    final defIndices = _defOrder;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a term, then tap its matching definition.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary),
                  ),
                ),
                Text(
                  '$_matchedCount/${_pairs.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Two columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Terms column
                Expanded(
                  child: Column(
                    children: [
                      const _ColumnLabel('Terms'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: termIndices.length,
                          itemBuilder: (_, listIdx) {
                            final i = termIndices[listIdx];
                            final matched = _matchedTerms.contains(i);
                            final selected = _selectedTermIndex == i;
                            return _MatchTile(
                              text: _pairs[i].term,
                              matched: matched,
                              selected: selected,
                              color: AppColors.primary,
                              onTap: matched ? null : () => _onTermTap(i),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Center connector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pairs.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: _matchedTerms.contains(i)
                              ? AppColors.success.withValues(alpha: 0.5)
                              : AppColors.lightGrey,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Definitions column
                Expanded(
                  child: Column(
                    children: [
                      const _ColumnLabel('Definitions'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: defIndices.length,
                          itemBuilder: (_, listIdx) {
                            final i = defIndices[listIdx];
                            final matched = _matchedDefs.contains(i);
                            final selected = _selectedDefIndex == i;
                            return _MatchTile(
                              text: _pairs[i].definition,
                              matched: matched,
                              selected: selected,
                              color: AppColors.accent,
                              onTap: matched ? null : () => _onDefTap(i),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mistakes counter
          if (_mistakes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$_mistakes ${_mistakes == 1 ? 'mistake' : 'mistakes'}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _pulseCtrl..forward(),
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.success, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All matched!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mistakes == 0
                  ? 'Perfect score! No mistakes.'
                  : 'Completed with $_mistakes ${_mistakes == 1 ? 'mistake' : 'mistakes'}.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+30 XP earned',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play again'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pair {
  final String term;
  final String definition;
  const _Pair({required this.term, required this.definition});
}

class _ColumnLabel extends StatelessWidget {
  final String label;
  const _ColumnLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String text;
  final bool matched;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const _MatchTile({
    required this.text,
    required this.matched,
    required this.selected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = matched
        ? AppColors.success.withValues(alpha: 0.1)
        : selected
            ? color.withValues(alpha: 0.12)
            : AppColors.white;
    final borderColor = matched
        ? AppColors.success
        : selected
            ? color
            : AppColors.lightGrey;
    final textColor =
        matched ? AppColors.success : selected ? color : AppColors.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (matched)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: matched ? FontWeight.w500 : FontWeight.w600,
                    color: textColor,
                    height: 1.3,
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
