<div align="center">
  <h1>📱 SMS Manager</h1>
  <p><strong>A powerful, offline Android testing and utility tool to generate mock SMS messages directly into your native inbox.</strong></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/UI-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Flutter"></a>
    <a href="https://kotlinlang.org"><img src="https://img.shields.io/badge/Backend-Kotlin-7F52FF?style=for-the-badge&logo=kotlin" alt="Kotlin"></a>
    <a href="https://github.com/thejulan/fake-sms/releases"><img src="https://img.shields.io/badge/Download-APK-2ea44f?style=for-the-badge&logo=android" alt="Download"></a>
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  </p>
</div>

<br/>

<div align="center">
  <a href="https://github.com/thejulan/fake-sms/releases/latest">
    <img src="https://img.shields.io/badge/⬇️_DOWNLOAD_LATEST_APK-Click_Here-brightgreen?style=for-the-badge&logo=android" alt="Download Latest Release" />
  </a>
</div>

<br/>

## 📸 Screenshots
<div align="center">
  <img src="https://raw.githubusercontent.com/thejulan/fake-sms/refs/heads/main/assets/homescreen.png" width="250" alt="Home Screen" />
  &nbsp;&nbsp;&nbsp;&nbsp;
</div>
<p align="center"><i>Experience a beautiful 2026 dark-mode UI built with glassmorphism, Phosphor icons, and smooth transitions.</i></p>

---

## ✨ Features
- **Direct Inbox Insertion:** Bypasses standard Android restrictions by temporarily acting as the Default SMS App, allowing direct database inserts without root.
- **Bulk Generation:** Use the built-in slider to generate and push up to 100 messages simultaneously in a single tap!
- **Native Contact Picker:** Seamlessly select real contacts from your address book using native Kotlin hooks instead of Flutter plugins.
- **Full Time Manipulation:** Use custom date & time pickers to alter both the 'Sent' and 'Received' timestamps of your messages effortlessly.
- **Folder Targeting:** Push your generated messages exactly where you want them using the custom card grid: *Inbox*, *Sent*, *Draft*, *Failed*, or *Queued* folders.
- **Offline & Private:** SMS Manager requests *no* internet permissions. Your data, contacts, and generated messages never leave your device.

## 🚀 Quick Start
1. Go to the [**Releases**](https://github.com/thejulan/fake-sms/releases) page.
2. Download the appropriate `.apk` file for your device (e.g., `app-arm64-v8a-release.apk`).
3. Install the APK on your Android device (ensure "Install from Unknown Sources" is allowed).
4. Launch the app, grant the requested permissions when prompted, and start generating!

## 🛠️ Building from Source
Because this app relies heavily on native Android Method Channels to communicate with the Telephony provider, ensure your Android SDK is up to date.

```bash
# Clone the repository
git clone https://github.com/thejulan/fake-sms.git

# Navigate into the directory
cd fake-sms

# Get Flutter dependencies
flutter pub get

# Build the release APK
flutter build apk --release
```
The compiled APK will be available in `build/app/outputs/flutter-apk/app-release.apk`.

## 🛡️ Privacy Statement
Your data is yours. This app **does not** collect, store, or transmit any data externally. The `READ_CONTACTS` and `READ_SMS` permissions are solely utilized locally on your device to pick contacts and write directly to your messaging database.

## 🤝 Contributing
Found a bug or have a brilliant idea for a new feature? 
We'd love to hear it! Open a [New Issue](https://github.com/thejulan/fake-sms/issues/new) to report a bug or request a feature. Pull Requests are always welcome!

<div align="center">
  <sub>Built with ❤️ by Julan.</sub>
</div>
