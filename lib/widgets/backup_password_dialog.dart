import 'package:flutter/material.dart';
import 'package:keepsafe/utils/strings.dart';

class BackupPasswordDialog extends StatefulWidget {
  final bool isSettingPassword;
  final String? initialPassword;

  const BackupPasswordDialog({
    Key? key,
    required this.isSettingPassword,
    this.initialPassword,
  }) : super(key: key);

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordError = false;
  bool _showConfirmPasswordError = false;
  String _passwordError = '';
  String _confirmPasswordError = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialPassword != null) {
      _passwordController.text = widget.initialPassword!;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _showPasswordError = false;
      _passwordError = '';

      if (_passwordController.text.isEmpty) {
        _showPasswordError = true;
        _passwordError = AppStrings.backupPasswordEmpty;
      } else if (_passwordController.text.length < 4) {
        _showPasswordError = true;
        _passwordError = 'Password must be at least 4 characters long';
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _showConfirmPasswordError = false;
      _confirmPasswordError = '';

      if (widget.isSettingPassword) {
        if (_confirmPasswordController.text.isEmpty) {
          _showConfirmPasswordError = true;
          _confirmPasswordError = AppStrings.backupPasswordEmpty;
        } else if (_confirmPasswordController.text !=
            _passwordController.text) {
          _showConfirmPasswordError = true;
          _confirmPasswordError = AppStrings.backupPasswordMismatch;
        }
      }
    });
  }

  void _submit() {
    _validatePassword();
    if (widget.isSettingPassword) {
      _validateConfirmPassword();
    }

    if (!_showPasswordError &&
        (!widget.isSettingPassword || !_showConfirmPasswordError)) {
      Navigator.of(context).pop(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isSettingPassword
            ? AppStrings.setBackupPassword
            : AppStrings.backupPasswordRequired,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSettingPassword) ...[
              Text(
                AppStrings.backupPasswordDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.backupPasswordWarning,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: widget.isSettingPassword
                    ? 'Enter Password'
                    : AppStrings.backupPasswordEnter,
                errorText: _showPasswordError ? _passwordError : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (value) {
                if (_showPasswordError) {
                  _validatePassword();
                }
                if (widget.isSettingPassword && _showConfirmPasswordError) {
                  _validateConfirmPassword();
                }
              },
              onSubmitted: (value) {
                if (widget.isSettingPassword) {
                  // Focus on confirm password field
                  FocusScope.of(context).nextFocus();
                } else {
                  _submit();
                }
              },
            ),
            if (widget.isSettingPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: AppStrings.backupPasswordConfirm,
                  errorText:
                      _showConfirmPasswordError ? _confirmPasswordError : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                onChanged: (value) {
                  if (_showConfirmPasswordError) {
                    _validateConfirmPassword();
                  }
                },
                onSubmitted: (value) => _submit(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.backupPasswordForgot,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(
            widget.isSettingPassword ? 'Set Password' : 'Continue',
          ),
        ),
      ],
    );
  }
}
