class StageSessionType {
  static const String adventure = 'adventure';
  static const String dailyChallenge = 'daily_challenge';

  static bool isDailyChallenge(String? value) {
    return value == dailyChallenge;
  }
}
