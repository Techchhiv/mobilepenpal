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

  /// An optional bonus quest with extra rewards.
  bonus,
}
