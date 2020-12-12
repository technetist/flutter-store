import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_store/models/app_state.dart';
import 'package:flutter_store/models/order.dart';
import 'package:flutter_store/models/user.dart';
import 'package:flutter_store/redux/actions.dart';
import 'package:flutter_store/widgets/product_item.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartPage extends StatefulWidget {
  final void Function() onInit;

  CartPage({this.onInit});

  @override
  CartPageState createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  bool _isSubmitting = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState() {
    super.initState();
    widget.onInit();
    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_ZAj9JbtRiAKp8H42j9hnvNVH00rrKACGNA",
        merchantId: "Flutter Store",
        androidPayMode: 'test'));
  }

  Widget _cartTab(state) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            top: false,
            bottom: false,
            child: GridView.builder(
              itemCount: state.cartProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                  childAspectRatio:
                      orientation == Orientation.portrait ? 1.0 : 1.3),
              itemBuilder: (context, i) =>
                  ProductItem(item: state.cartProducts[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardsTab(state) {
    _addCard(cardToken) async {
      final User user = state.user;
      await http.put('http://localhost:1337/users/${user.id}', body: {
        "card_token": cardToken,
      }, headers: {
        "Authorization": "Bearer ${user.jwt}",
      });

      http.Response response = await http.post('http://localhost:1337/card/add',
          body: {"source": cardToken, "customer": user.customerId});

      final responseData = json.decode(response.body);
      return responseData;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10.0),
        ),
        RaisedButton(
          elevation: 8.0,
          child: Text('Add Card'),
          onPressed: () async {
            final PaymentMethod paymentMethod =
                await StripePayment.paymentRequestWithCardForm(
                    CardFormPaymentRequest());
            final String cardToken = paymentMethod.id;

            final card = await _addCard(cardToken);
            StoreProvider.of<AppState>(context).dispatch(AddCardAction(card));
            StoreProvider.of<AppState>(context)
                .dispatch(UpdateCardTokenAction(card['id']));

            final snackbar = SnackBar(
              content: Text(
                'Card Added',
                style: TextStyle(color: Colors.green),
              ),
            );
            _scaffoldKey.currentState.showSnackBar(snackbar);
          },
        ),
        Expanded(
          child: ListView(
            children: state.cards
                .map<Widget>(
                  (c) => (ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      child: Icon(
                        Icons.credit_card,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                        "${c['card']['exp_month']}/${c['card']['exp_year']}, ${c['card']['last4']}"),
                    subtitle: Text("${c['card']['brand']}"),
                    trailing: state.cardToken == c['id']
                        ? Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                            ),
                            label: Text('Primary Card'),
                          )
                        : FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            child: Text(
                              'Set as Primary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            onPressed: () {
                              StoreProvider.of<AppState>(context)
                                  .dispatch(UpdateCardTokenAction(c['id']));
                            },
                          ),
                  )),
                )
                .toList(),
          ),
        )
      ],
    );
  }

  Widget _ordersTab(state) {
    return ListView(
      children: state.orders.length > 0
          ? state.orders
              .map<Widget>(
                (order) => (ListTile(
                  title: Text('\$${order.amount}'),
                  subtitle: Text(order.createdAt),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.white,
                    ),
                  ),
                )),
              )
              .toList()
          : [
              Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 60.0),
                      Text("No orders yet",
                          style: Theme.of(context).textTheme.headline6)
                    ],
                  ))
            ],
    );
  }

  String calculateTotalPrice(cartProducts) {
    double totalPrice = 0.0;
    cartProducts.forEach((cartProduct) {
      totalPrice += cartProduct.price;
    });

    return totalPrice.toStringAsFixed(2);
  }

  Future _showCheckoutDialog(state) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        if (state.cards.length == 0) {
          return AlertDialog(
            title: Row(
              children: [
                Padding(
                    padding: EdgeInsets.only(right: 10.0),
                    child: Text('Add Card')),
                Icon(
                  Icons.credit_card,
                  size: 60.0,
                )
              ],
            ),
            content: SingleChildScrollView(
                child: ListBody(
              children: [
                Text(
                  'Provide a credit card before checkout',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            )),
          );
        }
        String cartSummary = '';
        state.cartProducts.forEach((cartProduct) {
          cartSummary += "• ${cartProduct.name}, \$${cartProduct.price}\n";
        });

        final primaryCard = state.cards
            .singleWhere((card) => card['id'] == state.cardToken)['card'];
        return AlertDialog(
          title: Text('Checkout'),
          content: SingleChildScrollView(
              child: ListBody(
            children: [
              Text(
                'CART ITEMS (${state.cartProducts.length})\n',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                '$cartSummary',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                'CARD DETAILS\n',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                'Brand: ${primaryCard['brand']}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                'Card Number ${primaryCard['last4']}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                'Expires On ${primaryCard['exp_month']}/${primaryCard['exp_year']}\n',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                'ORDER TOTAL: \$${calculateTotalPrice(state.cartProducts)}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ],
          )),
          actions: [
            FlatButton(
              color: Colors.red,
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            RaisedButton(
              color: Colors.green,
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Checkout',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )
          ],
        );
      },
    ).then((value) async {
      _checkoutCartProducts() async {
        http.Response response =
            await http.post('http://localhost:1337/orders', body: {
          "amount": calculateTotalPrice(state.cartProducts),
          "products": json.encode(state.cartProducts),
          "source": state.cardToken,
          "customer": state.user.customerId
        }, headers: {
          "Authorization": "Bearer ${state.user.jwt}"
        });

        final responseData = json.decode(response.body);
        return responseData;
      }

      if (value == true) {
        setState(() => _isSubmitting = true);
        final newOrderData = await _checkoutCartProducts();
        Order newOrder = Order.fromJson(newOrderData);
        StoreProvider.of<AppState>(context).dispatch(AddOrderAction(newOrder));
        StoreProvider.of<AppState>(context).dispatch(clearCartProductsAction);
        setState(() => _isSubmitting = false);

        _showSuccessDialog();
      }
    });
  }

  Future _showSuccessDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text('Success'),
            children: [
              Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Order placed!\n\nCheck your email for your receipt!\n\nOrder summary will appear in the orders tab',
                    style: Theme.of(context).textTheme.bodyText2,
                  ))
            ],
          );
        });
  }

  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (_, state) {
        return ModalProgressHUD(
          inAsyncCall: _isSubmitting,
          child: DefaultTabController(
            length: 3,
            initialIndex: 0,
            child: Scaffold(
              key: _scaffoldKey,
              floatingActionButton: state.cartProducts.length > 0
                  ? FloatingActionButton(
                      child: Icon(Icons.local_atm, size: 30.0),
                      onPressed: () => _showCheckoutDialog(state))
                  : Text(''),
              appBar: AppBar(
                title: Text(
                    'Summary: ${state.cartProducts.length} Items • \$${calculateTotalPrice(state.cartProducts)}'),
                bottom: TabBar(
                  labelColor: Colors.deepOrange[600],
                  unselectedLabelColor: Colors.deepOrange[900],
                  tabs: [
                    Tab(icon: Icon(Icons.shopping_cart)),
                    Tab(icon: Icon(Icons.credit_card)),
                    Tab(icon: Icon(Icons.receipt)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _cartTab(state),
                  _cardsTab(state),
                  _ordersTab(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
