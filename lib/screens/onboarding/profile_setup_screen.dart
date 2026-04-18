import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// Profile setup screen — collects name, age, gender, preference, relationship type
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Gender _gender = Gender.man;
  Preference _preference = Preference.everyone;
  RelationshipType _relationshipType = RelationshipType.solo;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    await context.read<UserProvider>().createProfile(
          uid: uid,
          nameOrAlias: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _gender,
          preference: _preference,
          relationshipType: _relationshipType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Progress indicator
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: index <= _currentStep
                              ? AppTheme.primary
                              : AppTheme.surfaceLighter,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Step content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStep(),
                  ),
                ),

                // Error
                if (userProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      userProvider.errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),

                // Navigation
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            child: const Text('Back'),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 1,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: userProvider.isLoading ? null : _nextStep,
                          child: userProvider.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentStep < 2 ? 'Continue' : 'Create Profile',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildIdentityStep();
      case 2:
        return _buildPreferenceStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This can be your name or an alias',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Name or alias',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Required';
              if (val.trim().length < 2) return 'At least 2 characters';
              if (val.trim().length > 20) return 'Max 20 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.textMuted),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              final age = int.tryParse(val);
              if (age == null || age < 18) return 'Must be 18+';
              if (age > 99) return 'Invalid age';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        ...Gender.values.map((g) => _buildOptionTile(
              title: g.displayName,
              isSelected: _gender == g,
              onTap: () => setState(() => _gender = g),
            )),
        const SizedBox(height: 32),
        Text(
          'Relationship status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        ...RelationshipType.values.map((r) => _buildOptionTile(
              title: r.displayName,
              isSelected: _relationshipType == r,
              onTap: () => setState(() => _relationshipType = r),
            )),
      ],
    );
  }

  Widget _buildPreferenceStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show me...',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Who would you like to connect with?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        ...Preference.values.map((p) => _buildOptionTile(
              title: p.displayName,
              isSelected: _preference == p,
              onTap: () => setState(() => _preference = p),
            )),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.15)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
