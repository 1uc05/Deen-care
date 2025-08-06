import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;

  void goToHome() => setIndex(0);
  void goToTextes() => setIndex(1);
  void goToCalendar() => setIndex(2);
  void goToRoom() => setIndex(3);
  void setIndex(int index) => _setIndex(index);

  void _setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
