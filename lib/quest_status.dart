// lib/quest_status.dart
import 'user_progress_service.dart';

// In-memory only (no persistence). Everything resets when the app restarts.
class QuestStatus {
  // Progress / totals
  static int level = 1;
  static int streakDays = 0;
  static int chestsOpened = 0;

  // Save coalescing to avoid excessive Firestore writes
  static bool _saving = false;
  static bool _saveQueued = false;

  // ================= Content Keys & Level Thresholds =================
  static const String levelAlphabet = 'alphabet';
  static const String levelNumbers = 'numbers';
  static const String levelGreetings = 'greetings'; // Fruits (UI)
  static const String levelColour = 'colour';
  static const String levelCommonVerb = 'commonVerb'; // Animals (UI)
  static const String levelVerbs = 'verbs'; // Verbs (UI)
  static const String levelSpeech = 'speech'; // ✅ NEW: Speech (Medium tab)

  // Unlock requirements (Alphabet free, Numbers 5, Colour 10, Fruits 15, Animals 25, Verbs 30, Speech 35)
  static const Map<String, int> _unlockAtLevel = {
    levelAlphabet: 1,
    levelNumbers: 5,
    levelColour: 10,
    levelGreetings: 15,
    levelCommonVerb: 25,
    levelVerbs: 30,
    levelSpeech: 35, // ✅ NEW requirement
  };

  static int requiredLevelFor(String key) => _unlockAtLevel[key] ?? 1;
  static bool meetsLevelRequirement(String key) =>
      level >= requiredLevelFor(key);

  // ================= Per-correct XP rule =================
  static const int xpPerCorrect = 25;

  // ================= Level 1 (Alphabet) =================
  static List<bool?> level1Answers = List<bool?>.filled(5, null);
  static int get completedQuestions =>
      level1Answers.where((e) => e != null).length;
  static bool get level1Completed => level1Answers.every((e) => e != null);
  static int get level1Score => level1Answers.where((e) => e == true).length;

  /// Longest current streak of consecutive correct answers (Alphabet)
  static int get level1BestStreak {
    int best = 0, curr = 0;
    for (final v in level1Answers) {
      if (v == true) {
        curr++;
        if (curr > best) best = curr;
      } else {
        curr = 0;
      }
    }
    return best;
  }

  static void ensureLevel1Length(int length) {
    if (level1Answers.length != length) {
      final old = level1Answers;
      level1Answers = List<bool?>.filled(length, null);
      for (int i = 0; i < length && i < old.length; i++) {
        level1Answers[i] = old[i];
      }
    }
  }

  // ================= Keys / Quests (global state) =================
  static int userPoints = 0; // "keys"

  // ---- Watched items in learn mode (persistent storage)
  static Set<String> watchedAlphabet = {};
  static Set<String> watchedNumbers = {};
  static Set<String> watchedColours = {};
  static Set<String> watchedFruits = {};
  static Set<String> watchedAnimals = {};
  static Set<String> watchedVerbs = {};
  static Set<String> watchedSpeech = {}; // ✅ NEW (safe even if unused)

  // ---- Learning/quiz state flags & counters (across categories)
  // Alphabet
  static bool learnedAlphabetAll = false; // Q2
  static bool alphabetQuizStarted = false; // Q3
  static int alphabetRoundsCompleted = 0; // milestone

  // Numbers
  static bool learnedNumbersAll = false; // Q6
  static int numbersRoundsCompleted = 0; // Q8
  static int numbersPerfectRounds = 0; // Q7

  // Colour
  static bool learnedColoursAll = false; // Q10
  static int colourRoundsCompleted = 0; // Q12
  static int colourBestStreak = 0; // Q11

  // Fruits
  static bool learnedFruitsAll = false; // Q14
  static int fruitsRoundsCompleted = 0; // Q16
  static int fruitsBestStreak = 0; // Q15

  // Animals
  static bool learnedAnimalsAll = false; // Q18
  static int animalsRoundsCompleted = 0; // Q19
  static int animalsPerfectRounds = 0; // Q20

  // Verbs
  static bool learnedVerbsAll = false; // Q26
  static int verbsRoundsCompleted = 0; // Q27
  static int verbsPerfectRounds = 0; // Q28

  // (Optional) Speech flags for future use
  static bool playedSpeech = false; // ✅ NEW (prevents missing-member errors)

  // Misc tracker
  static bool firstQuizMedalEarned =
  false; // used by markFirstQuizMedalEarned()

  // ===== Counters & flags used by BadgeEngine and quiz screens =====
  static int quizzesCompleted = 0; // increment after each finished quiz
  static int perfectQuizzes = 0; // increment when a quiz is 100% correct

  // Track if the user has ever completed each mode at least once
  static bool completedMC = false;
  static bool completedMM = false;

  // Track if user has ever played these categories at least once
  static bool playedAlphabet = false;
  static bool playedNumbers = false;
  static bool playedColours = false;
  static bool playedFruits = false; // ✅ ADDED for fruits_q.dart

  // Set true in profile.dart when user sends feedback
  static bool feedbackSent = false;

