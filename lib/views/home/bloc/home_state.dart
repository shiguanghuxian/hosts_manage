part of "home_bloc.dart";

class HomeState extends Equatable {
  const HomeState({
    this.showHosts = '',
    this.hostsList = const [],
    this.changeHostList = 0,
    this.editList = false,
  });

  final String showHosts; // 右侧需要显示的hosts
  final List<HostsInfoModel> hostsList; // hosts配置列表
  final int changeHostList; // 用于列表更新刷新列表，改类属性无法判断
  final bool editList; // 是否编辑列表

  HomeState copyWith({
    String showHosts,
    List<HostsInfoModel> hostsList,
    int changeHostList,
    bool editList,
  }) {
    return HomeState(
      showHosts: showHosts ?? this.showHosts,
      hostsList: hostsList ?? this.hostsList,
      changeHostList: changeHostList ?? this.changeHostList,
      editList: editList ?? this.editList,
    );
  }

  @override
  List<Object> get props => [
        showHosts,
        hostsList,
        changeHostList,
        editList,
      ];
}
