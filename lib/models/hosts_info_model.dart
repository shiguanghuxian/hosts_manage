class HostsInfoModel {
  String key;
  String name;
  bool check;
  bool isBaseHosts; // 是否是基础hosts

  HostsInfoModel({this.key, this.name, this.check, this.isBaseHosts});

  HostsInfoModel.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    name = json['name'];
    check = json['check'] ?? false;
    isBaseHosts = json['is_base_hosts'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['name'] = name;
    data['check'] = check;
    data['is_base_hosts'] = isBaseHosts;
    return data;
  }
}
