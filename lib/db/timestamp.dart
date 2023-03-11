class Timestamp {
  final int? id;
  late final DateTime dateTime;
  final int origin;
  final bool deleted;

  static const inputClick = 0;
  static const inputManual = 1;

  Timestamp(DateTime dateTime, { this.id, this.origin = inputClick, this.deleted = false}) {
    this.dateTime = DateTime.fromMillisecondsSinceEpoch((dateTime.toUtc().millisecondsSinceEpoch ~/ 60000) * 60000);
  }

  Timestamp.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch, {this.id, this.origin = inputClick, this.deleted = false}) {
    dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true);
  }

  Map<String, dynamic> toMapForDB() => {
    'id': id,
    'dateTime': dateTime.millisecondsSinceEpoch,
    'origin': origin,
    'deleted': deleted ? 1 : 0,
  };

  int get millisecondsSinceEpoch => dateTime.millisecondsSinceEpoch;
}
