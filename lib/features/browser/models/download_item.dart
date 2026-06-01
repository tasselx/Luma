enum DownloadStatus { pending, downloading, completed, failed, canceled }

DownloadStatus _statusFromName(String? name) {
  return DownloadStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => DownloadStatus.pending,
  );
}

/// A record of a download attempt. Used for the optional download history.
class DownloadItem {
  DownloadItem({
    required this.id,
    required this.fileName,
    required this.url,
    this.sourcePageUrl = '',
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.localPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String fileName;
  final String url;
  final String sourcePageUrl;
  DownloadStatus status;
  double progress;
  String? localPath;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'url': url,
        'sourcePageUrl': sourcePageUrl,
        'status': status.name,
        'progress': progress,
        'localPath': localPath,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return DownloadItem(
      id: (json['id'] as String?) ?? '',
      fileName: (json['fileName'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      sourcePageUrl: (json['sourcePageUrl'] as String?) ?? '',
      status: _statusFromName(json['status'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      localPath: json['localPath'] as String?,
      createdAt: created is int
          ? DateTime.fromMillisecondsSinceEpoch(created)
          : DateTime.tryParse('${created ?? ''}') ?? DateTime.now(),
    );
  }
}
