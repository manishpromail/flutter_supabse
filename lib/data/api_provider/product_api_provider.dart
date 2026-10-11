import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/network_handling.dart';
import '../../features/products/data/product_model.dart';
import '../injector.dart';
import '../shared/data_response.dart';

/// ProductApiProvider handling remote product operations via Dio
class ProductApiProvider {
  late final Dio _dio;

  ProductApiProvider([Dio? dio]) {
    _dio = dio ?? Injector().getDio();
  }

  /// Fetch all products
  Future<DataResponse<List<ProductModel>>> getProducts() async {
    try {
      final Response response = await _dio.get(
        ApiConstants.products,
        options: Injector.getHeaderToken(),
      );

      final Map<String, dynamic> body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      final List list = (body['data'] is List) ? body['data'] as List : [];
      final products = list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return DataResponse.success(
        data: products,
        message: body['message']?.toString() ?? 'Products loaded',
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      return DataResponse.failure(
        message: NetworkHandling.getDioException(e),
        statusCode: NetworkHandling.getDioCode(e),
      );
    }
  }

  /// Create a new product
  Future<DataResponse<ProductModel>> createProduct({
    required String title,
    required String description,
    required double price,
    String? imageUrl,
  }) async {
    try {
      final Response response = await _dio.post(
        ApiConstants.products,
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'price': price,
          'image_url': imageUrl?.trim(),
        },
        options: Injector.getHeaderToken(),
      );

      final Map<String, dynamic> body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      final itemData = (body['data'] is Map<String, dynamic>)
          ? body['data'] as Map<String, dynamic>
          : body;

      final ProductModel product = ProductModel.fromJson(itemData);

      return DataResponse.success(
        data: product,
        message: body['message']?.toString() ?? 'Product added successfully',
        statusCode: response.statusCode ?? 201,
      );
    } catch (e) {
      return DataResponse.failure(
        message: NetworkHandling.getDioException(e),
        statusCode: NetworkHandling.getDioCode(e),
      );
    }
  }
}
