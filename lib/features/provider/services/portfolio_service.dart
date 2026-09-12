import '../models/portfolio_model.dart';

/// Service for provider portfolio management.
///
/// No documented client endpoints for portfolio. These methods will
/// throw [UnsupportedError] until the backend documents client portfolio routes.
class PortfolioService {
  // No documented client endpoint.
  Future<List<PortfolioModel>> getPortfolio(String providerId) async {
    throw UnsupportedError('Client portfolio endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<void> uploadPortfolioItem(
      {required String title,
      required String description,
      required String imagePath}) async {
    throw UnsupportedError('Client portfolio endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<void> removePortfolioItem(String id) async {
    throw UnsupportedError('Client portfolio endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<void> resubmitPortfolioItem(String id) async {
    throw UnsupportedError('Client portfolio endpoints are not documented.');
  }
}
