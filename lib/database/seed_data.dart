import '../models/category.dart';

class SeedData {
  static const List<CategoryModel> defaultCategories = [
    // Expense categories
    CategoryModel(name: 'อาหาร / Food', icon: 'restaurant', type: 'expense'),
    CategoryModel(name: 'ค่าเดินทาง / Transport', icon: 'directions_car', type: 'expense'),
    CategoryModel(name: 'ช้อปปิ้ง / Shopping', icon: 'shopping_bag', type: 'expense'),
    CategoryModel(name: 'ค่าน้ำมัน / Fuel', icon: 'local_gas_station', type: 'expense'),
    CategoryModel(name: 'บิลค่าใช้จ่าย / Bills', icon: 'receipt_long', type: 'expense'),
    CategoryModel(name: 'ที่อยู่อาศัย / Housing', icon: 'home', type: 'expense'),
    CategoryModel(name: 'การศึกษา / Education', icon: 'school', type: 'expense'),
    CategoryModel(name: 'สุขภาพ / Health', icon: 'local_hospital', type: 'expense'),
    CategoryModel(name: 'บันเทิง / Entertainment', icon: 'sports_esports', type: 'expense'),
    CategoryModel(name: 'โทรศัพท์ / Phone', icon: 'phone_android', type: 'expense'),

    // Income categories
    CategoryModel(name: 'เงินเดือน / Salary', icon: 'work', type: 'income'),
    CategoryModel(name: 'โบนัส / Bonus', icon: 'card_giftcard', type: 'income'),
    CategoryModel(name: 'รายได้เสริม / Extra', icon: 'trending_up', type: 'income'),
    CategoryModel(name: 'เงินออม / Savings', icon: 'savings', type: 'income'),

    // General
    CategoryModel(name: 'อื่นๆ / Other', icon: 'more_horiz', type: 'both'),
  ];
}
