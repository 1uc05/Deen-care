import 'package:flutter/material.dart';
import '../../models/voice_call_state.dart';

class VoiceCallButton extends StatelessWidget {
  final VoiceCallState state;
  final VoidCallback? onPressed;
  final bool enabled;

  const VoiceCallButton({
    super.key,
    required this.state,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          elevation: enabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: _getIcon(),
        label: Text(
          _getButtonText(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Retourne la couleur de fond selon l'état
  Color _getBackgroundColor() {
    if (!enabled) return Colors.grey;
    
    switch (state) {
      case VoiceCallState.idle:
        return const Color(0xFF4CAF50); // Vert pour "Appeler"
      case VoiceCallState.calling:
        return const Color(0xFFFF9800); // Orange pour "En cours"
      case VoiceCallState.connected:
        return const Color(0xFFF44336); // Rouge pour "Raccrocher"
    }
  }

  /// Retourne l'icône selon l'état
  Widget _getIcon() {
    switch (state) {
      case VoiceCallState.idle:
        return const Icon(Icons.call, size: 20);
      case VoiceCallState.calling:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case VoiceCallState.connected:
        return const Icon(Icons.call_end, size: 20);
    }
  }

  /// Retourne le texte du bouton selon l'état
  String _getButtonText() {
    switch (state) {
      case VoiceCallState.idle:
        return 'Démarrer l\'appel vocal';
      case VoiceCallState.calling:
        return 'Connexion en cours...';
      case VoiceCallState.connected:
        return 'Terminer l\'appel';
    }
  }
}

/// Version compacte pour usage dans d'autres contextes
class CompactVoiceCallButton extends StatelessWidget {
  final VoiceCallState state;
  final VoidCallback? onPressed;
  final bool enabled;

  const CompactVoiceCallButton({
    super.key,
    required this.state,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: enabled ? onPressed : null,
        backgroundColor: _getBackgroundColor(),
        disabledElevation: 0,
        child: _getIcon(),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!enabled) return Colors.grey;
    
    switch (state) {
      case VoiceCallState.idle:
        return const Color(0xFF4CAF50);
      case VoiceCallState.calling:
        return const Color(0xFFFF9800);
      case VoiceCallState.connected:
        return const Color(0xFFF44336);
    }
  }

  Widget _getIcon() {
    switch (state) {
      case VoiceCallState.idle:
        return const Icon(Icons.call, color: Colors.white);
      case VoiceCallState.calling:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case VoiceCallState.connected:
        return const Icon(Icons.call_end, color: Colors.white);
    }
  }
}
