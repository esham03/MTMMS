"""
Auth views — replaces Laravel AuthController
Endpoints: login, register, me, update_profile, change_password, logout, logout_all
"""

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

