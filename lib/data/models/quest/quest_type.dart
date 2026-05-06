/// Defines the different types of quests available in the app.
///
/// Each quest type targets a specific learning goal to help
/// users practice and reinforce Khmer handwriting skills.
enum QuestType {
  /// Practice the characters the user struggles with the most.
  weakestCharacters,

  /// Review characters from the most recently completed lesson.
  recentReview,

  /// A randomized set of characters from all previously learned content.
  randomReview,

  /// Fallback: showcase mastery of best character (when no weakest exists).
  masteryShowcase,

  /// Fallback: review a character not practiced in a long time.
  deepMemory,
}
