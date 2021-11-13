import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    Swift.print("applicationShouldTerminateAfterLastWindowClosed")
    NSApp.hide(nil)
    return false
  }
        
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    Swift.print("applicationShouldHandleReopen")
    if !flag {
      for window: AnyObject in NSApplication.shared.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }
}
