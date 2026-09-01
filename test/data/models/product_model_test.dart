import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/models/product_model.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('prioriza los campos validados de un item de búsqueda real', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'id': 'OPAQUE_ID',
        'usItemId': '927771478',
        'name': 'Nintendo Switch Lite - Blue',
        'price': 132,
        'priceInfo': <String, dynamic>{
          'linePrice': r'$132.30',
          'minPrice': 132.3,
        },
        'image': 'https://i5.walmartimages.com/asr/example.jpeg',
        'description': 'Portable Nintendo console',
      });

      expect(model.id, '927771478');
      expect(model.title, 'Nintendo Switch Lite - Blue');
      expect(model.price, 132.30);
      expect(
        model.thumbnailUrl,
        'https://i5.walmartimages.com/asr/example.jpeg',
      );
      expect(model.description, 'Portable Nintendo console');
    });

    test('ceros y strings vacíos representan precio no disponible', () {
      final model = ProductModel.fromJson(<String, dynamic>{
        'price': 0,
        'priceInfo': <String, dynamic>{'linePrice': '', 'minPrice': 0},
      });

      expect(model.price, isNull);
    });

    test('shape plano', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'itemId': 123,
        'name': 'TV 55',
        'price': 199.99,
        'thumbnailImage': 'http://img',
        'description': 'desc',
      });
      expect(m.id, '123');
      expect(m.title, 'TV 55');
      expect(m.price, 199.99);
      expect(m.thumbnailUrl, 'http://img');
    });
    test('shape anidado (confirmado de producto individual)', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'productId': 'abc',
        'title': 'Phone',
        'priceInfo': <String, dynamic>{
          'currentPrice': <String, dynamic>{'price': 10.5},
        },
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
      expect(
        ProductModel.fromJson(<String, dynamic>{'price': r'$12.99'}).price,
        12.99,
      );
    });
    test('índice de lista en la ruta', () {
      final m = ProductModel.fromJson(<String, dynamic>{
        'imageInfo': <String, dynamic>{
          'allImages': <dynamic>[
            <String, dynamic>{'url': 'http://a'},
          ],
        },
      });
      expect(m.thumbnailUrl, 'http://a');
    });
  });
}