  // ---- Helper setters to be called from Learning/Quiz screens:
  // (Calls to _autoClaimAll() are now no-op; kept for compatibility)
  // Alphabet helpers
  static void markAlphabetLearnAll() {
    learnedAlphabetAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void markAlphabetQuizStarted() {
    alphabetQuizStarted = true;
    markFirstQuizMedalEarned();
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incAlphabetRoundsCompleted() {
    alphabetRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // Numbers helpers
  static void markNumbersLearnAll() {
    learnedNumbersAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incNumbersRoundsCompleted() {
    numbersRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incNumbersPerfectRounds() {
    numbersPerfectRounds++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // Colour helpers
  static void markColoursLearnAll() {
    learnedColoursAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incColourRoundsCompleted() {
    colourRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void updateColourBestStreak(int streak) {
    if (streak > colourBestStreak) colourBestStreak = streak;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // Fruits helpers
  static void markFruitsLearnAll() {
    learnedFruitsAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incFruitsRoundsCompleted() {
    fruitsRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }
  static bool fruitsQuizStarted = false;

  static void markFruitsQuizStarted() {
    fruitsQuizStarted = true;
    // If you later add persistence (Firestore / SharedPreferences),
    // you can also save this flag here.
  }

  static void updateFruitsBestStreak(int streak) {
    if (streak > fruitsBestStreak) fruitsBestStreak = streak;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // Animals helpers
  static void markAnimalsLearnAll() {
    learnedAnimalsAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incAnimalsRoundsCompleted() {
    animalsRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incAnimalsPerfectRounds() {
    animalsPerfectRounds++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // Verbs helpers
  static void markVerbsLearnAll() {
    learnedVerbsAll = true;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incVerbsRoundsCompleted() {
    verbsRoundsCompleted++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  static void incVerbsPerfectRounds() {
    verbsPerfectRounds++;
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  /// Call this from any quiz when the user answers a question.
  /// Applies +25 XP for correct and then (no auto-claim; manual-claim only).
  static void onAnswer({required bool correct}) {
    if (correct) addXp(xpPerCorrect);
    _autoClaimAll();
    Future.microtask(() => autoSaveProgress());
  }

  // ================= Chest Progress (goal grows +20 per chest) =================
  static int claimedPoints =
  0; // progress within current chest tier (your UI shows this)
  static int levelGoalPoints = 30; // starting chest goal (first bar length)

  static double get chestProgress => levelGoalPoints == 0
      ? 0
      : (claimedPoints / levelGoalPoints).clamp(0.0, 1.0);

  // Each chest opened raises the next goal by +20
  static void advanceChestTier() {
    levelGoalPoints += 20;
    Future.microtask(() => autoSaveProgress());
  }

  static void _applyChestProgress(int progress) {
    if (progress <= 0) return;
    // Add progress ONLY. Do NOT auto-open chests here.
    // The chest will be opened manually via the UI button (_openChest).
    claimedPoints += progress;
    Future.microtask(() => autoSaveProgress());
  }

  // ================= Achievements =================
  static Set<String> achievements = <String>{};
  static bool awardAchievement(String name) {
    if (achievements.contains(name)) return false;
    achievements.add(name);
    Future.microtask(() => autoSaveProgress());
    return true;
  }

  // ================= XP / Level (XP to next grows +50/level) =================
  static int xp = 0;

  // Level bar rule: base 100, +50 per level-up step
  static int xpForLevel(int lvl) => 100 + (lvl - 1) * 50;
  static int get xpToNext => xpForLevel(level);
  static double get xpProgress => xpToNext == 0 ? 0 : xp / xpToNext;

  static int addXp(int amount) {
    int levelsUp = 0;
    if (amount <= 0) return 0;
    xp += amount;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      level += 1;
      levelsUp += 1;
      Future.microtask(() => autoSaveProgress());
    }
    Future.microtask(() => autoSaveProgress());
    return levelsUp;
  }

  // ================= Unlock Logic =================
  static bool isContentUnlocked(String key) {
    if (key == levelAlphabet) return true;
    return _unlockedContent.contains(key);
  }

  static bool isContentPurchasableNow(String key) {
    if (key == levelAlphabet) return true;
    return meetsLevelRequirement(key);
  }

  static const int unlockCost = 200;
  static final Set<String> _unlockedContent = <String>{};

  static Future<UnlockStatus> attemptUnlock(String key) async {
    if (key == levelAlphabet) return UnlockStatus.alreadyUnlocked;
    if (_unlockedContent.contains(key)) return UnlockStatus.alreadyUnlocked;

    if (level < requiredLevelFor(key)) return UnlockStatus.needLevel;
    if (userPoints < unlockCost) return UnlockStatus.needKeys;

    userPoints -= unlockCost;
    _unlockedContent.add(key);

    // No auto-claim; user must press CLAIM buttons.
    await autoSaveProgress();
    return UnlockStatus.success;
  }

  // ================= Quests (Q1 – Q28) with MANUAL claim =================
  // ---- Claimed flags
  static bool quest1Claimed = false; // Start Alphabet
  static bool quest2Claimed = false; // Learn ALL Alphabet
  static bool quest3Claimed = false; // Start Alphabet quiz
  static bool quest4Claimed = false; // 3 correct in a row (Alphabet)
  static bool quest5Claimed = false; // Start Numbers
  static bool quest6Claimed = false; // Learn ALL Numbers
  static bool quest7Claimed = false; // Numbers perfect round
  static bool quest8Claimed = false; // Finish 3 rounds Numbers
  static bool quest9Claimed = false; // Start Colour
  static bool quest10Claimed = false; // Learn ALL Colour
  static bool quest11Claimed = false; // 5-correct streak Colour
  static bool quest12Claimed = false; // Finish 2 rounds Colour
  static bool quest13Claimed = false; // Start Fruits
  static bool quest14Claimed = false; // Learn ALL Fruits
  static bool quest15Claimed = false; // 4-correct streak Fruits
  static bool quest16Claimed = false; // Finish 2 rounds Fruits
  static bool quest17Claimed = false; // Start Animals
  static bool quest18Claimed = false; // Learn ALL Animals
  static bool quest19Claimed = false; // Finish 3 rounds Animals
  static bool quest20Claimed = false; // 1 perfect round Animals
  static bool quest21Claimed = false; // Open 3 chests
  static bool quest22Claimed = false; // Reach Level 10
  static bool quest23Claimed = false; // Unlock all categories (original 5)
  static bool quest24Claimed = false; // Reach Level 25
  static bool quest25Claimed = false; // Start Verbs
  static bool quest26Claimed = false; // Learn ALL Verbs
  static bool quest27Claimed = false; // Finish 2 rounds Verbs
  static bool quest28Claimed = false; // 1 perfect round Verbs

  // ---- Conditions & Claims (Rewards tuned to help reach L25)
  static bool canClaimQuest1() => completedQuestions >= 1 && !quest1Claimed;
  static int claimQuest1({int reward = 100, int progress = 15}) {
    if (!canClaimQuest1()) return 0;
    quest1Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest2() => learnedAlphabetAll && !quest2Claimed;
  static int claimQuest2({int reward = 120, int progress = 15}) {
    if (!canClaimQuest2()) return 0;
    quest2Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest3() => alphabetQuizStarted && !quest3Claimed;
  static int claimQuest3({int reward = 80, int progress = 10}) {
    if (!canClaimQuest3()) return 0;
    quest3Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(60);
    return reward;
  }

  static bool canClaimQuest4() => level1BestStreak >= 3 && !quest4Claimed;
  static int claimQuest4({int reward = 120, int progress = 15}) {
    if (!canClaimQuest4()) return 0;
    quest4Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(100);
    return reward;
  }

  static bool canClaimQuest5() =>
      isContentUnlocked(levelNumbers) && !quest5Claimed;
  static int claimQuest5({int reward = 100, int progress = 15}) {
    if (!canClaimQuest5()) return 0;
    quest5Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest6() => learnedNumbersAll && !quest6Claimed;
  static int claimQuest6({int reward = 120, int progress = 15}) {
    if (!canClaimQuest6()) return 0;
    quest6Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest7() => numbersPerfectRounds >= 1 && !quest7Claimed;
  static int claimQuest7({int reward = 200, int progress = 20}) {
    if (!canClaimQuest7()) return 0;
    quest7Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(160);
    return reward;
  }

  static bool canClaimQuest8() => numbersRoundsCompleted >= 3 && !quest8Claimed;
  static int claimQuest8({int reward = 200, int progress = 20}) {
    if (!canClaimQuest8()) return 0;
    quest8Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(150);
    return reward;
  }

  static bool canClaimQuest9() =>
      isContentUnlocked(levelColour) && !quest9Claimed;
  static int claimQuest9({int reward = 100, int progress = 15}) {
    if (!canClaimQuest9()) return 0;
    quest9Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest10() => learnedColoursAll && !quest10Claimed;
  static int claimQuest10({int reward = 120, int progress = 15}) {
    if (!canClaimQuest10()) return 0;
    quest10Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest11() => colourBestStreak >= 5 && !quest11Claimed;
  static int claimQuest11({int reward = 150, int progress = 15}) {
    if (!canClaimQuest11()) return 0;
    quest11Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(100);
    return reward;
  }

  static bool canClaimQuest12() =>
      colourRoundsCompleted >= 2 && !quest12Claimed;
  static int claimQuest12({int reward = 200, int progress = 20}) {
    if (!canClaimQuest12()) return 0;
    quest12Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(150);
    return reward;
  }

  static bool canClaimQuest13() =>
      isContentUnlocked(levelGreetings) && !quest13Claimed;
  static int claimQuest13({int reward = 100, int progress = 15}) {
    if (!canClaimQuest13()) return 0;
    quest13Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest14() => learnedFruitsAll && !quest14Claimed;
  static int claimQuest14({int reward = 120, int progress = 15}) {
    if (!canClaimQuest14()) return 0;
    quest14Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest15() => fruitsBestStreak >= 4 && !quest15Claimed;
  static int claimQuest15({int reward = 150, int progress = 15}) {
    if (!canClaimQuest15()) return 0;
    quest15Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(100);
    return reward;
  }

  static bool canClaimQuest16() =>
      fruitsRoundsCompleted >= 2 && !quest16Claimed;
  static int claimQuest16({int reward = 200, int progress = 20}) {
    if (!canClaimQuest16()) return 0;
    quest16Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(150);
    return reward;
  }

  static bool canClaimQuest17() =>
      isContentUnlocked(levelCommonVerb) && !quest17Claimed;
  static int claimQuest17({int reward = 100, int progress = 15}) {
    if (!canClaimQuest17()) return 0;
    quest17Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest18() => learnedAnimalsAll && !quest18Claimed;
  static int claimQuest18({int reward = 120, int progress = 15}) {
    if (!canClaimQuest18()) return 0;
    quest18Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest19() =>
      animalsRoundsCompleted >= 3 && !quest19Claimed;
  static int claimQuest19({int reward = 150, int progress = 20}) {
    if (!canClaimQuest19()) return 0;
    quest19Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(150);
    return reward;
  }

  static bool canClaimQuest20() => animalsPerfectRounds >= 1 && !quest20Claimed;
  static int claimQuest20({int reward = 200, int progress = 20}) {
    if (!canClaimQuest20()) return 0;
    quest20Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(180);
    return reward;
  }

  static bool canClaimQuest21() => chestsOpened >= 3 && !quest21Claimed;
  static int claimQuest21({int reward = 150, int progress = 20}) {
    if (!canClaimQuest21()) return 0;
    quest21Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(120);
    return reward;
  }

  static bool canClaimQuest22() => level >= 10 && !quest22Claimed;
  static int claimQuest22({int reward = 150, int progress = 20}) {
    if (!canClaimQuest22()) return 0;
    quest22Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(120);
    return reward;
  }

  static bool canClaimQuest23() =>
      isContentUnlocked(levelNumbers) &&
          isContentUnlocked(levelColour) &&
          isContentUnlocked(levelGreetings) &&
          isContentUnlocked(levelCommonVerb) &&
          isContentUnlocked(levelVerbs) &&
          !quest23Claimed;

  static int claimQuest23({int reward = 200, int progress = 20}) {
    if (!canClaimQuest23()) return 0;
    quest23Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(160);
    return reward;
  }

  static bool canClaimQuest24() => level >= 25 && !quest24Claimed;
  static int claimQuest24({int reward = 300, int progress = 30}) {
    if (!canClaimQuest24()) return 0;
    quest24Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(200);
    return reward;
  }

  static bool canClaimQuest25() =>
      isContentUnlocked(levelVerbs) && !quest25Claimed;
  static int claimQuest25({int reward = 100, int progress = 15}) {
    if (!canClaimQuest25()) return 0;
    quest25Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(50);
    return reward;
  }

  static bool canClaimQuest26() => learnedVerbsAll && !quest26Claimed;
  static int claimQuest26({int reward = 120, int progress = 15}) {
    if (!canClaimQuest26()) return 0;
    quest26Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(80);
    return reward;
  }

  static bool canClaimQuest27() => verbsRoundsCompleted >= 2 && !quest27Claimed;
  static int claimQuest27({int reward = 150, int progress = 20}) {
    if (!canClaimQuest27()) return 0;
    quest27Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(150);
    return reward;
  }

  static bool canClaimQuest28() => verbsPerfectRounds >= 1 && !quest28Claimed;
  static int claimQuest28({int reward = 200, int progress = 20}) {
    if (!canClaimQuest28()) return 0;
    quest28Claimed = true;
    userPoints += reward;
    _applyChestProgress(progress);
    addXp(180);
    return reward;
  }

  // ================== AUTO-CLAIM DISABLED ==================
  static void _autoClaimAll() {
    // Manual-claim only. Do not auto-claim anything here.
    Future.microtask(() => autoSaveProgress());
  }

  // ================= Utility / Titles / Newly Unlocked =================
  static Future<void> ensureUnlocksLoaded() async {
    await Future.delayed(const Duration(milliseconds: 1));
  }

  static List<String> unlockedBetween(int oldLevel, int newLevel) {
    final newlyUnlocked = <String>[];
    for (final contentKey in _unlockAtLevel.keys) {
      final requiredLevel = _unlockAtLevel[contentKey]!;
      if (requiredLevel > oldLevel && requiredLevel <= newLevel) {
        newlyUnlocked.add(contentKey);
      }
    }
    return newlyUnlocked;
  }

  static String titleFor(String key) {
    switch (key) {
      case levelAlphabet:
        return 'Alphabet Quest';
      case levelNumbers:
        return 'Numbers Quest';
      case levelGreetings:
        return 'Fruits Quest';
      case levelColour:
        return 'Colors Quest';
      case levelCommonVerb:
        return 'Animals Quest';
      case levelVerbs:
        return 'Verbs Quest';
      case levelSpeech:
        return 'Speech Quest';
      default:
        return key.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2');
    }
  }

  static bool markFirstQuizMedalEarned() {
    if (firstQuizMedalEarned) return false;
    firstQuizMedalEarned = true;
    addXp(25);
    Future.microtask(() => autoSaveProgress());
    return true;
  }

  // ================= Streak (24h window - Snapchat style) =================
  static int longestStreak = 0;
  static DateTime? lastStreakUtc;

  /// Check if the user has been inactive for more than 1 day and reset streak
  /// This should be called when loading user progress (on app startup/login)
  static void checkStreakInactivity({DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    
    // If no last streak time, nothing to check
    if (lastStreakUtc == null) {
      return;
    }
    
    // Calculate day difference from last activity
    final lastStreakDate = DateTime(lastStreakUtc!.year, lastStreakUtc!.month, lastStreakUtc!.day);
    final currentDate = DateTime(n.year, n.month, n.day);
    final dayDifference = currentDate.difference(lastStreakDate).inDays;
    
    // If more than 1 day has passed, reset the streak (Snapchat style)
    if (dayDifference > 1) {
      print('Streak reset due to inactivity: $dayDifference days since last activity');
      streakDays = 0;
      lastStreakUtc = null;
      Future.microtask(() => autoSaveProgress());
    }
  }

  static bool addStreakForLevel({DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    
    // First time playing - start streak
    if (lastStreakUtc == null) {
      streakDays = 1;
      if (streakDays > longestStreak) longestStreak = streakDays;
      lastStreakUtc = n;
      _autoClaimAll(); // no-op
      Future.microtask(() => autoSaveProgress());
      return true;
    }
    
    // Calculate day difference (using date comparison, not hours)
    final lastStreakDate = DateTime(lastStreakUtc!.year, lastStreakUtc!.month, lastStreakUtc!.day);
    final currentDate = DateTime(n.year, n.month, n.day);
    final dayDifference = currentDate.difference(lastStreakDate).inDays;
    
    // Same day - no change
    if (dayDifference == 0) {
      return false;
    }
    
    // Next day - increment streak
    if (dayDifference == 1) {
      streakDays += 1;
      if (streakDays > longestStreak) longestStreak = streakDays;
      lastStreakUtc = n;
      _autoClaimAll();
      Future.microtask(() => autoSaveProgress());
      return true;
    }
    
    // Missed a day or more - reset streak to 1 (start fresh)
    print('Streak reset: $dayDifference days since last activity');
    streakDays = 1;
    lastStreakUtc = n;
    _autoClaimAll(); // no-op
    Future.microtask(() => autoSaveProgress());
    return true; // Still return true to play streak sound for new streak start
  }

  static void resetStreak() {
    streakDays = 0;
    longestStreak = 0;
    lastStreakUtc = null;
    Future.microtask(() => autoSaveProgress());
  }

  // ================= User Session Management =================
  static String? _currentUserId;
  static bool _loadingProgress = false;

  static void resetToDefaults() {
    quest1Claimed = quest2Claimed = quest3Claimed = false;
    quest4Claimed = quest5Claimed = quest6Claimed = false;
    quest7Claimed = quest8Claimed = quest9Claimed = quest10Claimed = false;
    quest11Claimed = quest12Claimed = quest13Claimed = quest14Claimed = false;
    quest15Claimed = quest16Claimed = quest17Claimed = quest18Claimed = false;
    quest19Claimed = quest20Claimed = quest21Claimed = quest22Claimed = false;
    quest23Claimed = quest24Claimed = false;
    quest25Claimed = quest26Claimed = quest27Claimed = quest28Claimed = false;

    learnedAlphabetAll = false;
    alphabetQuizStarted = false;
    alphabetRoundsCompleted = 0;

    learnedNumbersAll = false;
    numbersRoundsCompleted = 0;
    numbersPerfectRounds = 0;

    learnedColoursAll = false;
    colourRoundsCompleted = 0;
    colourBestStreak = 0;

    learnedFruitsAll = false;
    fruitsRoundsCompleted = 0;
    fruitsBestStreak = 0;

    learnedAnimalsAll = false;
    animalsRoundsCompleted = 0;
    animalsPerfectRounds = 0;

    learnedVerbsAll = false;
    verbsRoundsCompleted = 0;
    verbsPerfectRounds = 0;

    watchedAlphabet.clear();
    watchedNumbers.clear();
    watchedColours.clear();
    watchedFruits.clear();
    watchedAnimals.clear();
    watchedVerbs.clear();
    watchedSpeech.clear();

    playedSpeech = false;

    userPoints = 0;
    achievements.clear();
    claimedPoints = 0;
    levelGoalPoints = 30;
    chestsOpened = 0;

    xp = 0;
    level = 1;

    _unlockedContent.clear();
    resetStreak();

    firstQuizMedalEarned = false;
    level1Answers = List<bool?>.filled(5, null);

    quizzesCompleted = 0;
    perfectQuizzes = 0;
    completedMC = false;
    completedMM = false;
    playedAlphabet = false;
    playedNumbers = false;
    playedColours = false;
    playedFruits = false; // ✅ ADDED
    feedbackSent = false;
  }

  static Future<void> loadProgressForUser(String userId) async {
    print('loadProgressForUser called for userId: $userId');
    print('Current userId: $_currentUserId');

    _loadingProgress = true;

    try {
      if (_currentUserId != userId) {
        print('Loading different user or after logout - resetting to defaults first');
        resetToDefaults();
      }

      _currentUserId = userId;

      final progress = await UserProgressService().getProgress();
      print('Progress data from Firestore: $progress');

      if (progress != null) {
        loadFromProgress(progress);
        
        // Check if streak should be reset due to inactivity (Snapchat style)
        checkStreakInactivity();
        
        print('Progress loaded for user: $userId');
        print('Level after loading: $level, XP: $xp, Chests: $chestsOpened, Streak: $streakDays, UserPoints: $userPoints');
      } else {
        print('No saved progress found for user: $userId - using defaults');
        _currentUserId = userId;
      }
    } catch (e) {
      print('Error loading progress for user $userId: $e');
      _currentUserId = userId;
    } finally {
      _loadingProgress = false;
      print('Progress loading completed for user: $userId');
    }
  }

  static String? get currentUserId => _currentUserId;

  static void clearCurrentUser() {
    _currentUserId = null;
    print('Current user ID cleared');
  }

  static void showCurrentProgress() {
    print('=== CURRENT PROGRESS ===');
    print('User ID: $_currentUserId');
    print('Level: $level, XP: $xp');
    print('User Points: $userPoints');
    print('Chests Opened: $chestsOpened');
    print('Claimed Points: $claimedPoints/$levelGoalPoints');
    print('Streak Days: $streakDays');
    print('Achievements: ${achievements.length}');
    print('Unlocked Content: ${_unlockedContent.length}');
    print('========================');
  }

  static Future<void> forceSave() async {
    print('forceSave: Forcing save of current progress...');
    await autoSaveProgress();
    print('forceSave: Save completed');
  }

  static bool get isLoadingProgress => _loadingProgress;

  static void resetLevel1Answers() {
    for (int i = 0; i < level1Answers.length; i++) {
      level1Answers[i] = null;
    }
    Future.microtask(() => autoSaveProgress());
  }

  static void resetAll() {
    resetLevel1Answers();

    quest1Claimed = quest2Claimed = quest3Claimed = false;
    quest4Claimed = quest5Claimed = quest6Claimed = false;
    quest7Claimed = quest8Claimed = quest9Claimed = quest10Claimed = false;
    quest11Claimed = quest12Claimed = quest13Claimed = quest14Claimed = false;
    quest15Claimed = quest16Claimed = quest17Claimed = quest18Claimed = false;
    quest19Claimed = quest20Claimed = quest21Claimed = quest22Claimed = false;
    quest23Claimed = quest24Claimed = false;
    quest25Claimed = quest26Claimed = quest27Claimed = quest28Claimed = false;

    learnedAlphabetAll = false;
    alphabetQuizStarted = false;
    alphabetRoundsCompleted = 0;

    learnedNumbersAll = false;
    numbersRoundsCompleted = 0;
    numbersPerfectRounds = 0;

    learnedColoursAll = false;
    colourRoundsCompleted = 0;
    colourBestStreak = 0;

    learnedFruitsAll = false;
    fruitsRoundsCompleted = 0;
    fruitsBestStreak = 0;

    learnedAnimalsAll = false;
    animalsRoundsCompleted = 0;
    animalsPerfectRounds = 0;

    learnedVerbsAll = false;
    verbsRoundsCompleted = 0;
    verbsPerfectRounds = 0;

    userPoints = 0;
    achievements.clear();
    claimedPoints = 0;
    levelGoalPoints = 30;
    chestsOpened = 0;

    xp = 0;
    level = 1;

    _unlockedContent.clear();
    resetStreak();

    firstQuizMedalEarned = false;

    quizzesCompleted = 0;
    perfectQuizzes = 0;
    completedMC = false;
    completedMM = false;
    playedAlphabet = false;
    playedNumbers = false;
    playedColours = false;
    playedFruits = false; // ✅ ADDED
    feedbackSent = false;

    watchedAlphabet.clear();
    watchedNumbers.clear();
    watchedColours.clear();
    watchedFruits.clear();
    watchedAnimals.clear();
    watchedVerbs.clear();
    watchedSpeech.clear();

    playedSpeech = false;

    Future.microtask(() => autoSaveProgress());
  }

  static Future<void> autoSaveProgress() async {
    if (_loadingProgress) {
      print('autoSaveProgress: Currently loading progress - skipping save to avoid overwriting');
      return;
    }

    final currentUserId = UserProgressService().getCurrentUserId();
    if (currentUserId == null || _currentUserId == null) {
      print('autoSaveProgress: No user logged in (Firebase: $currentUserId, QuestStatus: $_currentUserId) - skipping save');
      _saving = false;
      _saveQueued = false;
      return;
    }

    if (_saving) {
      _saveQueued = true;
      return;
    }
    _saving = true;
    try {
      print('autoSaveProgress: Saving progress for user $_currentUserId - Level: $level, XP: $xp, Chests: $chestsOpened, Streak: $streakDays, UserPoints: $userPoints');
      print('autoSaveProgress: Watched items - Alphabet: ${watchedAlphabet.length}, Numbers: ${watchedNumbers.length}, Colours: ${watchedColours.length}, Fruits: ${watchedFruits.length}, Animals: ${watchedAnimals.length}, Verbs: ${watchedVerbs.length}, Speech: ${watchedSpeech.length}');
      await UserProgressService().saveProgress(
        level: level,
        score: xp,
        achievements: achievements.toList(),
        userPoints: userPoints,
        quizzesCompleted: quizzesCompleted,
        perfectQuizzes: perfectQuizzes,
        completedMC: completedMC,
        completedMM: completedMM,
        playedAlphabet: playedAlphabet,
        playedNumbers: playedNumbers,
        playedColours: playedColours,
        playedFruits: playedFruits,
        feedbackSent: feedbackSent,
        claimedPoints: claimedPoints,
        levelGoalPoints: levelGoalPoints,
        chestsOpened: chestsOpened,
        streakDays: streakDays,
        longestStreak: longestStreak,
        lastStreakUtc: lastStreakUtc?.millisecondsSinceEpoch,
        questStates: {
          'quest1Claimed': quest1Claimed,
          'quest2Claimed': quest2Claimed,
          'quest3Claimed': quest3Claimed,
          'quest4Claimed': quest4Claimed,
          'quest5Claimed': quest5Claimed,
          'quest6Claimed': quest6Claimed,
          'quest7Claimed': quest7Claimed,
          'quest8Claimed': quest8Claimed,
          'quest9Claimed': quest9Claimed,
          'quest10Claimed': quest10Claimed,
          'quest11Claimed': quest11Claimed,
          'quest12Claimed': quest12Claimed,
          'quest13Claimed': quest13Claimed,
          'quest14Claimed': quest14Claimed,
          'quest15Claimed': quest15Claimed,
          'quest16Claimed': quest16Claimed,
          'quest17Claimed': quest17Claimed,
          'quest18Claimed': quest18Claimed,
          'quest19Claimed': quest19Claimed,
          'quest20Claimed': quest20Claimed,
          'quest21Claimed': quest21Claimed,
          'quest22Claimed': quest22Claimed,
          'quest23Claimed': quest23Claimed,
          'quest24Claimed': quest24Claimed,
          'quest25Claimed': quest25Claimed,
          'quest26Claimed': quest26Claimed,
          'quest27Claimed': quest27Claimed,
          'quest28Claimed': quest28Claimed,
        },
        learningStates: {
          'learnedAlphabetAll': learnedAlphabetAll,
          'alphabetQuizStarted': alphabetQuizStarted,
          'alphabetRoundsCompleted': alphabetRoundsCompleted,
          'learnedNumbersAll': learnedNumbersAll,
          'numbersRoundsCompleted': numbersRoundsCompleted,
          'numbersPerfectRounds': numbersPerfectRounds,
          'learnedColoursAll': learnedColoursAll,
          'colourRoundsCompleted': colourRoundsCompleted,
          'colourBestStreak': colourBestStreak,
          'learnedFruitsAll': learnedFruitsAll,
          'fruitsRoundsCompleted': fruitsRoundsCompleted,
          'fruitsBestStreak': fruitsBestStreak,
          'learnedAnimalsAll': learnedAnimalsAll,
          'animalsRoundsCompleted': animalsRoundsCompleted,
          'animalsPerfectRounds': animalsPerfectRounds,
          'learnedVerbsAll': learnedVerbsAll,
          'verbsRoundsCompleted': verbsRoundsCompleted,
          'verbsPerfectRounds': verbsPerfectRounds,
          'firstQuizMedalEarned': firstQuizMedalEarned,
          'watchedAlphabet': watchedAlphabet.toList(),
          'watchedNumbers': watchedNumbers.toList(),
          'watchedColours': watchedColours.toList(),
          'watchedFruits': watchedFruits.toList(),
          'watchedAnimals': watchedAnimals.toList(),
          'watchedVerbs': watchedVerbs.toList(),
          'watchedSpeech': watchedSpeech.toList(),
          'playedSpeech': playedSpeech,
          'playedFruits': playedFruits, // ✅ ADDED
        },
        unlockedContent: _unlockedContent.toList(),
        level1Answers: level1Answers.map((e) => e == null ? null : (e ? 1 : 0)).toList(),
      );
    } finally {
      _saving = false;
      if (_saveQueued) {
        _saveQueued = false;
        Future.delayed(const Duration(milliseconds: 200), () => autoSaveProgress());
      }
    }
  }

  static void loadFromProgress(Map<String, dynamic> data) {
    level = data['level'] ?? 1;
    xp = data['score'] ?? 0;
    achievements = Set<String>.from(data['achievements'] ?? []);
    userPoints = data['userPoints'] ?? 0;
    claimedPoints = data['claimedPoints'] ?? 0;
    levelGoalPoints = data['levelGoalPoints'] ?? 30;
    chestsOpened = data['chestsOpened'] ?? 0;
    streakDays = data['streakDays'] ?? 0;
    longestStreak = data['longestStreak'] ?? 0;
    quizzesCompleted = data['quizzesCompleted'] ?? 0;
    perfectQuizzes = data['perfectQuizzes'] ?? 0;
    completedMC = data['completedMC'] ?? false;
    completedMM = data['completedMM'] ?? false;
    playedAlphabet = data['playedAlphabet'] ?? false;
    playedNumbers = data['playedNumbers'] ?? false;
    playedColours = data['playedColours'] ?? false;
    playedFruits = data['playedFruits'] ?? false;
    feedbackSent = data['feedbackSent'] ?? false;

    if (data['lastStreakUtc'] != null) {
      lastStreakUtc = DateTime.fromMillisecondsSinceEpoch(data['lastStreakUtc']);
    }

    final questStates = data['questStates'] as Map<String, dynamic>? ?? {};
    quest1Claimed = questStates['quest1Claimed'] ?? false;
    quest2Claimed = questStates['quest2Claimed'] ?? false;
    quest3Claimed = questStates['quest3Claimed'] ?? false;
    quest4Claimed = questStates['quest4Claimed'] ?? false;
    quest5Claimed = questStates['quest5Claimed'] ?? false;
    quest6Claimed = questStates['quest6Claimed'] ?? false;
    quest7Claimed = questStates['quest7Claimed'] ?? false;
    quest8Claimed = questStates['quest8Claimed'] ?? false;
    quest9Claimed = questStates['quest9Claimed'] ?? false;
    quest10Claimed = questStates['quest10Claimed'] ?? false;
    quest11Claimed = questStates['quest11Claimed'] ?? false;
    quest12Claimed = questStates['quest12Claimed'] ?? false;
    quest13Claimed = questStates['quest13Claimed'] ?? false;
    quest14Claimed = questStates['quest14Claimed'] ?? false;
    quest15Claimed = questStates['quest15Claimed'] ?? false;
    quest16Claimed = questStates['quest16Claimed'] ?? false;
    quest17Claimed = questStates['quest17Claimed'] ?? false;
    quest18Claimed = questStates['quest18Claimed'] ?? false;
    quest19Claimed = questStates['quest19Claimed'] ?? false;
    quest20Claimed = questStates['quest20Claimed'] ?? false;
    quest21Claimed = questStates['quest21Claimed'] ?? false;
    quest22Claimed = questStates['quest22Claimed'] ?? false;
    quest23Claimed = questStates['quest23Claimed'] ?? false;
    quest24Claimed = questStates['quest24Claimed'] ?? false;
    quest25Claimed = questStates['quest25Claimed'] ?? false;
    quest26Claimed = questStates['quest26Claimed'] ?? false;
    quest27Claimed = questStates['quest27Claimed'] ?? false;
    quest28Claimed = questStates['quest28Claimed'] ?? false;

    final learningStates = data['learningStates'] as Map<String, dynamic>? ?? {};
    learnedAlphabetAll = learningStates['learnedAlphabetAll'] ?? false;
    alphabetQuizStarted = learningStates['alphabetQuizStarted'] ?? false;
    alphabetRoundsCompleted = learningStates['alphabetRoundsCompleted'] ?? 0;
    learnedNumbersAll = learningStates['learnedNumbersAll'] ?? false;
    numbersRoundsCompleted = learningStates['numbersRoundsCompleted'] ?? 0;
    numbersPerfectRounds = learningStates['numbersPerfectRounds'] ?? 0;
    learnedColoursAll = learningStates['learnedColoursAll'] ?? false;
    colourRoundsCompleted = learningStates['colourRoundsCompleted'] ?? 0;
    colourBestStreak = learningStates['colourBestStreak'] ?? 0;
    learnedFruitsAll = learningStates['learnedFruitsAll'] ?? false;
    fruitsRoundsCompleted = learningStates['fruitsRoundsCompleted'] ?? 0;
    fruitsBestStreak = learningStates['fruitsBestStreak'] ?? 0;
    learnedAnimalsAll = learningStates['learnedAnimalsAll'] ?? false;
    animalsRoundsCompleted = learningStates['animalsRoundsCompleted'] ?? 0;
    animalsPerfectRounds = learningStates['animalsPerfectRounds'] ?? 0;
    learnedVerbsAll = learningStates['learnedVerbsAll'] ?? false;
    verbsRoundsCompleted = learningStates['verbsRoundsCompleted'] ?? 0;
    verbsPerfectRounds = learningStates['verbsPerfectRounds'] ?? 0;
    firstQuizMedalEarned = learningStates['firstQuizMedalEarned'] ?? false;

    watchedAlphabet = Set<String>.from(learningStates['watchedAlphabet'] ?? []);
    watchedNumbers = Set<String>.from(learningStates['watchedNumbers'] ?? []);
    watchedColours = Set<String>.from(learningStates['watchedColours'] ?? []);
    watchedFruits = Set<String>.from(learningStates['watchedFruits'] ?? []);
    watchedAnimals = Set<String>.from(learningStates['watchedAnimals'] ?? []);
    watchedVerbs = Set<String>.from(learningStates['watchedVerbs'] ?? []);
    watchedSpeech = Set<String>.from(learningStates['watchedSpeech'] ?? []);

    playedSpeech = learningStates['playedSpeech'] ?? false;
    playedFruits = learningStates['playedFruits'] ?? false; // ✅ ADDED

    print('loadFromProgress: Loaded watched items - Alphabet: ${watchedAlphabet.length}, Numbers: ${watchedNumbers.length}, Colours: ${watchedColours.length}, Fruits: ${watchedFruits.length}, Animals: ${watchedAnimals.length}, Verbs: ${watchedVerbs.length}, Speech: ${watchedSpeech.length}');

    final unlockedList = data['unlockedContent'] as List? ?? [];
    _unlockedContent.clear();
    _unlockedContent.addAll(unlockedList.cast<String>());

    final level1List = data['level1Answers'] as List? ?? [];
    level1Answers = level1List.map((e) => e == null ? null : (e == 1)).toList();
    if (level1Answers.isEmpty) {
      level1Answers = List<bool?>.filled(5, null);
    }
  }
}

enum UnlockStatus { success, alreadyUnlocked, needLevel, needKeys }