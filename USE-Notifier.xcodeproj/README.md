# USE-Notifier 🔴

<div align="center">

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**Real-time monitoring for Better Stack 500 errors on your iPhone**

Stay informed about critical server errors with instant notifications, beautiful widgets, and comprehensive error tracking.

</div>

---

## 📱 Features

### Core Functionality
- **🔔 Real-time Notifications** - Get instant alerts when 500 errors occur on your servers
- **🔄 Automatic Background Refresh** - Monitors errors even when the app is closed (every 15-30 minutes)
- **⚡️ Foreground Polling** - Checks for new errors every 30 seconds when app is active
- **📊 Home Screen Widget** - Displays the latest error at a glance (small & medium sizes)
- **🎯 Better Stack Integration** - Direct connection to Better Stack's logging API
- **💾 Local Storage** - Keeps up to 200 most recent errors cached locally
- **🔁 Retry Logic** - Exponential backoff for reliable network requests

### User Experience
- **🎨 Beautiful UI** - Native SwiftUI design with modern iOS aesthetics
- **📈 Error Timeline** - Chronological list of all 500 errors with timestamps
- **🏷️ Status Badges** - Visual indicators for "LATEST" errors
- **⏱️ Relative Timestamps** - Human-readable time indicators ("2 minutes ago")
- **🔄 Pull-to-Refresh** - Manual refresh with intuitive gesture
- **⚙️ Customizable Settings** - Control notifications, widgets, and refresh behavior
- **🗑️ Data Management** - Clear stored errors with one tap

### Technical Features
- **🧵 Swift Concurrency** - Modern async/await throughout
- **🎯 Background Tasks** - BGTaskScheduler for reliable background updates
- **📦 App Groups** - Shared data between app and widget
- **🔒 Secure Credentials** - Environment-based configuration (no hardcoded secrets)
- **🔐 HTTPS Enforced** - Secure communication with Better Stack API
- **🎭 SwiftUI Lifecycle** - Pure SwiftUI app architecture
- **📱 iOS 18+** - Built for the latest iOS features

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** (Xcode 16 recommended)
- **iOS 18.0+** device or simulator
- **Better Stack Account** with logging enabled
- **macOS 14.0+** for development

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Alioskillers/USE-Notifier.git
   cd USE-Notifier
   ```

2. **Configure Better Stack Credentials**
   
   Copy the template configuration file:
   ```bash
   cp Config.xcconfig.template Config.xcconfig
   ```
   
   Edit `Config.xcconfig` with your actual Better Stack credentials:
   ```xcconfig
   BETTERSTACK_HOST = your-region-connect.betterstackdata.com
   BETTERSTACK_USERNAME = your_clickhouse_username
   BETTERSTACK_PASSWORD = your_clickhouse_password
   BETTERSTACK_SOURCE_TABLE = t123456_your_source_table
   ```
   
   > ⚠️ **IMPORTANT**: `Config.xcconfig` is in `.gitignore` and should NEVER be committed to version control. Only commit `Config.xcconfig.template`.

3. **Open in Xcode**
   ```bash
   open USE-Notifier.xcodeproj
   ```

4. **Configure Signing**
   - Select the project in Xcode
   - Go to **Signing & Capabilities**
   - Enable **Automatically manage signing**
   - Select your **Team** (Apple ID)
   - Repeat for the **ErrorPagerWidgetExtension** target

5. **Generate App Icon** (Optional)
   ```bash
   swift -e '
   import AppKit
   func gen(_ s:CGFloat)->NSImage{
   let i=NSImage(size:NSSize(width:s,height:s))
   i.lockFocus()
   NSGradient(colors:[NSColor(red:1,green:0.2,blue:0.2,alpha:1),NSColor(red:0.8,green:0,blue:0,alpha:1)])?.draw(in:NSBezierPath(roundedRect:NSRect(x:0,y:0,width:s,height:s),xRadius:s*0.22,yRadius:s*0.22),angle:135)
   let t=NSAttributedString(string:"500",attributes:[.font:NSFont.systemFont(ofSize:s*0.4,weight:.bold),.foregroundColor:NSColor.white])
   t.draw(at:NSPoint(x:(s-t.size().width)/2,y:(s-t.size().height)/2))
   i.unlockFocus()
   return i
   }
   try?FileManager.default.createDirectory(atPath:"AppIconAssets",withIntermediateDirectories:true)
   for(n,s)in[("icon_1024",CGFloat(1024)),("icon_180",180),("icon_120",120)]{
   if let d=gen(s).tiffRepresentation,let b=NSBitmapImageRep(data:d),let p=b.representation(using:.png,properties:[:])
   {try?p.write(to:URL(fileURLWithPath:"AppIconAssets/\(n).png"));print("✅ \(n).png")}
   }
   '
   ```
   Then drag `AppIconAssets/icon_1024.png` into Xcode's Assets.xcassets → AppIcon

6. **Build and Run**
   - Select your device or simulator
   - Press **⌘R** or click the **Play** button

---

## 📖 Usage

### First Launch

1. **Grant Notification Permission** - Tap "Allow" when prompted
2. **View Error List** - See all recent 500 errors from Better Stack
3. **Pull to Refresh** - Swipe down to manually check for new errors

### Adding the Widget

1. Long-press on your **Home Screen**
2. Tap the **+ button** in the top corner
3. Search for **"Error Pager"** or **"USE-Notifier"**
4. Select widget size (**Small** or **Medium**)
5. Tap **Add Widget**

The widget displays:
- Latest error source and message
- Timestamp of the error
- Or "No errors" if everything is running smoothly

### Settings

Access settings via the ⚙️ icon in the top-right corner:

#### Notifications
- **Enable/Disable Notifications** - Control alert behavior
- Notifications appear for new errors even in background

#### Widget
- **Enable/Disable Widget** - Toggle widget functionality
- View setup instructions

#### Refresh Settings
- **Background Refresh** - Every 15-30 minutes (iOS-controlled)
- **Foreground Polling** - Every 30 seconds when app is active

#### Data Management
- **View Stored Errors** - See total count of cached errors
- **Clear All Errors** - Remove all locally stored data

---

## 🏗️ Architecture

### Project Structure

```
USE-Notifier/
├── USE-Notifier/               # Main app target
│   ├── ContentView.swift       # Main error list view
│   ├── SettingsView.swift      # Settings screen
│   ├── DetailView.swift        # Error detail view
│   ├── Models/
│   │   ├── LogEntry.swift      # Error data model
│   │   └── LogStore.swift      # Data management & fetching
│   ├── Networking/
│   │   └── BetterStackClient.swift  # API client
│   ├── Notifications/
│   │   └── NotificationManager.swift  # Push notification handler
│   └── AppDelegate.swift       # Background tasks & lifecycle
│
├── ErrorPagerWidget/           # Widget extension
│   ├── ErrorPagerWidget.swift  # Widget views & timeline
│   ├── ErrorPagerWidgetBundle.swift
│   └── ErrorPagerWidgetControl.swift
│
└── Config.xcconfig             # Better Stack credentials (gitignored)
```

### Key Components

#### `LogStore` (Main Actor)
- Manages error data with `@Published` properties
- Handles foreground and background refresh
- Implements exponential backoff retry logic
- Syncs with widget via App Groups

#### `BetterStackClient`
- Constructs Better Stack API requests
- Parses ClickHouse SQL responses
- Returns structured `LogEntry` models

#### `NotificationManager`
- Requests notification authorization
- Creates and schedules local notifications
- Handles foreground notification presentation

#### `AppDelegate`
- Registers background tasks with `BGTaskScheduler`
- Schedules periodic refresh (every 15 minutes)
- Manages app lifecycle events

#### `ErrorPagerWidget`
- Provides timeline with latest error
- Updates every 15 minutes
- Supports small and medium sizes

---

## 🔧 Configuration

### App Groups

The app uses an App Group to share data between the main app and widget:
```
group.com.ali.ios.USE-Notifier
```

Configure in Xcode:
1. Select target → **Signing & Capabilities**
2. Add **App Groups** capability
3. Check `group.com.ali.ios.USE-Notifier`
4. Repeat for **ErrorPagerWidgetExtension** target

### Background Modes

Configured in `Info.plist`:
- `fetch` - Background fetch
- `processing` - Background processing
- `remote-notification` - Remote notifications (future)

### Info.plist Keys

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.ali.ios.USE-Notifier.refresh</string>
</array>
```

