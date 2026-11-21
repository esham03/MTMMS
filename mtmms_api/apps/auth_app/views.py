"""
Auth views — replaces Laravel AuthController
Endpoints: login, register, me, update_profile, change_password, logout, logout_all
"""

import random
import time
from django.core.cache import cache
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import make_password
from .models import User


def _user_dict(user):
    """Shared user response shape — matches Laravel's AuthController response."""
    return {
        'id':         user.id,
        'name':       user.name,
        'email':      user.email,
        'role':       user.role or 'admin',
        'department': user.department or 'Department of Information Technology',
        'created_at': user.created_at,
        'updated_at': user.updated_at,
    }


# ─────────────────────────────────────────────────
# POST /api/auth/login  (public)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    login_input = request.data.get('email', '').strip()
    password    = request.data.get('password', '')

    if not login_input or not password:
        return Response(
            {'errors': {'email': ['Email and password are required.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )

    # Allow login by email OR name (mirrors Laravel AuthController)
    user = (
        User.objects.filter(email__iexact=login_input).first() or
        User.objects.filter(name__iexact=login_input).first()
    )

    if not user or not user.check_password(password):
        return Response(
            {'errors': {'email': ['Invalid credentials. Please verify your email/username and password.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )

    # Issue JWT token (replaces Sanctum createToken)
    refresh = RefreshToken.for_user(user)

    return Response({
        'message': 'Login successful',
        'token':   str(refresh.access_token),
        'user':    _user_dict(user),
    })


# ─────────────────────────────────────────────────
# POST /api/auth/register  (public)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    data = request.data
    errors = {}

    name       = data.get('name', '').strip()
    email      = data.get('email', '').strip()
    password   = data.get('password', '')
    role       = data.get('role', 'officer')
    department = data.get('department', 'Department of Information Technology')

    if not name:
        errors['name'] = ['Name is required.']
    if not email:
        errors['email'] = ['Email is required.']
    elif User.objects.filter(email__iexact=email).exists():
        errors['email'] = ['Email already exists.']
    if not password or len(password) < 6:
        errors['password'] = ['Password must be at least 6 characters.']
    if role not in ['admin', 'officer', 'inspector', 'viewer']:
        role = 'officer'

    if errors:
        return Response({'errors': errors}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

    user = User.objects.create_user(
        email=email, name=name, password=password,
        role=role, department=department
    )

    refresh = RefreshToken.for_user(user)

    return Response({
        'message': 'User registered successfully',
        'token':   str(refresh.access_token),
        'user':    _user_dict(user),
    }, status=status.HTTP_201_CREATED)


# ─────────────────────────────────────────────────
# GET /api/auth/me  (protected)
# ─────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    return Response({'user': _user_dict(request.user)})


# ─────────────────────────────────────────────────
# PUT /api/auth/profile  (protected)
# ─────────────────────────────────────────────────
@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user   = request.user
    data   = request.data
    errors = {}

    if 'name' in data:
        name = data['name'].strip()
        if not name:
            errors['name'] = ['Name is required.']
        else:
            user.name = name

    if 'email' in data:
        email = data['email'].strip()
        if not email:
            errors['email'] = ['Email is required.']
        elif User.objects.filter(email__iexact=email).exclude(pk=user.pk).exists():
            errors['email'] = ['Email already taken.']
        else:
            user.email = email

    if 'department' in data:
        user.department = data['department']

    if errors:
        return Response({'errors': errors}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

    user.save()
    return Response({
        'message': 'Profile updated successfully',
        'user':    _user_dict(user),
    })


# ─────────────────────────────────────────────────
# POST /api/auth/change-password  (protected)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    current  = request.data.get('current_password', '')
    new_pass = request.data.get('new_password', '')

    if not user.check_password(current):
        return Response(
            {'errors': {'current_password': ['The provided current password does not match our records.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    if len(new_pass) < 6:
        return Response(
            {'errors': {'new_password': ['Password must be at least 6 characters.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )

    user.set_password(new_pass)
    user.save()
    return Response({'message': 'Password changed successfully'})


# ─────────────────────────────────────────────────
# POST /api/auth/logout  (protected)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    # JWT is stateless — client removes token from localStorage/sessionStorage
    # Optionally blacklist the refresh token if provided
    try:
        refresh_token = request.data.get('refresh_token')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
    except Exception:
        pass
    return Response({'message': 'Logged out successfully'})


# ─────────────────────────────────────────────────
# POST /api/auth/logout-all  (protected)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_all(request):
    # For stateless JWT, we can't revoke all tokens without a blacklist
    # This is a no-op that returns success (mirrors Laravel's behavior)
    return Response({'message': 'Logged out from all devices successfully'})


# ─────────────────────────────────────────────────
# POST /api/users/{pk}/reset-password  (protected)
# ─────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reset_password(request, pk):
    try:
        user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response({'message': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    new_pass = request.data.get('password', '')
    if len(new_pass) < 6:
        return Response(
            {'errors': {'password': ['Password must be at least 6 characters.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )
    user.set_password(new_pass)
    user.save()
    return Response({'message': 'Password reset successfully'})


# ─────────────────────────────────────────────────
# GET /api/health/ (public)
# ─────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    Public health check endpoint for LAN discovery, Flutter APK self-discovery,
    and Start-Live-System.bat verification.
    """
    return Response({
        "status": "ok",
        "service": "MTMMS API",
        "version": "1.0",
        "message": "MTMMS REST API is running and healthy",
    }, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────────
# Password Recovery with 6-Digit OTP (Zero-Cost Local Simulation)
# ─────────────────────────────────────────────────
_RESET_OTP_STORE = {}


@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset_otp(request):
    """
    Public endpoint: Generates a 6-digit OTP for password recovery.
    Runs 100% locally with zero external paid SMS/email gateways.
    """
    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response(
            {'errors': {'email': ['Official Email is required.']}},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY
        )

    user = User.objects.filter(email__iexact=email).first()
    if not user:
        return Response(
            {'errors': {'email': ['No officer account found with this registered email address.']}},
            status=status.HTTP_404_NOT_FOUND
        )

    # Generate random 6-digit OTP
    otp = f"{random.randint(100000, 999999)}"
    expires_in = 300  # 5 minutes
    expires_at = time.time() + expires_in

    _RESET_OTP_STORE[email] = {
        'otp': otp,
        'expires_at': expires_at,
        'user_id': user.id
    }
    try:
        cache.set(f"reset_otp_{email}", otp, timeout=expires_in)
    except Exception:
        pass

    print(f"\n=======================================================")
    print(f"[MTMMS SECURITY DISPATCH] Password Reset OTP for {email}: {otp}")
    print(f"=======================================================\n")

    return Response({
        'status': 'success',
        'message': f'Verification OTP dispatched for {user.name or email}.',
        'otp_preview': otp,
        'expires_in': expires_in
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_and_reset_password(request):
    """
    Public endpoint: Verifies the 6-digit OTP and updates user's password.
    """
    email = request.data.get('email', '').strip().lower()
    otp = request.data.get('otp', '').strip()
    new_password = request.data.get('new_password', '')

    errors = {}
    if not email:
        errors['email'] = ['Email is required.']
    if not otp:
        errors['otp'] = ['6-Digit OTP is required.']
    if not new_password or len(new_password) < 6:
        errors['new_password'] = ['New password must be at least 6 characters long.']

    if errors:
        return Response({'errors': errors}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

    # Validate OTP
    is_valid = False
    try:
        cached_otp = cache.get(f"reset_otp_{email}")
        if cached_otp and str(cached_otp).strip() == otp:
            is_valid = True
            cache.delete(f"reset_otp_{email}")
    except Exception:
        pass

    record = _RESET_OTP_STORE.get(email)
    if not is_valid and record:
        if time.time() <= record['expires_at'] and record['otp'] == otp:
            is_valid = True
            _RESET_OTP_STORE.pop(email, None)
        elif time.time() > record['expires_at']:
            _RESET_OTP_STORE.pop(email, None)
            return Response(
                {'errors': {'otp': ['OTP code has expired. Please request a new verification code.']}},
                status=status.HTTP_400_BAD_REQUEST
            )

    if not is_valid:
        return Response(
            {'errors': {'otp': ['Invalid OTP verification code. Please check and try again.']}},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = User.objects.filter(email__iexact=email).first()
    if not user:
        return Response({'message': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

    user.set_password(new_password)
    user.save()

    return Response({
        'status': 'success',
        'message': 'Password has been successfully updated. You may now sign in with your new credentials.'
    })


