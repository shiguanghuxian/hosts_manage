part of "home_bloc.dart";

abstract class HomeEvent extends Equatable {
  const HomeEvent();
}

/// 切换选中的hosts
class ChangeSelectedHostsEvent extends HomeEvent {
  final String selectedHosts;
  final bool isCheck;

  const ChangeSelectedHostsEvent(this.selectedHosts, this.isCheck);

  @override
  List<Object> get props => [selectedHosts, isCheck];

  @override
  String toString() => 'ChangeSelectedHostsEvent { $selectedHosts $isCheck }';
}

/// 初始化hosts配置列表
class InitHostsListEvent extends HomeEvent {
  final I18N lang;
  const InitHostsListEvent(this.lang);

  @override
  List<Object> get props => [lang];

  @override
  String toString() => 'InitHostsListEvent';
}

/// 切换右侧展示hosts
class ChangeShowHostsEvent extends HomeEvent {
  final String showHosts;

  const ChangeShowHostsEvent(this.showHosts);

  @override
  List<Object> get props => [showHosts];

  @override
  String toString() => 'ChangeShowHostsEvent { $showHosts }';
}

/// 切换列表编辑状态
class ChangeEditListEvent extends HomeEvent {
  final bool editList;

  const ChangeEditListEvent(this.editList);

  @override
  List<Object> get props => [editList];

  @override
  String toString() => 'ChangeEditListEvent { $editList }';
}

/// 添加hosts配置
class AddHostsEvent extends HomeEvent {
  final String name;

  const AddHostsEvent(this.name);

  @override
  List<Object> get props => [name];

  @override
  String toString() => 'AddHostsEvent { $name }';
}

/// 删除一个hosts配置
class DelHostsEvent extends HomeEvent {
  final String key;

  const DelHostsEvent(this.key);

  @override
  List<Object> get props => [key];

  @override
  String toString() => 'DelHostsEvent { $key }';
}
