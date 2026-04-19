class MediaItem {
  final String filePath;
  final String albumName;
  final DateTime dateTaken;
  final String mediaType; // 'photo' or 'video'
  final String? thumbnailPath;
  final String? id;

  const MediaItem({
    required this.filePath,
    required this.albumName,
    required this.dateTaken,
    this.mediaType = 'photo',
    this.thumbnailPath,
    this.id,
  });

  String get fileName => filePath.split('/').last;

  MediaItem copyWith({
    String? filePath,
    String? albumName,
    DateTime? dateTaken,
    String? mediaType,
    String? thumbnailPath,
    String? id,
  }) {
    return MediaItem(
      filePath: filePath ?? this.filePath,
      albumName: albumName ?? this.albumName,
      dateTaken: dateTaken ?? this.dateTaken,
      mediaType: mediaType ?? this.mediaType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}
