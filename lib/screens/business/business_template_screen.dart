import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WhatsApp-style Create template (Setup + Edit). No email/profile in header.
/// Accents use [ColorScheme.primary] from app theme.
class BusinessTemplateScreen extends StatefulWidget {
  const BusinessTemplateScreen({
    super.key,
    this.businessName = 'My Business',
  });

  final String businessName;

  @override
  State<BusinessTemplateScreen> createState() => _BusinessTemplateScreenState();
}

enum _TemplateCategory { marketing, utility, authentication }

enum _HeaderMedia { none, text, image, video, document }

enum _ButtonKind { custom, visitWebsite, callPhone, copyOffer }

class _TemplateButton {
  _ButtonKind kind;
  final TextEditingController textCtrl;
  final TextEditingController urlCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController offerCtrl;
  String urlType;
  String country;

  _TemplateButton({
    required this.kind,
    String text = '',
    String url = '',
    String phone = '',
    String offer = '',
    this.urlType = 'static',
    this.country = '+91',
  })  : textCtrl = TextEditingController(text: text),
        urlCtrl = TextEditingController(text: url),
        phoneCtrl = TextEditingController(text: phone),
        offerCtrl = TextEditingController(text: offer);

  void dispose() {
    textCtrl.dispose();
    urlCtrl.dispose();
    phoneCtrl.dispose();
    offerCtrl.dispose();
  }

  bool get isQuickReply => kind == _ButtonKind.custom;

  String get title {
    switch (kind) {
      case _ButtonKind.custom:
        return 'Quick reply · Optional';
      default:
        return 'Call to action · Optional';
    }
  }
}

class _BusinessTemplateScreenState extends State<BusinessTemplateScreen> {
  static const Color _headerBg = Color(0xFF1C2B33);
  static const Color _pageBg = Color(0xFFF0F2F5);
  static const Color _success = Color(0xFF1DAA61);
  static const Color _ink = Color(0xFF1C2B33);
  static const Color _muted = Color(0xFF667781);
  static const Color _line = Color(0xFFE9EDEF);
  static const Color _previewBg = Color(0xFFE5DDD5);
  static const Color _error = Color(0xFFD92D20);

  // Step 0 setup
  _TemplateCategory _category = _TemplateCategory.marketing;
  int _step = 0; // 0 setup, 1 edit, 2 submit

  // Step 1 edit
  final _nameCtrl = TextEditingController();
  final _headerTextCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController(text: 'Hello');
  final _bodyFocus = FocusNode();
  final _footerCtrl = TextEditingController();
  final _mediaUrlCtrl = TextEditingController();
  String _language = 'English';
  String _variableType = 'number';
  _HeaderMedia _headerMedia = _HeaderMedia.none;
  final List<_TemplateButton> _buttons = [];
  bool _showEmojiPanel = false;

  static const _emojiList = <String>[
    '😀', '😁', '😂', '🤣', '😊', '😍', '🤩', '😎',
    '🙂', '😉', '😢', '😭', '😡', '🤔', '🙌', '👏',
    '👍', '👎', '🙏', '💪', '🔥', '✨', '🎉', '❤️',
    '💙', '💚', '💛', '🧡', '💜', '🖤', '💯', '✅',
    '❌', '⭐', '🌟', '📌', '📢', '🛒', '🎁', '💰',
    '📱', '📦', '🚚', '🏠', '⏰', '📅', '🔗', '🆕',
  ];

  final _languages = const [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Portuguese',
    'Arabic',
    'Indonesian',
  ];

  ColorScheme get _cs => Theme.of(context).colorScheme;
  Color get _primary => _cs.primary;
  Color get _primarySoft => _primary.withValues(alpha: 0.12);

  String get _categoryLabel {
    switch (_category) {
      case _TemplateCategory.marketing:
        return 'Marketing';
      case _TemplateCategory.utility:
        return 'Utility';
      case _TemplateCategory.authentication:
        return 'Authentication';
    }
  }

