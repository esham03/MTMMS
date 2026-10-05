"""
User model — maps to the existing Laravel users table (no extra columns).
Authentication is handled via JWT (djangorestframework-simplejwt).

Laravel users table columns:
    id, name, email, role, department,
    email_verified_at, password, remember_token,
    created_at, updated_at
"""

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, name, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, name, password=None, **extra_fields):
        extra_fields.setdefault('role', 'admin')
        return self.create_user(email, name, password, **extra_fields)


class User(AbstractBaseUser):
    """
    Mirrors the Laravel users table exactly.
    AbstractBaseUser only adds: id (inherited), password, last_login.
    We suppress last_login below since it's not in the Laravel schema.
    """

    ROLE_CHOICES = [
        ('admin',     'Admin'),
        ('officer',   'Officer'),
        ('inspector', 'Inspector'),
        ('viewer',    'Viewer'),
    ]

    # ── Columns present in the Laravel users table ────────────────
    name               = models.CharField(max_length=255)
    email              = models.EmailField(unique=True)
    role               = models.CharField(max_length=255, choices=ROLE_CHOICES, default='admin')
    department         = models.CharField(max_length=255, default='Department of Information Technology')
    email_verified_at  = models.DateTimeField(null=True, blank=True)
    remember_token     = models.CharField(max_length=100, null=True, blank=True)
    created_at         = models.DateTimeField(auto_now_add=True)
    updated_at         = models.DateTimeField(auto_now=True)

    # ── Suppress Django-added fields absent from the Laravel table ─
    last_login  = None  # AbstractBaseUser adds this; not in our table

    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['name']

    objects = UserManager()

    class Meta:
        db_table = 'users'  # Use existing Laravel users table

    def __str__(self):
        return f"{self.name} <{self.email}>"

    # ── Virtual fields — roles-based, no DB column needed ─────────
    @property
    def is_active(self):
        """All users in the table are considered active."""
        return True

    @property
    def is_staff(self):
        return self.role == 'admin'

    @property
    def is_superuser(self):
        return self.role == 'admin'

    # ── Permission stubs (no PermissionsMixin — avoids extra tables) ─
    def has_perm(self, perm, obj=None):
        return self.role == 'admin'

    def has_module_perms(self, app_label):
        return self.role == 'admin'
