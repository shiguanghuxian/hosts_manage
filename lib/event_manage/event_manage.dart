import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

// 状态菜单变化事件 dns通知home
class ChangeContextMenuDNSToHome {
  const ChangeContextMenuDNSToHome();
}

// 状态菜单变化事件 home通知dns
class ChangeContextMenuHomeToDNS {
  const ChangeContextMenuHomeToDNS();
}

// 状态菜单变化事件 Socks5通知home
class ChangeContextMenuSocks5ToHome {
  const ChangeContextMenuSocks5ToHome();
}

// 状态菜单变化事件 home通知Socks5
class ChangeContextMenuHomeToSocks5 {
  const ChangeContextMenuHomeToSocks5();
}
