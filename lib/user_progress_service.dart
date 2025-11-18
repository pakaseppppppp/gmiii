import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveProgress({
    required int level,
    required int score,
    required List<String> achievements,
    required int userPoints,
    required int claimedPoints,
    required int levelGoalPoints,
    required int chestsOpened,
    required int streakDays,
    required int longestStreak,
    int? lastStreakUtc,
    required Map<String, bool> questStates,
    required Map<String, dynamic> learningStates,
    required List<String> unlockedContent,
    required List<int?> level1Answers,
    required int quizzesCompleted,
    required int perfectQuizzes,
    required bool completedMC,
    required bool completedMM,
    required bool playedAlphabet,
    required bool playedNumbers,
    required bool playedColours,
    required bool playedFruits,
    required bool feedbackSent,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Get display name from users collection for leaderboard
    String? displayName;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        displayName = userDoc.data()?['displayName'] as String?;
      }
    } catch (e) {
      print('Error getting display name for progress save: $e');
    }

    // This saves progress PER-USER, using their UID as document
    await _firestore.collection('progress').doc(user.uid).set({
      'level': level,
      'score': score,
      'achievements': achievements,
      'userPoints': userPoints,
      'claimedPoints': claimedPoints,
      'levelGoalPoints': levelGoalPoints,
      'chestsOpened': chestsOpened,
      'streakDays': streakDays,
      'longestStreak': longestStreak,
      'lastStreakUtc': lastStreakUtc,
      'questStates': questStates,
      'learningStates': learningStates,
      'unlockedContent': unlockedContent,
      'level1Answers': level1Answers,
      'quizzesCompleted': quizzesCompleted,
      'perfectQuizzes': perfectQuizzes,
      'completedMC': completedMC,
      'completedMM': completedMM,
      'playedAlphabet': playedAlphabet,
      'playedNumbers': playedNumbers,
      'playedColours': playedColours,
      'playedFruits': playedFruits,
      'feedbackSent': feedbackSent,
      'displayName':
          displayName, // Store displayName in progress for leaderboard
      'email': user.email, // Store email for username fallback
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print(
      'Progress saved - Level: $level, XP: $score, UserPoints: $userPoints',
    );
  }

  Future<Map<String, dynamic>?> getProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // This loads progress PER-USER, using their UID as document
      var doc = await _firestore.collection('progress').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        print('Progress loaded from Firestore for user ${user.uid}');
        print('Data keys: ${data?.keys.toList()}');
        print(
          'Level: ${data?['level']}, Score: ${data?['score']}, UserPoints: ${data?['userPoints']}',
        );
        return data;
      } else {
        print('No progress document found for user ${user.uid}');
        return null;
      }
    } catch (e) {
      print('Error loading progress from Firestore: $e');
      rethrow;
    }
  }

  /// Get the current user ID
  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Get global leaderboard data with display names
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('progress')
          .orderBy('level', descending: true)
          .limit(limit)
          .get();

      final leaderboard = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final userData = doc.data();

        // Try to get display name from users collection
        String displayName = 'Player';
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(doc.id)
              .get();
          if (userDoc.exists) {
            displayName = userDoc.data()?['displayName'] ?? 'Player';
          }
        } catch (e) {
          print('Error getting display name for ${doc.id}: $e');
        }

        leaderboard.add({
          'userId': doc.id,
          'displayName': displayName,
          ...userData,
        });
      }

      return leaderboard;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Clear user progress (for reset functionality)
  Future<void> clearProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('progress').doc(user.uid).delete();
    print('Progress cleared for user: ${user.uid}');
  }

  /// Save user display name and log changes for admin monitoring
  Future<void> saveDisplayName(String displayName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Get old display name
    String? oldName;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        oldName = doc.data()?['displayName'] as String?;
      }
    } catch (e) {
      print('Error getting old display name: $e');
    }

    // Save new display name
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Log the change for admin monitoring
    await _firestore.collection('display_name_changes').add({
      'userId': user.uid,
      'oldName': oldName ?? '',
      'newName': displayName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('Display name saved: $displayName and change logged');
  }

  /// Get user display name
  Future<String?> getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['displayName'] as String?;
      }
    } catch (e) {
      print('Error getting display name: $e');
    }
    return null;
  }

  /// Submit user feedback to Firestore
  Future<void> submitFeedback(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Get display name
    String displayName = 'Anonymous';
    try {
      final name = await getDisplayName();
      if (name != null && name.isNotEmpty) {
        displayName = name;
      } else if (user.email != null) {
        displayName = user.email!.split('@').first;
      }
    } catch (e) {
      print('Error getting display name for feedback: $e');
    }

    // Save feedback to Firestore
    await _firestore.collection('feedback').add({
      'userId': user.uid,
      'userName': displayName,
      'userEmail': user.email ?? '',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'new', // new, read, resolved
      'createdAt': DateTime.now().toIso8601String(),
    });

    print('Feedback submitted by $displayName');
  }

  Future<void> saveAchievements(List<String> ids) async {
    // TODO: persist to local storage / cloud if you want
  }

  Future<void> saveCounters(Map<String, dynamic> counters) async {
    // TODO: persist to local storage / cloud if you want
  }

  /// Save user avatar index
  Future<void> saveAvatarIndex(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).set({
      'avatarIndex': index,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('Avatar index saved: $index');
  }

  /// Get user avatar index
  Future<int> getAvatarIndex() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['avatarIndex'] as int? ?? 0;
      }
    } catch (e) {
      print('Error getting avatar index: $e');
    }
    return 0;
  }
}
