import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Login / Sign-up screen for field officers.
/// Supports login via email OR badge number + password.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _badgeController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useBadgeLogin = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    if (!mounted) return;
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _useBadgeLogin = false;
    });
    _animController.forward(from: 0);
  }

  void _toggleLoginMethod() {
    if (!mounted) return;
    setState(() {
      _useBadgeLogin = !_useBadgeLogin;
      _identifierController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        if (_useBadgeLogin) {
          await AuthService.instance.signInWithBadge(
            badgeNumber: _identifierController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await AuthService.instance.signIn(
            email: _identifierController.text.trim(),
            password: _passwordController.text,
          );
        }
      } else {
        await AuthService.instance.signUp(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          badgeNumber: _badgeController.text.trim().isEmpty
              ? null
              : _badgeController.text.trim(),
        );
      }
      if (mounted) {
        context.go(AppRoutes.homeScreen);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _localizeError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizeError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid credentials')) {
      return 'Kimlik bilgileri hatalı. Lütfen tekrar deneyin.';
    }
    if (m.contains('email already registered') ||
        m.contains('already been registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }
    if (m.contains('password should be at least')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    if (m.contains('user not found')) {
      return 'Kullanıcı bulunamadı.';
    }
    if (m.contains('network') ||
        m.contains('connection') ||
        m.contains('socket')) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }
    if (m.contains('sicil numarasına kayıtlı') ||
        m.contains('sicil numarasına bağlı')) {
      return message;
    }
    return message;
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _useBadgeLogin
          ? 'Sicil numarası boş bırakılamaz'
          : 'E-posta adresi boş bırakılamaz';
    }
    if (!_useBadgeLogin) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Geçerli bir e-posta adresi girin';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş bırakılamaz';
    }
    if (!_isLogin && value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Resize when keyboard appears to prevent content overlap
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 2.h),
                  // ── Logo / Header ──────────────────────────────────
                  Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 9.w,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Nirengi',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _isLogin
                        ? 'Hesabınıza giriş yapın'
                        : 'Yeni hesap oluşturun',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // ── Form Card ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(38),
                      ),
                    ),
                    padding: EdgeInsets.all(5.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Login method toggle (login only) ───────
                          if (_isLogin) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withAlpha(102),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _useBadgeLogin
                                          ? _toggleLoginMethod
                                          : null,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_useBadgeLogin
                                              ? AppTheme.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        child: Text(
                                          'E-posta',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: !_useBadgeLogin
                                                ? Colors.white
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: !_useBadgeLogin
                                          ? _toggleLoginMethod
                                          : null,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _useBadgeLogin
                                              ? AppTheme.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        child: Text(
                                          'Sicil No',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: _useBadgeLogin
                                                ? Colors.white
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 2.h),
                          ],

                          // ── Name field (signup only) ───────────────
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14.sp,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Ad Soyad (isteğe bağlı)',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(height: 1.5.h),
                          ],

                          // ── Identifier field ───────────────────────
                          TextFormField(
                            controller: _identifierController,
                            textInputAction: TextInputAction.next,
                            keyboardType: _useBadgeLogin
                                ? TextInputType.number
                                : TextInputType.emailAddress,
                            autocorrect: false,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              labelText: _useBadgeLogin
                                  ? 'Sicil Numarası'
                                  : 'E-posta Adresi',
                              prefixIcon: Icon(
                                _useBadgeLogin
                                    ? Icons.badge_outlined
                                    : Icons.email_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            validator: _validateIdentifier,
                          ),
                          SizedBox(height: 1.5.h),

                          // ── Password field ─────────────────────────
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),

                          // ── Badge field (signup only) ──────────────
                          if (!_isLogin) ...[
                            SizedBox(height: 1.5.h),
                            TextFormField(
                              controller: _badgeController,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.number,
                              onFieldSubmitted: (_) => _submit(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14.sp,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Sicil Numarası (isteğe bağlı)',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],

                          // ── Error message ──────────────────────────
                          if (_errorMessage != null) ...[
                            SizedBox(height: 1.5.h),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.error.withAlpha(77),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 2.h),

                          // ── Submit button ──────────────────────────
                          SizedBox(
                            height: 6.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTheme.primary
                                    .withAlpha(102),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // ── Toggle login/signup ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'Hesabınız yok mu? '
                            : 'Zaten hesabınız var mı? ',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _toggleMode,
                        child: Text(
                          _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
