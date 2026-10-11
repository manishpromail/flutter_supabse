import '../../../data/api_provider/product_api_provider.dart';
import 'product_model.dart';

class ProductRepository {
  final ProductApiProvider _apiProvider;

  ProductRepository({ProductApiProvider? apiProvider})
      : _apiProvider = apiProvider ?? ProductApiProvider();

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiProvider.getProducts();

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Failed to load products');
    }

    return response.data ?? [];
  }

  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    String? imageUrl,
  }) async {
    final response = await _apiProvider.createProduct(
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message ?? 'Failed to add product');
    }

    return response.data!;
  }
}
