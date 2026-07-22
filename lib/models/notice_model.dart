class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String actionType;
  final String? actionUrl;
  final List<Attachment> attachments; // ✅ NEW: Multiple attachments
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.actionType,
    this.actionUrl,
    this.attachments = const [],
    required this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    // Parse attachments from JSON
    List<Attachment> attachments = [];
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((a) => Attachment.fromJson(a))
          .toList();
    }

    return NoticeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      actionType: json['action_type'] as String,
      actionUrl: json['action_url'] as String?,
      attachments: attachments,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'action_type': actionType,
      'action_url': actionUrl,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}

class Attachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'pdf', 'image', 'doc', etc.
  final double fileSize; // in KB

  Attachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileSize: (json['file_size'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }
}
