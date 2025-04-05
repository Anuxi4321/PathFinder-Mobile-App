class ShoppingListStore {
  static final ShoppingListStore _instance = ShoppingListStore._internal();

  factory ShoppingListStore() => _instance;

  ShoppingListStore._internal();

  List<Map<String, dynamic>> items = [];
}
