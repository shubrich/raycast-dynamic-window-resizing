import Cocoa
import ApplicationServices
import Carbon.HIToolbox

// MARK: - Error reporting

func die(_ tag: String, code: Int32 = 1) -> Never {
  FileHandle.standardError.write(Data("error:\(tag)\n".utf8))
  exit(code)
}

// MARK: - AX helpers

func frontmostWindow() -> AXUIElement? {
  guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
  let appAX = AXUIElementCreateApplication(app.processIdentifier)
  var windowRef: CFTypeRef?
  let err = AXUIElementCopyAttributeValue(appAX, kAXFocusedWindowAttribute as CFString, &windowRef)
  guard err == .success, let raw = windowRef else { return nil }
  return (raw as! AXUIElement)
}

func axSize(of window: AXUIElement) -> CGSize? {
  var ref: CFTypeRef?
  guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &ref) == .success,
        let value = ref
  else { return nil }
  var size = CGSize.zero
  AXValueGetValue((value as! AXValue), .cgSize, &size)
  return size
}

func setAXSize(_ window: AXUIElement, _ size: CGSize) {
  var s = size
  guard let value = AXValueCreate(.cgSize, &s) else { return }
  AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
}

// MARK: - Boot

guard AXIsProcessTrusted() else { die("accessibility-not-granted", code: 2) }
guard let window = frontmostWindow() else { die("no-window", code: 3) }
guard let initialSize = axSize(of: window) else { die("no-size", code: 4) }

let initialCursor = CGEvent(source: nil)?.location ?? .zero

// Snapshot which modifiers are held right now — releasing any of them cancels.
let modifierMask: UInt64 = CGEventFlags.maskCommand.rawValue
  | CGEventFlags.maskAlternate.rawValue
  | CGEventFlags.maskControl.rawValue
  | CGEventFlags.maskShift.rawValue

let initialModifiers = CGEventSource.flagsState(.combinedSessionState).rawValue & modifierMask

// MARK: - Resize loop

let minSize = CGSize(width: 80, height: 80)

let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
  // Cancel: any originally-held modifier was released.
  let currentModifiers = CGEventSource.flagsState(.combinedSessionState).rawValue & modifierMask
  if (currentModifiers & initialModifiers) != initialModifiers {
    exit(0)
  }

  // Cancel: Escape pressed (fallback when the hotkey has no modifiers).
  if CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(kVK_Escape)) {
    exit(0)
  }

  let cursor = CGEvent(source: nil)?.location ?? initialCursor
  // CGEvent locations are in Quartz (top-left origin, y grows downward), so
  // moving the cursor right/down increases width/height — matching the
  // native bottom-right resize handle.
  let newSize = CGSize(
    width: max(minSize.width, initialSize.width + (cursor.x - initialCursor.x)),
    height: max(minSize.height, initialSize.height + (cursor.y - initialCursor.y))
  )
  setAXSize(window, newSize)
}

RunLoop.main.add(timer, forMode: .common)
RunLoop.main.run()
