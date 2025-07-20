class AppStrings {
  // App Info
  static const String appName = 'KeepSafe';
  static const String appDescription = 'Your Personal Secure Vault';
  static const String appVersion = 'App Version';
  static const String loading = 'Loading...';

  // Settings Sections
  static const String security = 'Security';
  static const String dataManagement = 'Data Management';
  static const String appSettings = 'App Settings';
  static const String about = 'About';

  // Security
  static const String useBiometric = 'Use %s';
  static const String enableBiometric = 'Enable %s authentication';
  static const String changePin = 'Change PIN';
  static const String updateSecurityPin = 'Update your security PIN';
  static const String biometricEnabled = 'Biometric authentication enabled';
  static const String biometricDisabled = 'Biometric authentication disabled';
  static const String biometricFailed = 'Failed to %s biometrics: %s';

  // Data Management
  static const String exportData = 'Export Data';
  static const String backupData = 'Backup your data to a file';
  static const String importData = 'Import Data';
  static const String restoreData = 'Restore data from a backup file';
  static const String clearAllData = 'Clear All Data';
  static const String deleteAllInfo = 'Delete all your stored information';
  static const String dataExported = 'Data exported successfully';
  static const String dataImported = 'Data imported successfully';
  static const String dataCleared = 'All data has been cleared';
  static const String dataExportFailed = 'Failed to export data: %s';
  static const String dataImportFailed = 'Failed to import data: %s';
  static const String dataClearFailed = 'Failed to clear data: %s';

  // Backup Password
  static const String backupPassword = 'Backup Password';
  static const String setBackupPassword = 'Set Backup Password';
  static const String backupPasswordRequired = 'Backup Password Required';
  static const String backupPasswordDescription =
      'Create a password to protect your backup files';
  static const String backupPasswordWarning =
      'This password is different from your unlock PIN and is used only for backup files';
  static const String backupPasswordSet = 'Backup password set successfully';
  static const String backupPasswordIncorrect = 'Incorrect backup password';
  static const String backupPasswordEmpty = 'Backup password cannot be empty';
  static const String backupPasswordMismatch = 'Backup passwords do not match';
  static const String backupPasswordConfirm = 'Confirm Backup Password';
  static const String backupPasswordEnter = 'Enter Backup Password';
  static const String backupPasswordForgot =
      'If you forget this password, you will not be able to restore your backup';
  static const String backupPasswordSecure =
      'Your backup is now protected by a password';
  static const String backupPasswordLegacy =
      'This backup was created without a password. For better security, create a new backup with a password.';

  // Theme
  static const String theme = 'Theme';
  static const String selectTheme = 'Select Theme';
  static const String systemDefault = 'System default';
  static const String followSystem = 'Follow system settings';
  static const String lightTheme = 'Light';
  static const String darkTheme = 'Dark';

  // About
  static const String shareApp = 'Share App';
  static const String tellAboutApp = 'Tell others about KeepSafe';
  static const String rateUs = 'Rate Us';
  static const String rateOnStore = 'Rate us on the app store';
  static const String privacyPolicy = 'Privacy Policy';
  static const String viewPrivacyPolicy = 'View our privacy policy';
  static const String connectUs = 'Connect Us';
  static const String sendFeedback = 'Send us feedback or get support';

  // Dialogs
  static const String cancel = 'CANCEL';
  static const String delete = 'DELETE';
  static const String change = 'CHANGE';
  static const String continueText = 'CONTINUE';
  static const String ok = 'OK';
  static const String error = 'Error';
  static const String close = 'CLOSE';

  // Messages
  static const String pinUpdated = 'PIN updated successfully';
  static const String invalidPin = 'Invalid PIN';
  static const String pinsNotMatch = 'PINs do not match';
  static const String clearDataWarning =
      'This will permanently delete all your stored credentials and family members. This action cannot be undone.';
  static const String importDataWarning =
      'Importing data will replace all your current data. Are you sure you want to continue?';
  static const String backupCreated =
      'Your backup has been created and can be imported on other devices where you have KeepSafe installed.';
  static const String backupCompatibilityIssue =
      'The backup file could not be imported because it was created on a different device or with a different app version.';
  static const String recommendation = 'Recommendation:';
  static const String createNewBackup =
      '• Create a new backup on your original device using the latest app version';
  static const String manualRecreate =
      '• If that\'s not possible, you\'ll need to manually recreate your data on this device';
  static const String understand = 'OK, I UNDERSTAND';

  // Contact
  static const String connectWithUs = 'Connect With Us';
  static const String email = 'Email';
  static const String website = 'Website';
  static const String supportEmail = 'mayurdabhi041@gmail.com';
  static const String websiteUrl = 'https://mayur.dev/';
  static const String emailSubject = 'KeepSafe Feedback';
  static const String couldNotLaunch = 'Could not launch %s';

  // URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mayur.keepsafe';
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';
  static const String appWebsite = 'https://keepsafe.app';
  static const String privacyPolicyUrl =
      'https://mayur.dev/setkeep-safe-privacy-policy';

  // Upgrade Notice
  static const String upgradeNoticeTitle = 'Important: Secure Your Backups';
  static const String upgradeNoticeBody =
      'We have added password protection to your backups for better security and cross-device support.\n\nPlease set a backup password and create a new backup file. Old backups are less secure and may not work on other devices.';
  static const String upgradeNoticeAction = 'Set Password & Backup';
  static const String upgradeNoticeRemindMeLater = 'Remind Me Later';
  static const String upgradeBanner =
      'Your backups are not yet password-protected. Set a backup password and create a new backup for better security and cross-device restore.';

  static const String currentPin = 'Current PIN';
  static const String newPin = 'New PIN';
  static const String confirmPin = 'Confirm New PIN';
}
