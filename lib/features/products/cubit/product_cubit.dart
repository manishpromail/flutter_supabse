import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  List<ProductModel> _cachedProducts = [];

  ProductCubit({ProductRepository? productRepository})
      : _productRepository = productRepository ?? ProductRepository(),
        super(ProductInitial());

  List<ProductModel> get currentProducts => _cachedProducts;

  Future<void> fetchProducts() async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.getProducts();
      _cachedProducts = products;
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    String? imageUrl,
  }) async {
    emit(ProductActionInProgress());
    try {
      final newProduct = await _productRepository.createProduct(
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
      );

      _cachedProducts = [newProduct, ..._cachedProducts];
      emit(ProductAddedSuccess(newProduct));
      emit(ProductLoaded(List.from(_cachedProducts)));
      return true;
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
      // Restore loaded list if available
      if (_cachedProducts.isNotEmpty) {
        emit(ProductLoaded(List.from(_cachedProducts)));
      }
      return false;
    }
  }
}
