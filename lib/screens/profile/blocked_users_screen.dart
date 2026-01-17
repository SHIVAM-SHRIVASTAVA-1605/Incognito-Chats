import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/config.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final appProvider = context.read<AppProvider>();
    final result = await appProvider.userService.getBlockedUsers();

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _blockedUsers = result['users'] as List<UserModel>;
      } else {
        _error = result['error'];
      }
    });
  }

  Future<void> _unblockUser(UserModel user) async {
    final appProvider = context.read<AppProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await appProvider.userService.unblockUser(user.id);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} has been unblocked')),
        );
        _loadBlockedUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to unblock user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBlockedUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No blocked users',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: ListView.builder(
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accentColor,
                              backgroundImage: user.profilePicture != null
                                  ? CachedNetworkImageProvider(
                                      '${Config.baseUrl}${user.profilePicture}',
                                    )
                                  : null,
                              child: user.profilePicture == null
                                  ? Text(
                                      user.displayName[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(user.displayName),
                            trailing: TextButton(
                              onPressed: () => _unblockUser(user),
                              child: const Text('Unblock'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
