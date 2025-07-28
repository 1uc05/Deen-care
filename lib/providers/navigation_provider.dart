import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;

  void goToHome() => setIndex(0);
  void goToCalendar() => setIndex(1);
  void goToSalon() => setIndex(2);
  void setIndex(int index) => _setIndex(index);

  void _setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
