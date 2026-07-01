import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme.dart';
import 'info_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime _sentDateTime = DateTime.now().subtract(const Duration(minutes: 5));
  DateTime _receivedDateTime = DateTime.now();
  double _messageCount = 1;

  String _selectedFolder = 'Inbox';
  final List<String> _folders = ['Inbox', 'Sent', 'Draft', 'Failed', 'Queued'];

  static const platform = MethodChannel('fakesms.channel');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isSent) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isSent ? _sentDateTime : _receivedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(isSent ? _sentDateTime : _receivedDateTime),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isSent) {
        _sentDateTime = newDateTime;
      } else {
        _receivedDateTime = newDateTime;
      }
    });
  }

  Future<void> _chooseFromContacts() async {
    try {
      final Map<dynamic, dynamic>? result =
          await platform.invokeMethod('pickContact');
      if (result != null) {
        setState(() {
          _nameController.text = result['name'] ?? '';
          _phoneController.text = result['phoneNumber'] ?? '';
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick contact: ${e.message}')),
        );
      }
    }
  }

  Future<void> _generateFakeSMS() async {
    if (_phoneController.text.isEmpty && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number or name')),
      );
      return;
    }
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message body')),
      );
      return;
    }

    try {
      final bool isDefault =
          await platform.invokeMethod('requestDefaultSms') ?? false;

      if (!isDefault) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Must be default SMS app to insert messages.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      int successCount = 0;
      for (int i = 0; i < _messageCount.toInt(); i++) {
        await platform.invokeMethod('insertSMS', {
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'message': _messageController.text,
          'sentTime': _sentDateTime.millisecondsSinceEpoch,
          'receivedTime': _receivedDateTime.millisecondsSinceEpoch,
          'folder': _selectedFolder,
        });
        successCount++;
      }
      if (mounted) {
        showGeneralDialog(
          context: context,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale:
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: animation,
                child: AlertDialog(
                  backgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.all(32),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 64),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Success!',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your $successCount message(s) were added directly to your SMS app. Open your messaging app to view them.',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Ok'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert SMS: ${e.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Message'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.info(PhosphorIconsStyle.regular)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InfoScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sender Info'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: Icon(
                        PhosphorIcons.addressBook(PhosphorIconsStyle.fill),
                        color: AppTheme.primary),
                    onPressed: _chooseFromContacts,
                    tooltip: 'Choose from contacts',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Name (Optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Message Content'),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Number of Messages (${_messageCount.toInt()})'),
            const SizedBox(height: 8),
            Slider(
              value: _messageCount,
              min: 1,
              max: 100,
              divisions: 99,
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.surfaceHighlight,
              onChanged: (value) {
                setState(() {
                  _messageCount = value;
                });
              },
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Timing'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Sent',
                    dateTime: _sentDateTime,
                    onTap: () => _pickDateTime(true),
                    icon: PhosphorIcons.paperPlaneRight(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Received',
                    dateTime: _receivedDateTime,
                    onTap: () => _pickDateTime(false),
                    icon: PhosphorIcons.trayArrowDown(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Destination Folder'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: _folders.map((folder) {
                final isSelected = _selectedFolder == folder;
                IconData iconData;
                switch (folder) {
                  case 'Inbox':
                    iconData =
                        PhosphorIcons.trayArrowDown(PhosphorIconsStyle.fill);
                    break;
                  case 'Sent':
                    iconData =
                        PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill);
                    break;
                  case 'Draft':
                    iconData =
                        PhosphorIcons.fileDashed(PhosphorIconsStyle.fill);
                    break;
                  case 'Failed':
                    iconData =
                        PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
                    break;
                  case 'Queued':
                    iconData = PhosphorIcons.hourglass(PhosphorIconsStyle.fill);
                    break;
                  default:
                    iconData = PhosphorIcons.folder(PhosphorIconsStyle.fill);
                }

                return GestureDetector(
                  onTap: () => setState(() => _selectedFolder = folder),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconData,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          folder,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateFakeSMS,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Generate SMS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, h:mm a').format(dateTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
