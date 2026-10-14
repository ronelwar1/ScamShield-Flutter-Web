import 'package:flutter/material.dart';

void main() => runApp(const ScamShieldApp());

const Color maroon = Color(0xFF6F1628);
const Color deepMaroon = Color(0xFF4A0D1C);
const Color pageBackground = Color(0xFFF8F6F7);
const Color softMaroon = Color(0xFFF5E9ED);
const Color lineColor = Color(0xFFE9E0E3);
const Color textColor = Color(0xFF292226);
const Color mutedText = Color(0xFF7B7075);

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon, primary: maroon),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: maroon, width: 1.5),
          ),
        ),
      ),
      home: const ScamShieldHome(),
    );
  }
}

enum AppPage { chat, login, register }

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class ScamShieldHome extends StatefulWidget {
  const ScamShieldHome({super.key});

  @override
  State<ScamShieldHome> createState() => _ScamShieldHomeState();
}

class _ScamShieldHomeState extends State<ScamShieldHome> {
  AppPage _page = AppPage.chat;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _obscurePassword = true;
  String _accountEmail = '';
  String? _authNotice;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPage(AppPage page) {
    setState(() {
      _page = page;
      _authNotice = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _submitAuth() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isRegister = _page == AppPage.register;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _authNotice = 'Enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _authNotice = 'Enter your password to continue.');
      return;
    }
    if (password.length < 8) {
      setState(() => _authNotice = 'Password must be at least 8 characters.');
      return;
    }

    // UI-only authentication: connect this action to your real auth backend.
    setState(() {
      _accountEmail = email;
      _authNotice = isRegister
          ? 'Registration form completed. Connect the authentication backend to create your account.'
          : 'Sign-in form completed. Connect the authentication backend to verify your account.';
    });
  }

  void _continueAsGuest() {
    setState(() {
      _page = AppPage.chat;
      _authNotice = null;
      _accountEmail = '';
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Honest placeholder until the real ScamShield classifier is connected.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text:
                'I received your message. The ScamShield classification model is not connected yet, so I cannot provide a reliable scam verdict or risk level. Please verify suspicious links and requests through an official source before acting.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearConversation() {
    setState(() {
      _messages.clear();
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_page == AppPage.login || _page == AppPage.register) {
      return _buildAuthPage(isRegister: _page == AppPage.register);
    }
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 258, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isWide),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                          itemCount: _messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isSending && index == _messages.length) {
                              return const _TypingIndicator();
                            }
                            return _MessageBubble(message: _messages[index]);
                          },
                        ),
                ),
                _buildComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPage({required bool isRegister}) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: EdgeInsets.all(isWide ? 34 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: lineColor),
                  boxShadow: [
                    BoxShadow(
                      color: deepMaroon.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: maroon,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 33),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ScamShield',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: deepMaroon,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      isRegister ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      isRegister
                          ? 'Register with your email to get started.'
                          : 'Sign in with your email to continue.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: mutedText, fontSize: 12.5, height: 1.5),
                    ),
                    const SizedBox(height: 27),
                    const Text(
                      'Email address',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded, color: mutedText, size: 20),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: isRegister
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      onSubmitted: (_) => _submitAuth(),
                      decoration: InputDecoration(
                        hintText: isRegister ? 'At least 8 characters' : 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: mutedText, size: 20),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: mutedText,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_authNotice != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softMaroon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _authNotice!,
                          style: const TextStyle(color: deepMaroon, fontSize: 12, height: 1.45),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _submitAuth,
                        style: FilledButton.styleFrom(
                          backgroundColor: maroon,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isRegister ? 'Create account' : 'Sign in',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            isRegister ? 'Already have an account?' : "Don't have an account?",
                            style: const TextStyle(color: mutedText, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPage(isRegister ? AppPage.login : AppPage.register),
                          child: Text(
                            isRegister ? 'Sign in' : 'Register',
                            style: const TextStyle(color: maroon, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: _continueAsGuest,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Continue as guest'),
                        style: TextButton.styleFrom(foregroundColor: mutedText),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Account creation and sign-in need a connected authentication service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText, fontSize: 10.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: deepMaroon,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 23, 18, 25),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.shield_rounded, color: maroon, size: 27),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'ScamShield',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _SidebarItem(
                icon: Icons.add_rounded,
                label: 'New chat',
                outlined: true,
                onTap: _clearConversation,
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 11),
              child: Text('CHAT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
            ),
            _SidebarItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Current conversation',
              selected: true,
              onTap: () {},
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: Colors.white24, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 16, 19, 19),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.person_outline, color: maroon),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _accountEmail.isEmpty ? 'Guest' : _accountEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        const Text('ScamShield account', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign in or register',
                    onPressed: () => _showPage(AppPage.login),
                    icon: const Icon(Icons.login_rounded, color: Colors.white70, size: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: maroon,
        border: Border(bottom: BorderSide(color: deepMaroon, width: 1)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                tooltip: 'Open navigation',
              ),
            ),
            const SizedBox(width: 3),
          ],
          const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 11),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ScamShield Chat', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Suspicious message screening', style: TextStyle(color: Color(0xFFEBDDE1), fontSize: 11)),
            ],
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width > 570) ...[
            TextButton.icon(
              onPressed: () => _showPage(AppPage.login),
              icon: const Icon(Icons.login_rounded, size: 17),
              label: const Text('Sign in'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x80FFFFFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 9),
            FilledButton(
              onPressed: () => _showPage(AppPage.register),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: maroon,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ] else
            IconButton(
              tooltip: 'Sign in',
              onPressed: () => _showPage(AppPage.login),
              icon: const Icon(Icons.login_rounded, color: Colors.white),
            ),
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _clearConversation,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: maroon,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(color: maroon.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 22),
              const Text(
                'How can I help you today?',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.7),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste a suspicious message below to start a conversation with ScamShield.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      width: double.infinity,
      color: pageBackground,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0D3D8)),
              boxShadow: [
                BoxShadow(color: maroon.withValues(alpha: 0.045), blurRadius: 18, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 0, 17),
                  child: Icon(Icons.message_outlined, color: Color(0xFF9B8790), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Message ScamShield...',
                      hintStyle: TextStyle(color: Color(0xFF9B8E93), fontSize: 13),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 18),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: IconButton(
                    tooltip: 'Send message',
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: maroon,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 21),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool outlined;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovering;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_hovering ? Colors.white.withValues(alpha: 0.14) : Colors.transparent)
                : (highlighted ? Colors.white.withValues(alpha: widget.selected ? 0.15 : 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: widget.outlined ? Colors.white.withValues(alpha: 0.38) : Colors.transparent),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 19, color: Colors.white.withValues(alpha: highlighted ? 1 : 0.72)),
                    const SizedBox(width: 11),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(color: maroon, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isUser ? maroon : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 16),
                ),
                border: isUser ? null : Border.all(color: lineColor),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: isUser ? Colors.white : textColor, fontSize: 13, height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 45, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: lineColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: maroon)),
              SizedBox(width: 10),
              Text('Sending...', style: TextStyle(color: mutedText, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
