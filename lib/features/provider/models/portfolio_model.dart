/// Mirrors the `portfolios` table.
class PortfolioModel {
  final String id;
  final String providerId;
  final String image;
  final String title;
  final String description;
  final String status; // approved | pending | rejected

  const PortfolioModel({
    required this.id,
    required this.providerId,
    required this.image,
    required this.title,
    this.description = '',
    this.status = 'approved',
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
        id: json['portfolio_id'].toString(),
        providerId: json['provider_id'].toString(),
        image: json['image'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'approved',
      );
}
