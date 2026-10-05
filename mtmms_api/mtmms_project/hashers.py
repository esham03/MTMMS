"""
LaravelBcryptHasher
────────────────────
Laravel stores bcrypt passwords with a '$2y$' prefix (PHP convention).
Python's bcrypt library uses '$2b$' — the algorithms are identical.
This hasher swaps '$2y$' → '$2b$' before verifying so existing Laravel
users can log in without a password reset.

New passwords created by Django (e.g. via register or change-password)
will use PBKDF2 (the first hasher in PASSWORD_HASHERS) which is stored
with a 'pbkdf2_sha256$' prefix, not '$2y$', so they won't be touched here.
"""

import bcrypt
from django.contrib.auth.hashers import BasePasswordHasher
from django.utils.crypto import constant_time_compare


class LaravelBcryptHasher(BasePasswordHasher):
    """
    Verifies bcrypt hashes created by Laravel/PHP (prefix: $2y$).
    Encoding: encode() is intentionally not used for new passwords
    (PBKDF2 is preferred); it's here only to satisfy the interface.
    """

    algorithm = 'laravel_bcrypt'

    def salt(self):
        return ''  # bcrypt generates its own salt internally

    def encode(self, password, salt):
        """Encode a new password (used only if this hasher is first in the list)."""
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        return hashed.decode('utf-8')  # e.g. $2b$12$...

    def verify(self, password, encoded):
        """
        Verify a password against a stored hash.
        Handles both '$2y$' (Laravel/PHP) and '$2b$' (Python bcrypt) prefixes.
        """
        # Swap $2y$ → $2b$ so Python's bcrypt library accepts it
        if encoded.startswith('$2y$'):
            encoded = '$2b$' + encoded[4:]
        try:
            return bcrypt.checkpw(
                password.encode('utf-8'),
                encoded.encode('utf-8'),
            )
        except Exception:
            return False

    def identify(self, encoded):
        """Return True if this hasher should handle the given encoded value."""
        return encoded.startswith('$2y$') or encoded.startswith('$2b$')

    def safe_summary(self, encoded):
        return {
            'algorithm': 'bcrypt (Laravel compatible)',
            'hash': encoded[:20] + '...',
        }

    def must_update(self, encoded):
        """Never force-upgrade Laravel bcrypt hashes."""
        return False
