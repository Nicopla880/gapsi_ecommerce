import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/models/product_model.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('shape plano', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'itemId': 123, 'name': 'TV 55', 'price': 199.99,
        'thumbnailImage': 'http://img', 'description': 'desc',
      });
      expect(m.id, '123');
      expect(m.title, 'TV 55');
      expect(m.price, 199.99);
      expect(m.thumbnailUrl, 'http://img');
    });
    test('shape anidado (confirmado de producto individual)', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'productId': 'abc', 'title': 'Phone',
        'priceInfo': <String, dynamic>{'currentPrice': <String, dynamic>{'price': 10.5}},
        'imageInfo': <String, dynamic>{'thumbnailUrl': 'http://t'},
      });
      expect(m.id, 'abc');
      expect(m.price, 10.5);
      expect(m.thumbnailUrl, 'http://t');
    });
    test('json vacío no lanza', () {
      final m = ProductModel.fromJson(<String, dynamic>{});
      expect(m.id, '');
      expect(m.price, isNull);
      expect(m.thumbnailUrl, isNull);
    });
    test('precio como string con símbolo', () {
      expect(ProductModel.fromJson(<String, dynamic>{'price': r'$12.99'}).price, 12.99);
    });
    test('índice de lista en la ruta', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'imageInfo': <String, dynamic>{'allImages': <dynamic>[<String, dynamic>{'url': 'http://a'}]},
      });
      expect(m.thumbnailUrl, 'http://a');
    });
  });
}
