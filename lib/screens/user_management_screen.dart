import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final users = await provider.getUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar usuu00e1rios: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserDialog(
        onSave: (name, email, password, role) async {
          final provider = Provider.of<AppStateProvider>(context, listen: false);
          
          try {
            await provider.registerUser(
              name: name,
              email: email,
              password: password,
              role: role,
            );
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuu00e1rio criado com sucesso!'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
            
            _loadUsers();
          } catch (e) {
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao criar usuu00e1rio: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDialog(
        user: user,
        onSave: (name, email, password, role) async {
          final provider = Provider.of<AppStateProvider>(context, listen: false);
          
          try {
            // Create updated user object
            final updatedUser = user.copyWith(
              name: name,
              email: email,
              role: role,
              passwordHash: password.isNotEmpty 
                  ? User.hashPassword(password) 
                  : user.passwordHash,
            );
            
            await provider.updateUser(updatedUser);
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuu00e1rio atualizado com sucesso!'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
            
            _loadUsers();
          } catch (e) {
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar usuu00e1rio: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Usuu00e1rio'),
        content: Text('Tem certeza que deseja excluir o usuu00e1rio ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final provider = Provider.of<AppStateProvider>(context, listen: false);
              
              try {
                await provider.deleteUser(user.id);
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuu00e1rio excluu00eddo com sucesso!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
                
                _loadUsers();
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir usuu00e1rio: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuu00e1rios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? _buildEmptyState()
                  : _buildUserList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Usuu00e1rio',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum usuu00e1rio cadastrado',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Usuu00e1rio'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    // Current user
    final currentUser = Provider.of<AppStateProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == user.id;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Icon(
                _getRoleIcon(user.role),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Vocu00ea',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleName(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Can't edit/delete self (to prevent locking yourself out)
                if (!isCurrentUser) ...[  
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                    onPressed: () => _showEditUserDialog(user),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(user),
                    tooltip: 'Excluir',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.technician:
        return 'Tu00e9cnico';
      case UserRole.viewer:
        return 'Visualizador';
      default:
        return 'Usuu00e1rio';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.technician:
        return Icons.engineering;
      case UserRole.viewer:
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.technician:
        return AppTheme.primaryColor;
      case UserRole.viewer:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class UserDialog extends StatefulWidget {
  final User? user;
  final Function(String name, String email, String password, UserRole role) onSave;

  const UserDialog({
    super.key,
    this.user,
    required this.onSave,
  });

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.viewer;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Usuu00e1rio' : 'Novo Usuu00e1rio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isEditing, // Cannot edit email for existing users
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Por favor, informe um email vu00e1lido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Nova Senha (opcional)' : 'Senha',
                  prefixIcon: const Icon(Icons.lock),
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
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'Por favor, informe a senha';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                decoration: const InputDecoration(
                  labelText: 'Funu00e7u00e3o',
                  prefixIcon: Icon(Icons.badge),
                ),
                value: _selectedRole,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: UserRole.admin,
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Text('Administrador'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRole.technician,
                    child: Row(
                      children: [
                        Icon(Icons.engineering, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        const Text('Tu00e9cnico'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRole.viewer,
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.teal),
                        const SizedBox(width: 12),
                        const Text('Visualizador'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              widget.onSave(
                _nameController.text.trim(),
                _emailController.text.trim(),
                _passwordController.text,
                _selectedRole,
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}