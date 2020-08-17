import 'dart:convert';
import 'package:flutter_store/models/product.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_store/Models/app_state.dart';
import 'package:flutter_store/Models/user.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThunkAction<AppState> getUserAction = (Store<AppState> store) async {
  final prefs = await SharedPreferences.getInstance();
  final String storedUser = prefs.getString('user');
  final user =
      storedUser != null ? User.fromJson(json.decode(storedUser)) : null;

  store.dispatch(GetUserAction(user));
};

class GetUserAction {
  final dynamic _user;

  dynamic get user => this._user;

  GetUserAction(this._user);
}

ThunkAction<AppState> getProductsAction = (Store<AppState> store) async {
  http.Response response = await http.get('http://localhost:1337/products');

  final List<dynamic> responseData = json.decode(response.body);
  List<Product> products = [];

  responseData.forEach((productData) {
    final Product product = Product.fromJson(productData);
      products.add(product);
  });

  store.dispatch(GetProductsAction(products));
};

class GetProductsAction {
  final List<dynamic> _products;

  List<Product> get products => this._products;

  GetProductsAction(this._products);
}
