import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	let menuHandler = MenuHandler()
	var windows:[NSWindow] = []
	let shortcuts = Shortcuts()
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		statusItem.menu = Settings.setupMenu(target: menuHandler)
		
		if let button = statusItem.button {
			button.title = "VOCR"
			button.action = #selector(click(_:))
		}

		let fileManager = FileManager.default
		let home = fileManager.homeDirectoryForCurrentUser
		let launchFolder = home.appendingPathComponent("Library/LaunchAgents")
		if !fileManager.fileExists(atPath: launchFolder.path) {
			try! fileManager.createDirectory(at: launchFolder, withIntermediateDirectories: false, attributes: nil)
		}
		let launchPath = "Library/LaunchAgents/com.chikim.VOCR.plist"
		let launchFile = home.appendingPathComponent(launchPath)
		if !Settings.launchOnBoot && !fileManager.fileExists(atPath: launchFile.path) {
			let bundle = Bundle.main
			let bundlePath = bundle.path(forResource: "com.chikim.VOCR", ofType: "plist")
			try! fileManager.copyItem(at: URL(fileURLWithPath: bundlePath!), to: launchFile)
			Settings.launchOnBoot = true
			Settings.save()
		}

		windows = NSApplication.shared.windows
		NSApplication.shared.hide(self)
		windows[1].close()
		
	}
	
	@objc func click(_ sender: Any?) {
		print("Clicked")
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		Settings.removeMouseMonitor()
	}
	
	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		if let image = NSImage(contentsOf: fileURL) {
			var rect = CGRect(origin: .zero, size: image.size)
			if let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
				GPT.askGpt(image:cgImage)

				return true  // Indicate success
			} else {
				return false
			}
		}
		return false
	}
	
}
