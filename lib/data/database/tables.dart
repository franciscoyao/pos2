import 'package:drift/drift.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().nullable()();
  TextColumn get username => text().unique().nullable()();
  TextColumn get pin => text().nullable()(); // 4-digit PIN
  TextColumn get role =>
      text()(); // "admin", "waiter", "kitchen", "bar", "kiosk"
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get menuType =>
      text().withDefault(const Constant('dine-in'))(); // "dine-in", "takeaway"
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get station => text()
      .nullable()(); // "kitchen", "bar" - optional default for items in this category
  TextColumn get status => text().withDefault(const Constant('active'))();
}

@DataClassName('MenuItem')
class MenuItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique().nullable()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get station =>
      text().withDefault(const Constant('kitchen'))(); // "kitchen", "bar"
  TextColumn get type =>
      text().withDefault(const Constant('dine-in'))(); // "dine-in", "takeaway"
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get allowPriceEdit =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('Order')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get type =>
      text().withDefault(const Constant('dine-in'))(); // "dine-in", "takeaway"
  IntColumn get waiterId => integer().nullable().references(Users, #id)();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // "pending", "sent", "completed", "paid", "cancelled"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get serviceAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod =>
      text().nullable()(); // "cash", "card", "mixed"
  RealColumn get tipAmount => real().withDefault(const Constant(0.0))();
  TextColumn get taxNumber => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('OrderItem')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get menuItemId => integer().references(MenuItems, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get priceAtTime => real()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // "pending", "cooking", "ready", "served"
}

@DataClassName('Printer')
class Printers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get macAddress => text()();
  TextColumn get role => text()(); // "kitchen", "bar", "receipt"
  TextColumn get status => text().withDefault(const Constant('active'))();
}

@DataClassName('SystemSetting')
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get serviceRate => real().withDefault(const Constant(0.0))();
  TextColumn get currencySymbol => text().withDefault(const Constant('\$'))();
  BoolColumn get kioskMode => boolean().withDefault(const Constant(false))();
  IntColumn get orderDelayThreshold =>
      integer().withDefault(const Constant(15))(); // minutes
}

@DataClassName('RestaurantTable')
class RestaurantTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()(); // e.g., "Table 1"
  TextColumn get status => text().withDefault(
    const Constant('available'),
  )(); // "available", "occupied"
  IntColumn get x =>
      integer().withDefault(const Constant(0))(); // For potential visual layout
  IntColumn get y => integer().withDefault(const Constant(0))();
}