---

## 🧪 Testing

### Debug Features

The app includes debug-only features (only in Debug builds):

- **Console Logging** - Detailed logs wrapped in `#if DEBUG`
- **Background Task Scheduling** - Visible success/failure logs

### Testing Background Refresh

On a **real device** (doesn't work in simulator):

1. Run app from Xcode
2. Put app in background
3. In Xcode, pause execution (⌃⌘Y)
4. In LLDB console:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ali.ios.USE-Notifier.refresh"]
   ```
5. Continue execution (⌃⌘Y)

### Testing Notifications

1. Run the app
2. Press **Home button** to background it
3. Wait for background refresh or trigger manually
4. New errors should trigger notifications

---

## 📋 Requirements

### System Requirements
- iOS 18.0 or later
- iPhone or iPad

### User Requirements
- **Background App Refresh** must be enabled:
  - Settings → General → Background App Refresh (ON)
  - Settings → USE-Notifier → Background App Refresh (ON)
- **Low Power Mode** disables background refresh
- **Notification permissions** for alerts

### Developer Requirements
- Xcode 15.0+ (Xcode 16 recommended)
- macOS 14.0+ (Sonoma or later)
- Apple Developer account or Apple ID

---

## 🎯 Roadmap

### Planned Features
- [ ] Push notification support (for instant alerts)
- [ ] Multiple source monitoring
- [ ] Error filtering and search
- [ ] Dark mode theme customization
- [ ] iPad-optimized layout
- [ ] Export error logs
- [ ] Error statistics and trends
- [ ] Custom alert sounds
- [ ] Critical vs. warning severity levels
- [ ] Integration with other logging services

---

## 🐛 Known Issues

### Background Refresh Limitations
- Background tasks only work on **real devices** (not simulator)
- iOS controls when background tasks actually run
- Frequency depends on app usage patterns, battery level, and system load
- Low Power Mode disables all background refresh

### Free Apple ID Limitations
- Apps signed with free Apple ID expire after **7 days**
- Need to reinstall weekly
- Limited to **3 apps** simultaneously
- Consider enrolling in Apple Developer Program ($99/year) for production use

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Ali Ahmed**

- GitHub: [@Alioskillers](https://github.com/Alioskillers)

---

## 🙏 Acknowledgments

- [Better Stack](https://betterstack.com/) for the logging platform
- Apple for SwiftUI and WidgetKit frameworks
- The Swift community for excellent resources and support

---

## 📞 Support

If you have any questions or run into issues:

1. Check the [Issues](https://github.com/Alioskillers/USE-Notifier/issues) page
2. Create a new issue with detailed information
3. Include Xcode version, iOS version, and steps to reproduce

---

<div align="center">

Made with ❤️ and Swift

**Stay informed. Stay proactive. Never miss a critical error.**

</div>
