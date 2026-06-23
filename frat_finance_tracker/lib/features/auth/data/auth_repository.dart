import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';
import 'package:frat_finance_tracker/shared/services/fcm_service.dart';
import 'package:frat_finance_tracker/shared/utils/app_logger.dart';
import 'package:frat_finance_tracker/shared/utils/password_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _auth = SupabaseService.auth;
  final _client = SupabaseService.client;

  // Default password for all new users
  static const String _defaultPassword = 'TempPassword123@';

  // Get current user profile from database
  Future<AppUser?> getCurrentUserProfile() async {
    final session = _auth.currentSession;
    if (session == null) {
      AppLogger.debug('No active session found');
      return null;
    }

    try {
      AppLogger.database('Fetching user profile');
      final response = await _client
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      AppLogger.database('User profile fetched successfully');
      return AppUser.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to fetch user profile', error: e);
      return null;
    }
  }

  // Sign in with email and password
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed');
      }

      // Get user profile from database
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Initialize FCM and save token (non-blocking)
      FCMService.initialize().catchError((e) {
        print('FCM initialization failed: $e');
      });

      return userProfile;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with invitation code
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String invitationCode,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Verify invitation code
      final invitation = await _client
          .from('invitations')
          .select()
          .eq('invitation_code', invitationCode)
          .eq('email', email)
          .eq('status', 'pending')
          .single();

      if (invitation == null) {
        throw Exception('Invalid invitation code');
      }

      // Check if invitation is expired
      final expiresAt = DateTime.parse(invitation['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        throw Exception('Invitation code has expired');
      }

      // Create auth user
      final authResponse = await _auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Sign up failed');
      }

      // Create user profile
      await _client.from('users').insert({
        'id': authResponse.user!.id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': 'brother',
        'profile_completed': true,
        'brother_status': 'active',
      });

      // Mark invitation as accepted
      await _client.from('invitations').update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', invitation['id']);

      // Get the created user profile
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception('Failed to create user profile');
      }

      return userProfile;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Delete FCM token before signing out
    await FCMService.deleteFCMToken();
    await _auth.signOut();
  }

  // Auth state stream
  Stream<AppUser?> authStateChanges() {
    return _auth.onAuthStateChange.asyncMap((data) async {
      if (data.session == null) return null;
      try {
        return await getCurrentUserProfile();
      } catch (e) {
        // If session is invalid (e.g., stale refresh token), sign out cleanly
        AppLogger.error('Failed to restore session, signing out', error: e);
        try {
          await _auth.signOut();
        } catch (_) {}
        return null;
      }
    });
  }

  // VP of Finance: Create a new user
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role, // 'brother' or 'vp_finance'
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can create users'
        };
      }

      // Validate inputs
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'error': 'Invalid email address'};
      }

      if (fullName.trim().isEmpty) {
        return {'success': false, 'error': 'Full name is required'};
      }

      if (role != 'brother' && role != 'vp_finance') {
        return {'success': false, 'error': 'Invalid role'};
      }

      // IMPORTANT: Store current session info BEFORE creating new user
      // We need to preserve the VP's session
      final currentSession = _auth.currentSession;
      if (currentSession == null) {
        AppLogger.error('No current session when creating user');
        return {'success': false, 'error': 'Not authenticated. Please log in again.'};
      }

      AppLogger.info('Current session exists, storing for later restoration');

      // Store refresh token to restore session later
      final vpRefreshToken = currentSession.refreshToken;
      if (vpRefreshToken == null || vpRefreshToken.isEmpty) {
        AppLogger.error('No refresh token available');
        return {'success': false, 'error': 'Invalid session. Please log in again.'};
      }

      AppLogger.info('Refresh token stored successfully');

      // Create user in Supabase Auth with default password
      AppLogger.info('Creating auth user with email: $email');
      final authResponse = await _auth.signUp(
        email: email,
        password: _defaultPassword,
      );

      if (authResponse.user == null) {
        AppLogger.error('signUp returned null user');
        return {'success': false, 'error': 'Failed to create user account'};
      }

      final newUserId = authResponse.user!.id;
      AppLogger.info('Auth user created with ID: $newUserId');

      // IMPORTANT: Immediately sign out the newly created user
      // (signUp auto-logs them in, which logged out the VP)
      AppLogger.info('Signing out newly created user');
      await _auth.signOut();

      // Restore the VP's session using refresh token
      AppLogger.info('Attempting to restore VP session with refresh token');
      try {
        final refreshResponse = await _auth.refreshSession(vpRefreshToken);
        if (refreshResponse.session == null) {
          throw Exception('Failed to refresh session - no session returned');
        }
        AppLogger.info('VP session restored successfully');
      } catch (e) {
        AppLogger.error('Failed to restore VP session', error: e);
        // Session restoration failed, but auth user was created
        return {
          'success': false,
          'error': 'User auth account created, but you were logged out. Please log back in.',
          'needsRelogin': true,
        };
      }

      // NOW create user profile while logged in as VP (who has permission)
      AppLogger.info('Creating user profile in database');
      try {
        await _client.from('users').insert({
          'id': newUserId,
          'email': email,
          'full_name': fullName,
          'role': role,
          'profile_completed': true,
          'must_change_password': true,
          'brother_status': 'active',
        });
        AppLogger.info('User profile created successfully');
      } catch (e) {
        AppLogger.error('Failed to create user profile in database', error: e);
        return {
          'success': false,
          'error': 'Failed to create user profile: $e',
        };
      }

      // User created successfully
      AppLogger.info('User created successfully');
      return {
        'success': true,
        'message': 'User created successfully. Default password: $_defaultPassword',
      };
    } on AuthException catch (e) {
      AppLogger.auth('User creation failed: Authentication error');
      return {'success': false, 'error': e.message};
    } catch (e) {
      AppLogger.error('Failed to create user', error: e);
      return {'success': false, 'error': 'Failed to create user. Please try again.'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
  }) async {
    try {
      // SECURITY: Validate password strength
      final passwordError = PasswordValidator.validate(newPassword);
      if (passwordError != null) {
        return {
          'success': false,
          'error': passwordError
        };
      }

      // Update must_change_password flag BEFORE changing password,
      // because updateUser triggers an auth state event that re-fetches
      // the profile. If the flag is still true, the router redirects
      // back to the change password screen.
      final session = _auth.currentSession;
      if (session != null) {
        await _client
            .from('users')
            .update({'must_change_password': false})
            .eq('id', session.user.id);
      }

      await _auth.updateUser(UserAttributes(password: newPassword));

      return {'success': true};
    } on AuthException catch (e) {
      AppLogger.auth('Password change failed: Authentication error');
      return {'success': false, 'error': e.message};
    } catch (e) {
      AppLogger.error('Failed to change password', error: e);
      return {'success': false, 'error': 'Failed to change password. Please try again.'};
    }
  }

  // Change email
  Future<Map<String, dynamic>> changeEmail({
    required String newEmail,
  }) async {
    try {
      // Validate email format
      if (newEmail.isEmpty || !newEmail.contains('@')) {
        return {
          'success': false,
          'error': 'Please enter a valid email address'
        };
      }

      final session = _auth.currentSession;
      if (session == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      // Check if email is already in use
      final existingUser = await _client
          .from('users')
          .select()
          .eq('email', newEmail)
          .maybeSingle();

      if (existingUser != null) {
        return {
          'success': false,
          'error': 'This email is already in use'
        };
      }

      // Update email in Supabase Auth
      await _auth.updateUser(UserAttributes(email: newEmail));

      // Update email in users table
      await _client
          .from('users')
          .update({'email': newEmail})
          .eq('id', session.user.id);

      return {'success': true};
    } on AuthException catch (e) {
      AppLogger.auth('Email change failed: Authentication error');
      return {'success': false, 'error': e.message};
    } catch (e) {
      AppLogger.error('Failed to change email', error: e);
      return {'success': false, 'error': 'Failed to change email. Please try again.'};
    }
  }

  // VP of Finance: Update brother status
  Future<Map<String, dynamic>> updateBrotherStatus({
    required String brotherId,
    required String status,
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can update brother status'
        };
      }

      // Validate status
      if (!['active', 'inactive'].contains(status)) {
        return {'success': false, 'error': 'Invalid status'};
      }

      // Prevent VP from changing their own status
      if (brotherId == currentUser.id) {
        return {
          'success': false,
          'error': 'Cannot change your own status'
        };
      }

      await _client
          .from('users')
          .update({'brother_status': status})
          .eq('id', brotherId);

      return {'success': true};
    } catch (e) {
      AppLogger.error('Failed to update brother status', error: e);
      return {'success': false, 'error': 'Failed to update status. Please try again.'};
    }
  }

  // VP of Finance: Transfer VP role to another brother
  Future<Map<String, dynamic>> transferVPRole({
    required String currentVPId,
    required String newVPId,
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can transfer the role'
        };
      }

      // Verify the current user is the one initiating the transfer
      if (currentUser.id != currentVPId) {
        return {
          'success': false,
          'error': 'Unauthorized: You can only transfer your own VP role'
        };
      }

      // Prevent transferring to self
      if (currentVPId == newVPId) {
        return {
          'success': false,
          'error': 'Cannot transfer VP role to yourself'
        };
      }

      // Verify the target user exists and is a brother
      final targetUser = await _client
          .from('users')
          .select()
          .eq('id', newVPId)
          .maybeSingle();

      if (targetUser == null) {
        return {
          'success': false,
          'error': 'Target user not found'
        };
      }

      // Update current VP to brother
      await _client
          .from('users')
          .update({'role': 'brother'})
          .eq('id', currentVPId);

      // Update new VP to vp_finance
      await _client
          .from('users')
          .update({'role': 'vp_finance'})
          .eq('id', newVPId);

      return {'success': true};
    } catch (e) {
      AppLogger.error('Failed to transfer VP role', error: e);
      return {'success': false, 'error': 'Failed to transfer VP role. Please try again.'};
    }
  }

  // Get all users (for VP to view brothers)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('full_name', ascending: true);

      return (response as List)
          .map((userData) => AppUser.fromJson(userData))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get all users', error: e);
      return [];
    }
  }

  // VP of Finance: Permanently delete a brother and all associated data
  Future<Map<String, dynamic>> deleteBrother({
    required String brotherId,
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can delete brothers'
        };
      }

      // Prevent self-deletion
      if (brotherId == currentUser.id) {
        return {'success': false, 'error': 'Cannot delete your own account'};
      }

      // Prevent deleting another VP of Finance
      final targetUser = await _client
          .from('users')
          .select('role')
          .eq('id', brotherId)
          .maybeSingle();

      if (targetUser == null) {
        return {'success': false, 'error': 'Brother not found'};
      }
      if (targetUser['role'] == 'vp_finance') {
        return {'success': false, 'error': 'Cannot delete a VP of Finance'};
      }

      // 1. Delete scheduled_payments → payment_plans (for all brother_dues of this brother)
      // Query payment_plan IDs linked to this brother's dues
      final brotherDuesResponse = await _client
          .from('brother_dues')
          .select('id')
          .eq('brother_id', brotherId);

      final duesIds = (brotherDuesResponse as List)
          .map((d) => d['id'] as String)
          .toList();

      if (duesIds.isNotEmpty) {
        final paymentPlansResponse = await _client
            .from('payment_plans')
            .select('id')
            .inFilter('brother_dues_id', duesIds);

        final planIds = (paymentPlansResponse as List)
            .map((p) => p['id'] as String)
            .toList();

        if (planIds.isNotEmpty) {
          await _client
              .from('scheduled_payments')
              .delete()
              .inFilter('payment_plan_id', planIds);

          await _client
              .from('payment_plans')
              .delete()
              .inFilter('id', planIds);
        }

        // Delete brother_dues (payments CASCADE delete via FK)
        await _client
            .from('brother_dues')
            .delete()
            .inFilter('id', duesIds);
      }

      // 2. Delete FCM tokens
      await _client.from('fcm_tokens').delete().eq('user_id', brotherId);

      // 3. Delete in-app notifications
      await _client.from('notifications').delete().eq('user_id', brotherId);

      // 4. Delete the user record
      await _client.from('users').delete().eq('id', brotherId);

      return {'success': true};
    } on PostgrestException catch (e) {
      AppLogger.error('Database error deleting brother', error: e);
      return {'success': false, 'error': 'Database error: ${e.message}'};
    } catch (e) {
      AppLogger.error('Failed to delete brother', error: e);
      return {
        'success': false,
        'error': 'Failed to delete brother. Please try again.'
      };
    }
  }
}
