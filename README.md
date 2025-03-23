# KeepSafe - Your Personal Secure Vault

KeepSafe is a secure mobile application built with Flutter that allows you to safely store confidential information such as ATM card details, bank accounts, website logins, and more - for both yourself and your family members.

## Features

- **Secure Storage**: All sensitive data is encrypted using AES encryption
- **PIN & Biometric Authentication**: Protect your data with a 4-digit PIN and biometric authentication (fingerprint/face ID)
- **Family Member Management**: Store credentials for your family members
- **Categorized Information**: Organize credentials by type (Bank Account, Card, Website, App, etc.)
- **Advanced Search**: Search across all stored data and filter by category or family member
- **Dark Mode Support**: Comfortable viewing in any lighting conditions
- **Data Portability**: Export and import your encrypted data for backup or device transfer

## Security Features

- AES 256-bit encryption for all sensitive data
- Secure storage of encryption keys using the device's secure storage
- Biometric authentication (fingerprint or face ID) when available
- 4-digit PIN fallback authentication
- Automatic locking when app is in background
- Encrypted data export and import for secure backups

## Data Management

### Export & Backup
- Create encrypted backups of all your stored credentials
- Share backup files to cloud storage (Google Drive, Dropbox, etc.)
- Fully encrypted data ensures privacy even in cloud storage

### Import & Restore
- Easily restore your data from backup files
- Transfer your credentials when switching to a new device
- Content validation ensures only valid backup files are imported

## Screenshots

(Screenshots will be added here)

## Getting Started

### Prerequisites

- Flutter 2.18.0 or higher
- Android Studio or Xcode for native development

### Installation

1. Clone the repository
```
git clone https://github.com/yourusername/keepsafe.git
```

2. Navigate to the project directory
```
cd keepsafe
```

3. Install dependencies
```
flutter pub get
```

4. Run the app
```
flutter run
```

## Tech Stack

- **Flutter**: For cross-platform mobile development
- **Provider**: For state management
- **SQLite**: For local database storage
- **Encrypt**: For AES encryption
- **Flutter Secure Storage**: For secure key storage
- **Local Auth**: For biometric authentication
- **Share Plus**: For sharing backup files
- **File Picker**: For selecting backup files during import

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to the Flutter team for the amazing framework
- All the open source libraries used in this project 