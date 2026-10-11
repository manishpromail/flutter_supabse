import '../data/product_model.dart';

abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  ProductLoaded(this.products);
}

class ProductActionInProgress extends ProductState {}

class ProductAddedSuccess extends ProductState {
  final ProductModel product;
  ProductAddedSuccess(this.product);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
