class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? bankName;
  final String? sender;
  final String? receiver;
  final String? refNo;
  final String? note;
  final String? imagePath;
  final int? categoryId;
  final String? categoryName;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String? hash;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    this.bankName,
    this.sender,
    this.receiver,
    this.refNo,
    this.note,
    this.imagePath,
    this.categoryId,
    this.categoryName,
    required this.transactionDate,
    DateTime? createdAt,
    this.hash,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'bank_name': bankName,
      'sender': sender,
      'receiver': receiver,
      'ref_no': refNo,
      'note': note,
      'image_path': imagePath,
      'category_id': categoryId,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'hash': hash,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      bankName: map['bank_name'] as String?,
      sender: map['sender'] as String?,
      receiver: map['receiver'] as String?,
      refNo: map['ref_no'] as String?,
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      hash: map['hash'] as String?,
    );
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? type,
    String? bankName,
    String? sender,
    String? receiver,
    String? refNo,
    String? note,
    String? imagePath,
    int? categoryId,
    String? categoryName,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? hash,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      refNo: refNo ?? this.refNo,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      hash: hash ?? this.hash,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
