import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool enabled;
  final String? placeholder;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.placeholder,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isMessageValid = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Détecte les changements dans le champ de texte
  void _onTextChanged() {
    final trimmedText = _textController.text.trim();
    final isValid = trimmedText.isNotEmpty;
    
    if (_isMessageValid != isValid) {
      setState(() {
        _isMessageValid = isValid;
      });
    }
  }

  /// Gère l'envoi du message
  Future<void> _handleSendMessage() async {
    if (!_isMessageValid || !widget.enabled) return;
    
    final message = _textController.text.trim();
    
    // Réinitialiser le champ immédiatement (UX responsive)
    _textController.clear();
    setState(() {
      _isMessageValid = false;
    });
    
    // Envoyer le message via callback
    widget.onSendMessage(message);
    
    // Remettre le focus sur le champ
    _focusNode.requestFocus();
  }

  /// Gère la saisie clavier (Enter pour envoyer)
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.enter && 
        !HardwareKeyboard.instance.isShiftPressed) {
      _handleSendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Champ de saisie
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: widget.enabled,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.enabled ? (_) => _handleSendMessage() : null,
                decoration: InputDecoration(
                  hintText: widget.enabled 
                      ? (widget.placeholder ?? 'Tapez votre message...')
                      : 'Chat non disponible',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          // Bouton d'envoi
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: (_isMessageValid && widget.enabled) 
                  ? _handleSendMessage 
                  : null,
              icon: Icon(
                Icons.send_rounded,
                color: (_isMessageValid && widget.enabled) 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[400],
              ),
              tooltip: 'Envoyer le message',
            ),
          ),
        ],
      ),
    );
  }
}

/// Version simple pour d'autres usages
class SimpleMessageInput extends StatelessWidget {
  final Function(String) onSendMessage;
  final bool enabled;
  final String? placeholder;

  const SimpleMessageInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: placeholder ?? 'Message...',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: enabled 
                ? (text) {
                    if (text.trim().isNotEmpty) {
                      onSendMessage(text.trim());
                      controller.clear();
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: enabled
              ? () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    onSendMessage(text);
                    controller.clear();
                  }
                }
              : null,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
