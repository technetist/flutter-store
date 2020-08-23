import 'package:flutter/material.dart';
import 'package:flutter_store/models/product.dart';
import 'package:flutter_store/pages/products_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Product item;

  ProductDetailPage({this.item});

  @override
  Widget build(BuildContext context) {
    final String pictureUrl = 'http://localhost:1337/${item.picture['url']}';
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: Container(
        decoration: gradientBackground,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Hero(
                tag: item,
                child: Image.network(
                  pictureUrl,
                  width: orientation == Orientation.portrait ? 600 : 250,
                  height: orientation == Orientation.portrait ? 400 : 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              item.name,
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              '\$${item.price}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 32.0, right: 32.0, bottom: 32.0),
                  child: Text(item.description),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