  String get _displayName {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) return 'your_template_name';
    return n.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameCtrl,
      _headerTextCtrl,
      _bodyCtrl,
      _footerCtrl,
      _mediaUrlCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headerTextCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    _footerCtrl.dispose();
    _mediaUrlCtrl.dispose();
    for (final b in _buttons) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Create template',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 28 : 16,
                20,
                isDesktop ? 28 : 16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    const Text(
                      'Create template',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _buildStepper(),
                  const SizedBox(height: 22),
                  if (_step == 0)
                    _buildSetupLayout(isDesktop)
                  else if (_step == 1)
                    _buildEditLayout(isDesktop)
                  else
                    _buildSubmitLayout(isDesktop),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─── Layouts ──────────────────────────────────────────────────────────────

  Widget _buildSetupLayout(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildSetupCard()),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: _buildSetupPreviewCard()),
        ],
      );
    }
    return Column(
      children: [
        _buildSetupCard(),
        const SizedBox(height: 16),
        _buildSetupPreviewCard(),
      ],
    );
  }

  Widget _buildEditLayout(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildTemplateMetaChip(),
                const SizedBox(height: 12),
                _buildNameLanguageCard(),
                const SizedBox(height: 12),
                _buildContentCard(),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: _buildLivePreviewCard()),
        ],
      );
    }
    return Column(
      children: [
        _buildTemplateMetaChip(),
        const SizedBox(height: 12),
        _buildNameLanguageCard(),
        const SizedBox(height: 12),
        _buildContentCard(),
        const SizedBox(height: 16),
        _buildLivePreviewCard(),
      ],
    );
  }

  Widget _buildSubmitLayout(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildSubmitReviewCard()),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: _buildLivePreviewCard()),
        ],
      );
    }
    return Column(
      children: [
        _buildSubmitReviewCard(),
        const SizedBox(height: 16),
        _buildLivePreviewCard(),
      ],
    );
  }

  Widget _buildSubmitReviewCard() {
    final headerLabel = switch (_headerMedia) {
      _HeaderMedia.none => 'None',
      _HeaderMedia.text => 'Text',
      _HeaderMedia.image => 'Image',
      _HeaderMedia.video => 'Video',
      _HeaderMedia.document => 'Document',
    };
    final bodyText =
        _bodyCtrl.text.trim().isEmpty ? '—' : _bodyCtrl.text.trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit for review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review your template details, then submit to Meta. Approval usually takes a few minutes to a few hours.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _reviewRow('Name', _displayName),
                _reviewDivider(),
                _reviewRow('Language', _language),
                _reviewDivider(),
                _reviewRow('Category', _categoryLabel),
                _reviewDivider(),
                _reviewRow('Header', headerLabel),
                _reviewDivider(),
                _reviewRow('Buttons', '${_buttons.length}'),
                _reviewDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Body',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bodyText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: _ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8C97A)),
            ),
            child: const Text(
              'Once submitted, this template cannot be edited until Meta finishes review. You can delete and recreate it if changes are needed.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF7A5C12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewDivider() => const Divider(height: 1, color: _line);

  // ─── Stepper ──────────────────────────────────────────────────────────────

  Widget _buildStepper() {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final steps = narrow
        ? const ['Set up', 'Edit', 'Submit']
        : const ['Set up template', 'Edit template', 'Submit for Review'];

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: _stepConnector(completed: i <= _step),
              ),
            Flexible(
              fit: FlexFit.loose,
              child: _stepItem(
                index: i,
                label: steps[i],
                completed: i < _step,
                active: i == _step,
                compact: narrow,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepConnector({required bool completed}) {
    if (completed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(height: 2, color: _success),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CustomPaint(
        painter: _DashedLinePainter(color: Colors.grey.shade400),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  Widget _stepItem({
    required int index,
    required String label,
    required bool completed,
    required bool active,
    bool compact = false,
  }) {
    final circleSize = compact ? 20.0 : 28.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: circleSize,
          width: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? _success
                : active
                    ? _primary
                    : Colors.transparent,
            border: Border.all(
              color: completed
                  ? _success
                  : active
                      ? _primary
                      : Colors.grey.shade400,
              width: 1.6,
            ),
          ),
          child: completed
              ? Icon(Icons.check, size: compact ? 11 : 16, color: Colors.white)
              : active
                  ? Icon(Icons.more_vert, size: compact ? 11 : 14, color: Colors.white)
                  : null,
        ),
        SizedBox(width: compact ? 4 : 8),
        Flexible(
          child: Container(
            padding: active
                ? EdgeInsets.symmetric(
                    horizontal: compact ? 5 : 10,
                    vertical: compact ? 3 : 6,
                  )
                : EdgeInsets.zero,
            decoration: active
                ? BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10.5 : 13,
                fontWeight:
                    active || completed ? FontWeight.w600 : FontWeight.w500,
                color: completed
                    ? _ink
                    : active
                        ? _primary
                        : _muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared card ──────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.fromLTRB(
            narrow ? 14 : 22,
            narrow ? 16 : 22,
            narrow ? 14 : 22,
            narrow ? 14 : 18,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }

  InputDecoration _fieldDeco({
    String? hint,
    String? label,
    Widget? prefixIcon,
    bool error = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: error ? _error : _line),
    );
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: error ? _error : _primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _error),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETUP STEP
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSetupCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set up your template',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose the category that best describes your message template. Then, select the type of message that you want to send.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
          const SizedBox(height: 18),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          _buildMessageTypeList(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wrap = constraints.maxWidth < 420;
        final tabs = [
          _categoryTab(
            _TemplateCategory.marketing,
            'Marketing',
            Icons.campaign_outlined,
            expanded: !wrap,
          ),
          _categoryTab(
            _TemplateCategory.utility,
            'Utility',
            Icons.notifications_none_rounded,
            expanded: !wrap,
          ),
          _categoryTab(
            _TemplateCategory.authentication,
            wrap ? 'Auth' : 'Authentication',
            Icons.verified_user_outlined,
            expanded: !wrap,
          ),
        ];

        if (wrap) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  tabs[i],
                ],
              ],
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: tabs[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _categoryTab(
    _TemplateCategory cat,
    String label,
    IconData icon, {
    bool expanded = false,
  }) {
    final selected = _category == cat;
    final child = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _category = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _primary.withValues(alpha: 0.45) : _line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: selected ? _primary : _muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? _primary : _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return child;
  }

  Widget _buildMessageTypeList() {
    final types = const [
      ('Default', 'Send messages with media and customised buttons to engage your customers.', true),
      ('Catalogue', 'Send messages that drive sales by connecting your product catalogue.', false),
      ('Flows', 'Send a form to capture customer interests, appointment requests or run surveys.', false),
      ('Order details', 'Send messages through which customers can pay you.', false),
      ('Calling permissions request', 'Ask customers if you can call them on WhatsApp.', false),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _line),
            _messageTypeRow(types[i].$1, types[i].$2, types[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _messageTypeRow(String title, String desc, bool enabled) {
    return Material(
      color: enabled ? _primarySoft : Colors.white,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                enabled ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: enabled ? _primary : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: enabled ? _ink : _muted,
                            ),
                          ),
                        ),
                        if (!enabled) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Coming soon',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: enabled ? _muted : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPreviewCard() {
    String body;
    String goodFor;
    List<(IconData, String)> buttons;
    bool showImage;

    switch (_category) {
      case _TemplateCategory.marketing:
        body =
            'Hey there! Check out our fresh groceries now! Use code HEALTH to get additional 10% off on your entire purchase.';
        goodFor =
            'Welcome messages, promotions, offers, coupons, newsletters, announcements.';
        buttons = [
          (Icons.open_in_new_rounded, 'Shop now'),
          (Icons.copy_rounded, 'Copy code'),
        ];
        showImage = true;
      case _TemplateCategory.utility:
        body =
            'Your order #{{1}} has been shipped and is on its way. Track delivery with the link below.';
        goodFor =
            'Order updates, account alerts, appointment reminders, payment confirmations.';
        buttons = [(Icons.open_in_new_rounded, 'Track order')];
        showImage = false;
      case _TemplateCategory.authentication:
        body =
            '{{1}} is your verification code. For your security, do not share this code.';
        goodFor = 'One-time passwords, account verification, login codes.';
        buttons = [];
        showImage = false;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 14),
          _chatShell(
            child: _messageBubble(
              showImage: showImage,
              headerText: null,
              headerMedia: showImage ? _HeaderMedia.image : _HeaderMedia.none,
              body: body,
              footer: null,
              buttons: buttons,
              time: '13:28',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This template is good for',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 4),
          Text(goodFor, style: const TextStyle(fontSize: 12, height: 1.4, color: _muted)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT STEP
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTemplateMetaChip() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: _success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_displayName · $_language',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_categoryLabel · Default',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameLanguageCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template name and language',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 520;
              final nameField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Name your template',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ),
                      Text(
                        '${_nameCtrl.text.length}/512',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    maxLength: 512,
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) =>
                        null,
                    decoration: _fieldDeco(hint: 'Enter a template name.'),
                  ),
                ],
              );
              final langField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select language',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _language,
                    isExpanded: true,
                    decoration: _fieldDeco(),
                    items: _languages
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              l,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _language = v);
                    },
                  ),
                ],
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 16),
                    Expanded(child: langField),
                  ],
                );
              }
              return Column(
                children: [
                  nameField,
                  const SizedBox(height: 14),
                  langField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in the header, body and footer sections of your template. Cloud API hosted by Meta will review the variables and content samples you provide for approval.',
            style: TextStyle(fontSize: 12, height: 1.45, color: _muted),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 520;
              final varField = _labeledDropdown(
                label: 'Type of variable',
                showInfo: true,
                value: _variableType,
                items: const ['number', 'text'],
                onChanged: (v) => setState(() => _variableType = v!),
              );
              final mediaField = _labeledDropdown(
                label: 'Media sample · Optional',
                value: _headerMedia == _HeaderMedia.none
                    ? 'None'
                    : _headerMedia.name[0].toUpperCase() +
                        _headerMedia.name.substring(1),
                items: const ['None', 'Text', 'Image', 'Video', 'Document'],
                icon: _mediaIcon(_headerMedia),
                onChanged: (v) {
                  setState(() {
                    switch (v) {
                      case 'Text':
                        _headerMedia = _HeaderMedia.text;
                      case 'Image':
                        _headerMedia = _HeaderMedia.image;
                      case 'Video':
                        _headerMedia = _HeaderMedia.video;
                      case 'Document':
                        _headerMedia = _HeaderMedia.document;
                      default:
                        _headerMedia = _HeaderMedia.none;
                    }
                    if (_headerMedia != _HeaderMedia.video &&
                        _headerMedia != _HeaderMedia.document) {
                      _mediaUrlCtrl.clear();
                    }
                  });
                },
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: varField),
                    const SizedBox(width: 16),
                    Expanded(child: mediaField),
                  ],
                );
              }
              return Column(
                children: [
                  varField,
                  const SizedBox(height: 12),
                  mediaField,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildHeaderSection(),
          const SizedBox(height: 20),
          _buildBodySection(),
          const SizedBox(height: 20),
          _buildFooterSection(),
          const SizedBox(height: 20),
          _buildButtonsSection(),
        ],
      ),
    );
  }

  IconData? _mediaIcon(_HeaderMedia m) {
    switch (m) {
      case _HeaderMedia.image:
        return Icons.image_outlined;
      case _HeaderMedia.video:
        return Icons.videocam_outlined;
      case _HeaderMedia.document:
        return Icons.description_outlined;
      case _HeaderMedia.text:
        return Icons.title_rounded;
      case _HeaderMedia.none:
        return null;
    }
  }

  Widget _labeledDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool showInfo = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 14, color: _muted),
            ],
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: _fieldDeco(
            prefixIcon: icon == null ? null : Icon(icon, size: 18, color: _muted),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Header · Optional',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            if (_headerMedia == _HeaderMedia.text)
              Text(
                '${_headerTextCtrl.text.length}/60',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_headerMedia == _HeaderMedia.none)
          Text(
            'Choose a media sample above to add a text or media header.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          )
        else if (_headerMedia == _HeaderMedia.text)
          TextField(
            controller: _headerTextCtrl,
            maxLength: 60,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            decoration: _fieldDeco(hint: 'Enter header text'),
          )
        else if (_headerMedia == _HeaderMedia.image)
          _dashedUploadBox(
            child: Column(
              children: [
                Icon(Icons.upload_rounded, color: _primary, size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Drag and drop to upload',
                  style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'or ',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      TextSpan(
                        text: 'choose files on your device',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          _dashedUploadBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerMedia == _HeaderMedia.video
                      ? 'Paste a public HTTPS URL for your video.'
                      : 'Paste a public HTTPS URL for your document.',
                  style: const TextStyle(fontSize: 13, color: _ink),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mediaUrlCtrl,
                  decoration: _fieldDeco(hint: 'https://'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dashedUploadBox({required Widget child}) {
    final pad = MediaQuery.sizeOf(context).width < 400 ? 14.0 : 20.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _primary.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _primary.withValues(alpha: 0.35),
        ),
      ),
      child: CustomPaint(
        painter: _DashedRectPainter(color: _primary.withValues(alpha: 0.5)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBodySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Body',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            Text(
              '${_bodyCtrl.text.length}/1024',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              TextField(
                controller: _bodyCtrl,
                focusNode: _bodyFocus,
                maxLines: 5,
                maxLength: 1024,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null,
                decoration: const InputDecoration(
                  hintText: 'Enter body text…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _fmtIcon(
                        Icons.emoji_emotions_outlined,
                        tooltip: 'Emoji',
                        active: _showEmojiPanel,
                        onTap: () {
                          setState(() => _showEmojiPanel = !_showEmojiPanel);
                          _bodyFocus.requestFocus();
                        },
                      ),
                      _fmtIcon(
                        Icons.format_bold,
                        tooltip: 'Bold  *text*',
                        onTap: () =>
                            _wrapBodyFormat('*', '*', placeholder: 'bold'),
                      ),
                      _fmtIcon(
                        Icons.format_italic,
                        tooltip: 'Italic  _text_',
                        onTap: () =>
                            _wrapBodyFormat('_', '_', placeholder: 'italic'),
                      ),
                      _fmtIcon(
                        Icons.format_strikethrough,
                        tooltip: 'Strikethrough  ~text~',
                        onTap: () =>
                            _wrapBodyFormat('~', '~', placeholder: 'strike'),
                      ),
                      _fmtIcon(
                        Icons.code,
                        tooltip: 'Monospace  ```text```',
                        onTap: () => _wrapBodyFormat(
                          '```',
                          '```',
                          placeholder: 'code',
                        ),
                      ),
                      _fmtIcon(
                        Icons.format_list_numbered,
                        tooltip: 'Numbered list',
                        onTap: _insertNumberedLine,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _insertNextVariable,
                        style: TextButton.styleFrom(
                          foregroundColor: _primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          '+ Add variable',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            'WhatsApp formatting:\n*bold*  _italic_  ~strike~\n```code```  {{1}} variable',
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              if (_showEmojiPanel) _buildEmojiPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPanel() {
    final cols = MediaQuery.sizeOf(context).width < 420 ? 6 : 8;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 160),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
        color: Color(0xFFF8FAFC),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: _emojiList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (_, i) {
          final emoji = _emojiList[i];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _insertAtCursor(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }

  Widget _fmtIcon(
    IconData icon, {
    required VoidCallback onTap,
    String? tooltip,
    bool active = false,
  }) {
    final btn = IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 18,
        color: active ? _primary : _muted,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
    return btn;
  }

  // ─── Body formatting helpers ──────────────────────────────────────────────

  int _nextVariableIndex() {
    final matches = RegExp(r'\{\{(\d+)\}\}').allMatches(_bodyCtrl.text);
    var max = 0;
    for (final m in matches) {
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  void _insertNextVariable() {
    final n = _nextVariableIndex();
    final token = '{{$n}}';
    final text = _bodyCtrl.text;
    final sel = _bodyCtrl.selection;
    final at = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final needSpace = at > 0 && text[at - 1] != ' ' && text[at - 1] != '\n';
    _insertAtCursor(needSpace ? ' $token' : token);
  }

  void _insertNumberedLine() {
    final text = _bodyCtrl.text;
    final sel = _bodyCtrl.selection;
    final offset = sel.isValid ? sel.start.clamp(0, text.length) : text.length;

    // Count existing numbered lines like "1. "
    final lines = text.split('\n');
    var nextNum = 1;
    for (final line in lines) {
      final m = RegExp(r'^(\d+)\.\s').firstMatch(line.trimLeft());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n >= nextNum) nextNum = n + 1;
      }
    }

    final prefix = text.isEmpty || offset == 0 || text[offset - 1] == '\n'
        ? '$nextNum. '
        : '\n$nextNum. ';
    _insertAtCursor(prefix);
  }

  void _insertAtCursor(String value) {
    final text = _bodyCtrl.text;
    var start = _bodyCtrl.selection.start;
    var end = _bodyCtrl.selection.end;
    if (!_bodyCtrl.selection.isValid) {
      start = end = text.length;
    }
    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);

    final next = text.replaceRange(start, end, value);
    if (next.length > 1024) return;

    _bodyCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    _bodyFocus.requestFocus();
    setState(() {});
  }

  void _wrapBodyFormat(
    String left,
    String right, {
    String placeholder = 'text',
  }) {
    final text = _bodyCtrl.text;
    var start = _bodyCtrl.selection.start;
    var end = _bodyCtrl.selection.end;
    if (!_bodyCtrl.selection.isValid) {
      start = end = text.length;
    }
    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);
    if (start > end) {
      final t = start;
      start = end;
      end = t;
    }

    // Toggle off if already wrapped
    if (start >= left.length &&
        end + right.length <= text.length &&
        text.substring(start - left.length, start) == left &&
        text.substring(end, end + right.length) == right) {
      final inner = text.substring(start, end);
      final next = text.replaceRange(
        start - left.length,
        end + right.length,
        inner,
      );
      _bodyCtrl.value = TextEditingValue(
        text: next,
        selection: TextSelection(
          baseOffset: start - left.length,
          extentOffset: start - left.length + inner.length,
        ),
      );
      _bodyFocus.requestFocus();
      setState(() {});
      return;
    }

    final selected = start == end ? placeholder : text.substring(start, end);
    final wrapped = '$left$selected$right';
    final next = text.replaceRange(start, end, wrapped);
    if (next.length > 1024) return;

    final selStart = start + left.length;
    final selEnd = selStart + selected.length;
    _bodyCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection(baseOffset: selStart, extentOffset: selEnd),
    );
    _bodyFocus.requestFocus();
    setState(() {});
  }

  /// Renders WhatsApp-style markers: *bold* _italic_ ~strike~ ```code``` and {{n}}.
  List<InlineSpan> _parseWhatsAppSpans(
    String input, {
    TextStyle? base,
  }) {
    final style = base ??
        const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: _ink,
          fontWeight: FontWeight.w600,
        );
    if (input.isEmpty) return [TextSpan(text: '', style: style)];

    final pattern = RegExp(
      r'(\{\{\d+\}\})'
      r'|(\*[^*\n]+\*)'
      r'|(_[^_\n]+_)'
      r'|(~[^~\n]+~)'
      r'|(```[^`]+```)',
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in pattern.allMatches(input)) {
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: input.substring(cursor, m.start),
          style: style,
        ));
      }
      final token = m.group(0)!;
      if (token.startsWith('{{')) {
        spans.add(TextSpan(
          text: token,
          style: style.copyWith(
            color: _primary,
            fontWeight: FontWeight.w800,
            backgroundColor: _primarySoft,
          ),
        ));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: style.copyWith(fontWeight: FontWeight.w900),
        ));
      } else if (token.startsWith('_') && token.endsWith('_')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('~') && token.endsWith('~')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: style.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (token.startsWith('```') && token.endsWith('```')) {
        spans.add(TextSpan(
          text: token.substring(3, token.length - 3),
          style: style.copyWith(
            fontFamily: 'monospace',
            backgroundColor: const Color(0xFFF1F5F9),
            fontWeight: FontWeight.w500,
          ),
        ));
      } else {
        spans.add(TextSpan(text: token, style: style));
      }
      cursor = m.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: style));
    }
    return spans;
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Footer · Optional',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            Text(
              '${_footerCtrl.text.length}/60',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _footerCtrl,
          maxLength: 60,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          decoration: _fieldDeco(
            hint: 'Add a short line of text to the bottom of your message in English.',
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsSection() {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final addBtn = PopupMenuButton<_ButtonKind>(
      onSelected: (kind) {
        if (_buttons.length >= 10) return;
        setState(() {
          _buttons.add(
            _TemplateButton(
              kind: kind,
              text: kind == _ButtonKind.visitWebsite
                  ? 'Visit website'
                  : kind == _ButtonKind.callPhone
                      ? 'Call phone number'
                      : kind == _ButtonKind.copyOffer
                          ? 'Copy offer code'
                          : '',
            ),
          );
        });
      },
      itemBuilder: (_) => [
        _btnMenu(_ButtonKind.custom, Icons.reply_rounded, 'Custom'),
        _btnMenu(
          _ButtonKind.visitWebsite,
          Icons.open_in_new_rounded,
          'Visit website',
        ),
        _btnMenu(
          _ButtonKind.callPhone,
          Icons.phone_outlined,
          'Call Phone Number',
        ),
        _btnMenu(
          _ButtonKind.copyOffer,
          Icons.copy_rounded,
          'Copy offer code',
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: _primary),
            const SizedBox(width: 4),
            Text(
              'Add button',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _primary,
                fontSize: 13,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: _primary),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (narrow) ...[
          const Text(
            'Buttons · Optional',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create buttons that let customers respond to your message or take action. You can add up to ten buttons. If you add more than three buttons, they will appear in a list.',
            style: TextStyle(fontSize: 12, height: 1.4, color: _muted),
          ),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: addBtn),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buttons · Optional',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create buttons that let customers respond to your message or take action. You can add up to ten buttons. If you add more than three buttons, they will appear in a list.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              addBtn,
            ],
          ),
        const SizedBox(height: 12),
        for (var i = 0; i < _buttons.length; i++) ...[
          _buildButtonCard(i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  PopupMenuItem<_ButtonKind> _btnMenu(
    _ButtonKind kind,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: kind,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _muted),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  /// Side-by-side on wide, stacked on narrow — avoids Row overflow on phones.
  Widget _responsivePair(Widget a, Widget b, {double gap = 12}) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              a,
              SizedBox(height: gap),
              b,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            SizedBox(width: gap),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  Widget _buildButtonCard(int index) {
    final b = _buttons[index];
    final urlText = b.urlCtrl.text.trim();
    final parsedUrl = urlText.isEmpty ? null : Uri.tryParse(urlText);
    final urlInvalid = b.kind == _ButtonKind.visitWebsite &&
        urlText.isNotEmpty &&
        (parsedUrl == null || !parsedUrl.hasScheme);
    final urlEmpty = b.kind == _ButtonKind.visitWebsite &&
        urlText.isEmpty &&
        b.textCtrl.text.isNotEmpty;
    final phoneEmpty =
        b.kind == _ButtonKind.callPhone && b.phoneCtrl.text.trim().isEmpty;
    final offerEmpty =
        b.kind == _ButtonKind.copyOffer && b.offerCtrl.text.trim().isEmpty;

    final showUrlError = urlInvalid ||
        (urlEmpty && b.textCtrl.text.trim().isNotEmpty);
    final showPhoneError = phoneEmpty && b.textCtrl.text.trim().isNotEmpty;
    final showOfferError = offerEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _buttons[index].dispose();
                    _buttons.removeAt(index);
                  });
                },
                child: const Icon(Icons.close, size: 18, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (b.kind == _ButtonKind.custom)
            _responsivePair(_actionTypeDropdown(b), _buttonTextField(b))
          else if (b.kind == _ButtonKind.visitWebsite) ...[
            _responsivePair(_actionTypeDropdown(b), _buttonTextField(b)),
            const SizedBox(height: 12),
            _responsivePair(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'URL type',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: b.urlType,
                    isExpanded: true,
                    decoration: _fieldDeco(),
                    items: const [
                      DropdownMenuItem(value: 'static', child: Text('static')),
                      DropdownMenuItem(value: 'dynamic', child: Text('dynamic')),
                    ],
                    onChanged: (v) => setState(() => b.urlType = v ?? 'static'),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Website URL',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: b.urlCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDeco(
                      hint: 'https://',
                      error: showUrlError,
                    ),
                  ),
                  if (showUrlError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Enter a valid website URL.',
                        style: TextStyle(fontSize: 11, color: _error),
                      ),
                    ),
                ],
              ),
            ),
          ] else if (b.kind == _ButtonKind.callPhone) ...[
            _responsivePair(_actionTypeDropdown(b), _buttonTextField(b)),
            const SizedBox(height: 12),
            _responsivePair(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Country',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: b.country,
                    isExpanded: true,
                    decoration: _fieldDeco(),
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                      DropdownMenuItem(value: '+1', child: Text('+1')),
                      DropdownMenuItem(value: '+44', child: Text('+44')),
                    ],
                    onChanged: (v) => setState(() => b.country = v ?? '+91'),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phone number',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: b.phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDeco(error: showPhoneError),
                  ),
                  if (showPhoneError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'You need to enter a phone number. Please add a valid phone number.',
                        style: TextStyle(fontSize: 11, color: _error),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            _responsivePair(
              _actionTypeDropdown(b),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer code',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: b.offerCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDeco(
                      hint: 'e.g. SAVE20',
                      error: showOfferError,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionTypeDropdown(_TemplateButton b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type of action',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<_ButtonKind>(
          value: b.kind,
          isExpanded: true,
          decoration: _fieldDeco(),
          items: const [
            DropdownMenuItem(
              value: _ButtonKind.custom,
              child: Text('Custom', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: _ButtonKind.visitWebsite,
              child: Text('Visit website', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: _ButtonKind.callPhone,
              child: Text('Call Phone Number', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: _ButtonKind.copyOffer,
              child: Text('Copy offer code', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => b.kind = v);
          },
        ),
      ],
    );
  }

  Widget _buttonTextField(_TemplateButton b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Button text',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ),
            Text(
              '${b.textCtrl.text.length}/25',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: b.textCtrl,
          maxLength: 25,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          onChanged: (_) => setState(() {}),
          decoration: _fieldDeco(),
        ),
      ],
    );
  }

  // ─── Live preview (edit) ──────────────────────────────────────────────────

  Widget _buildLivePreviewCard() {
    final body = _bodyCtrl.text.trim().isEmpty ? 'Hello' : _bodyCtrl.text;
    final footer =
        _footerCtrl.text.trim().isEmpty ? null : _footerCtrl.text.trim();
    final headerText = _headerMedia == _HeaderMedia.text &&
            _headerTextCtrl.text.trim().isNotEmpty
        ? _headerTextCtrl.text.trim()
        : null;

    final previewButtons = <(IconData, String)>[];
    for (final b in _buttons) {
      final label = b.textCtrl.text.trim().isEmpty
          ? (b.kind == _ButtonKind.visitWebsite
              ? 'Visit website'
              : b.kind == _ButtonKind.callPhone
                  ? 'Call phone number'
                  : b.kind == _ButtonKind.copyOffer
                      ? 'Copy offer code'
                      : 'Quick reply')
          : b.textCtrl.text.trim();
      IconData icon;
      switch (b.kind) {
        case _ButtonKind.custom:
          icon = Icons.reply_rounded;
        case _ButtonKind.visitWebsite:
          icon = Icons.open_in_new_rounded;
        case _ButtonKind.callPhone:
          icon = Icons.phone_outlined;
        case _ButtonKind.copyOffer:
          icon = Icons.copy_rounded;
      }
      if (b.kind != _ButtonKind.custom) {
        previewButtons.add((icon, label));
      }
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 14),
          _chatShell(
            child: _messageBubble(
              showImage: false,
              headerText: headerText,
              headerMedia: _headerMedia,
              body: body,
              footer: footer,
              buttons: previewButtons,
              time: TimeOfDay.now().format(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preview widgets ──────────────────────────────────────────────────────

  Widget _chatShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _previewBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _ChatPatternPainter(),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth.isFinite ? c.maxWidth.clamp(0.0, 320.0) : 320.0;
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: w, child: child),
            );
          },
        ),
      ),
    );
  }

  Widget _messageBubble({
    required bool showImage,
    required String? headerText,
    required _HeaderMedia headerMedia,
    required String body,
    required String? footer,
    required List<(IconData, String)> buttons,
    required String time,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, 320.0)
            : 320.0;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
            if (showImage || headerMedia == _HeaderMedia.image)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: showImage
                      ? Image.network(
                          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=640&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              )
            else if (headerMedia == _HeaderMedia.video)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: const Color(0xFFD0D5DD),
                  alignment: Alignment.center,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: _primary, size: 28),
                  ),
                ),
              )
            else if (headerMedia == _HeaderMedia.document)
              Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: _primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'PDF · attachment',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (headerText != null) ...[
                    Text(
                      headerText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text.rich(
                    TextSpan(
                      children: _parseWhatsAppSpans(body),
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      footer,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            for (final btn in buttons) ...[
              const Divider(height: 1, color: _line),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(btn.$1, size: 15, color: _primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        btn.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCE8D5), Color(0xFFF5E6B8)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'Image header',
        style: TextStyle(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final narrow = MediaQuery.sizeOf(context).width < 400;
    final hPad = narrow ? 12.0 : 20.0;
    final btnPadH = narrow ? 14.0 : 22.0;
    final nextPadH = narrow ? 16.0 : 28.0;
    final nextLabel = _step == 2
        ? (narrow ? 'Submit' : 'Submit for Review')
        : 'Next';

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () {
                    if (_step == 0) {
                      Navigator.maybePop(context);
                    } else {
                      setState(() => _step--);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line),
                    padding: EdgeInsets.symmetric(
                      horizontal: btnPadH,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _step == 0 ? 'Discard' : 'Back',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_step < 2) _step++;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: nextPadH,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    nextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painters ───────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(10),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const step = 42.0;
    for (var y = 12.0; y < size.height; y += step) {
      for (var x = 12.0; x < size.width; x += step) {
        final i = ((x + y) / step).floor() % 4;
        final c = Offset(x, y);
        switch (i) {
          case 0:
            canvas.drawCircle(c, 4, paint);
          case 1:
            canvas.drawRect(
              Rect.fromCenter(center: c, width: 7, height: 7),
              paint,
            );
          case 2:
            canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), paint);
            canvas.drawLine(c.translate(0, -4), c.translate(0, 4), paint);
          default:
            canvas.drawOval(
              Rect.fromCenter(center: c, width: 8, height: 5),
              paint,
            );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
