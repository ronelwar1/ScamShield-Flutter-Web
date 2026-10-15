import 'package:flutter/material.dart';

void main() {
  runApp(const ScamShieldApp());
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScamShield',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F1628),
        ),
        fontFamily: 'Arial',
      ),
      home: const ScamShieldHome(),
    );
  }
}

class ScamShieldHome extends StatefulWidget {
  const ScamShieldHome({super.key});

  @override
  State<ScamShieldHome> createState() => _ScamShieldHomeState();
}

class _ScamShieldHomeState extends State<ScamShieldHome> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'message': text,
      });

      _messages.add({
        'sender': 'bot',
        'message':
            'I received your message. Scam analysis will be connected to the ML model later.',
      });
    });

    _messageController.clear();
  }

  void _newChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Row(
        children: [
         
          Container(
            width: 250,
            color: const Color(0xFF4A0D1C),
            child: SafeArea(
              child: Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF6F1628),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ScamShield',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // New Chat button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _newChat,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'New Chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white54,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Recent section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _sidebarItem(
                    Icons.chat_bubble_outline,
                    'New conversation',
                  ),

                  _sidebarItem(
                    Icons.warning_amber_rounded,
                    'Suspicious message',
                  ),

                  _sidebarItem(
                    Icons.link,
                    'Prize link analysis',
                  ),

                  _sidebarItem(
                    Icons.account_balance_outlined,
                    'Bank SMS check',
                  ),

                  const Spacer(),

                  // Bottom options
                  _sidebarItem(
                    Icons.history,
                    'History',
                  ),

                  _sidebarItem(
                    Icons.settings_outlined,
                    'Settings',
                  ),

                  const Divider(
                    color: Colors.white24,
                    indent: 15,
                    endIndent: 15,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFF6F1628),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ScamShield',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A0D1C),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline),
                        tooltip: 'Help',
                      ),
                    ],
                  ),
                ),

                
                Expanded(
                  child: _messages.isEmpty
                      ? _welcomeScreen()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];

                            return _chatBubble(
                              message['message']!,
                              message['sender'] == 'user',
                            );
                          },
                        ),
                ),

                // Message input
                _messageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _sidebarItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {},
      ),
    );
  }

  
  Widget _welcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF6F1628),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'How can I help you?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Send a suspicious message and ScamShield will analyze it for potential scam indicators.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),

            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _exampleCard(
                  Icons.sms_outlined,
                  'Check an SMS',
                  'Analyze a suspicious text message',
                ),
                _exampleCard(
                  Icons.link,
                  'Check a link message',
                  'Look for suspicious link indicators',
                ),
                _exampleCard(
                  Icons.warning_amber_rounded,
                  'Assess risk',
                  'Get a risk level and classification',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _exampleCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF6F1628),
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // CHAT BUBBLE
  // =========================
  Widget _chatBubble(String message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6F1628),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield,
                color: Colors.white,
                size: 20,
              ),
            ),

          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6F1628)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFFE1E1E1),
                      ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // message input ni na part
  
  Widget _messageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: const Color(0xFFF7F7F8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 850,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFDADADA),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Ask ScamShield about a suspicious message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                  bottom: 8,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6F1628),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    Icons.arrow_upward,
                    size: 20,
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