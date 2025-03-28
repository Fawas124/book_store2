class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final double price;
  final List<String> genres;
  final DateTime publishDate;
  final bool isBestseller;
  final double rating;
  final int reviewCount;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.price,
    required this.genres,
    required this.publishDate,
    this.isBestseller = false,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'] ?? 'No title',
      author: (json['authors'] as List?)?.join(', ') ?? 'Unknown author',
      description: json['description'] ?? 'No description available',
      coverUrl: json['imageLinks']?['thumbnail']
              ?.replaceFirst('http://', 'https://') ??
          'https://i.pinimg.com/originals/55/5c/a2/555ca28baea4ce9064d87e6a3cf301d0.png',
      price: (json['saleInfo']?['retailPrice']?['amount'] ?? 9.99).toDouble(),
      genres: (json['categories'] as List?)?.cast<String>() ?? [],
      publishDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate']) ?? DateTime.now()
          : DateTime.now(),
      isBestseller: (json['averageRating']?.toDouble() ?? 0.0) > 4.5,
      rating: json['averageRating']?.toDouble() ?? 0.0,
      reviewCount: json['ratingsCount'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
