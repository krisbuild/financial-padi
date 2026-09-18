enum ChatRole { user, coach }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
