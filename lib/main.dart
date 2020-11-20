import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_store/models/app_state.dart';
import 'package:flutter_store/pages/cart_page.dart';
import 'package:flutter_store/pages/login_page.dart';
import 'package:flutter_store/pages/products_page.dart';
import 'package:flutter_store/pages/register_page.dart';
import 'package:flutter_store/redux/actions.dart';
import 'package:flutter_store/redux/reducers.dart';
import 'package:redux/redux.dart';
import 'package:redux_logging/redux_logging.dart';
import 'package:redux_thunk/redux_thunk.dart';

void main() {
  final store = Store<AppState>(appReducer,
      initialState: AppState.initial(),
      middleware: [thunkMiddleware, LoggingMiddleware.printer()]);
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  MyApp({this.store});

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        routes: {
          '/': (BuildContext context) => ProductsPage(onInit: () {
                StoreProvider.of<AppState>(context).dispatch(getUserAction);
                StoreProvider.of<AppState>(context).dispatch(getProductsAction);
                StoreProvider.of<AppState>(context)
                    .dispatch(getCartProductsAction);
              }),
          '/login': (BuildContext context) => LoginPage(),
          '/register': (BuildContext context) => RegisterPage(),
          '/cart': (BuildContext context) => CartPage()
        },
        debugShowCheckedModeBanner: false,
        title: 'Flutter Store',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.cyan[400],
          accentColor: Colors.deepOrange,
          textTheme: TextTheme(
            headline5: TextStyle(
              fontSize: 72.0,
              fontWeight: FontWeight.bold,
            ),
            headline6: TextStyle(
              fontSize: 36.0,
              fontStyle: FontStyle.italic,
            ),
            bodyText2: TextStyle(
              fontSize: 18.0,
            ),
          ),
        ),
      ),
    );
  }
}
