import '../data/mock/mock_data.dart';
import '../models/portfolio_model.dart';
import 'api_client.dart';

/// Placeholder service for provider portfolio management.
class PortfolioService {
  // GET /providers/:id/portfolio
  Future<List<PortfolioModel>> getPortfolio(String providerId) async {
    await simulateNetworkDelay(ms: 350);
    return MockData.portfolio;
  }

  // POST /portfolio  (multipart upload — UI only, no implementation here)
  Future<void> uploadPortfolioItem({required String title, required String description, required String imagePath}) async {
    await simulateNetworkDelay(ms: 700);
  }

  // DELETE /portfolio/:id
  Future<void> removePortfolioItem(String id) async => simulateNetworkDelay(ms: 250);
}
