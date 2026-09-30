import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // 对齐 360 压缩默认主窗口尺寸
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let width: CGFloat = 1120
    let height: CGFloat = 720
    let frame = NSRect(
      x: screen.midX - width / 2,
      y: screen.midY - height / 2,
      width: width,
      height: height
    )
    self.contentViewController = flutterViewController
    self.setFrame(frame, display: true)
    self.title = "OpenZip"
    self.minSize = NSSize(width: 900, height: 560)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
