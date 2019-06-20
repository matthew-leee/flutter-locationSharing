class Item {
  String id;
  String name;
  int qty;
  final DateTime dateTime;
  Item(this.id, this.name, this.qty, this.dateTime);
  Map<String, String> toJson () {
    var temp = Map<String, String>();
    temp["id"] = id;
    temp['name'] = name;
    temp["qty"] = qty.toString();
    temp["DateTime"] = dateTime.toString();
    return temp;
  }
}