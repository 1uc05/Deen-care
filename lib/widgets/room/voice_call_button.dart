import 'package:caunvo/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/voice_call_state.dart';

class VoiceCallButton extends StatelessWidget {
  final VoiceCallState state;
  final VoidCallback? onPressed;
  final bool enabled;
  
  // Nouveaux paramètres pour le haut-parleur
  final bool isSpeakerOn;
  final VoidCallback? onSpeakerToggle;

  const VoiceCallButton({
    super.key,
    required this.state,
    this.onPressed,
    this.enabled = true,
    this.isSpeakerOn = false,
    this.onSpeakerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Bouton principal d'appel
            Expanded(
              child: SizedBox(
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
              ),
            ),
            
            // Bouton haut-parleur
            if (state == VoiceCallState.connected && onSpeakerToggle != null) ...[
              const SizedBox(width: 12),
              _buildModernSpeakerButton(),
            ],
          ],
        ),
      ],
    );
  }

  /// Bouton haut-parleur moderne et discret
  Widget _buildModernSpeakerButton() {
    return Tooltip(
      message: isSpeakerOn ? 'Désactiver le haut-parleur' : 'Activer le haut-parleur',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSpeakerOn 
            ? AppColors.primaryLight
            : Colors.grey[50],
          border: Border.all(
            color: isSpeakerOn 
              ? AppColors.primary
              : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onSpeakerToggle : null,
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              size: 20,
              color: isSpeakerOn 
                ? AppColors.primary
                : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// Retourne la couleur de fond selon l'état
  Color _getBackgroundColor() {
    if (!enabled) return AppColors.noStatus;
    
    switch (state) {
      case VoiceCallState.idle:
        return AppColors.secondary;
      case VoiceCallState.calling:
        return AppColors.accent;
      case VoiceCallState.connected:
        return AppColors.error;
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