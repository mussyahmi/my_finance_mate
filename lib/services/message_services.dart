import 'dart:math';

class MessageService {
  // List of messages for updating action (loading)
  final List<String> _updateMessages = [
    "Updating... because fresh is always better!",
    "Out with the old, in with the update!",
    "Polishing things up for you... One sec!",
    "Updating your awesomeness, hang tight!",
    "Making things new... Updating now!",
    "Getting you the latest version... Updating!",
    "Tweaking things to perfection... Updating!",
    "Refreshing the magic... Update in progress!",
    "Almost there... Your update is on the way!",
    "Hold tight... Updating your masterpiece!"
  ];

  // List of messages for deleting action (loading)
  final List<String> _deleteMessages = [
    "Poof! Making that disappear... Wait for it!",
    "Sweeping that away... Bye-bye!",
    "Deleting... This one's heading to the trash!",
    "Waving goodbye to the old... Delete in progress!",
    "Taking out the trash... Delete happening now!",
    "Making room for new things... Deleting!",
    "Out with the old... Deleting now!",
    "Just one sec... Sending it to oblivion!",
    "Clearing out the clutter... Deleting!",
    "That item won't bother you anymore... Deleting!"
  ];

  // List of messages for adding action (loading)
  final List<String> _addMessages = [
    "Adding your genius creation... Hold tight!",
    "Just a sec! We're adding your masterpiece.",
    "Here we go... Adding it now!",
    "Adding your brilliant idea... Almost there!",
    "Adding... This is going to be great!",
    "One moment, please... We're adding that now!",
    "You're adding something awesome... Almost done!",
    "Just making space for this... Adding!",
    "Almost there! Adding your new item.",
    "Preparing to add... Hold on tight!"
  ];

  // List of fun messages when done updating
  final List<String> _doneUpdateMessages = [
    "Updated successfully! Everything's fresh now.",
    "You're up to date! Your changes have been applied.",
    "Awesome! The update is complete.",
    "All done! Your update was successful.",
    "Boom! Your changes are now live.",
    "Looking good! Update complete.",
    "Great job! The update was successful.",
    "That's it! Your update is done.",
    "Nice! All changes are up to date.",
    "Well done! Your data has been updated."
  ];

  // List of fun messages when done deleting
  final List<String> _doneDeleteMessages = [
    "Gone! That item is deleted.",
    "Deleted successfully. It's out of here!",
    "Poof! Your delete was successful.",
    "Goodbye! That item is history.",
    "Bye-bye! Deletion complete.",
    "Cleared! The item has been deleted.",
    "It's gone! Deletion successful.",
    "That was fast! Item deleted.",
    "All clean! The item is gone.",
    "Success! You've deleted the unwanted item."
  ];

  // List of fun messages when done adding
  final List<String> _doneAddMessages = [
    "Boom! Your new item is added.",
    "All set! It's been added successfully.",
    "Awesome! You've added something new.",
    "Nice! Your addition was successful.",
    "Added successfully! Great job.",
    "It's official! Your item has been added.",
    "Well done! Your new item is in place.",
    "That was quick! Addition complete.",
    "Mission accomplished! New item added.",
    "Success! Your creation has been added."
  ];

  // Function to get a random message from a list
  String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  // Public methods to get random loading messages
  String getRandomUpdateMessage() => _getRandomMessage(_updateMessages);
  String getRandomDeleteMessage() => _getRandomMessage(_deleteMessages);
  String getRandomAddMessage() => _getRandomMessage(_addMessages);

  // Public methods to get random "done" messages
  String getRandomDoneUpdateMessage() => _getRandomMessage(_doneUpdateMessages);
  String getRandomDoneDeleteMessage() => _getRandomMessage(_doneDeleteMessages);
  String getRandomDoneAddMessage() => _getRandomMessage(_doneAddMessages);
}
