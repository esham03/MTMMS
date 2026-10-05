"""
MTMMS URL Configuration
Replaces Laravel's routes/api.php — identical endpoint paths
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Import all ViewSets
from apps.towers.views       import TowerViewSet
from apps.owners.views       import OwnerViewSet
from apps.operators.views    import OperatorViewSet
from apps.rent_payments.views import RentPaymentViewSet
from apps.users.views        import UserViewSet
from apps.locations.views    import (
    DistrictViewSet, TalukaViewSet,
    ConstituencyViewSet, AreaViewSet,
)
from apps.dashboard.views    import dashboard
from apps.reports.views      import reports
import apps.auth_app.views   as auth_views

# ─────────────────────────────────────────
# Router — replaces Route::apiResource()
# ─────────────────────────────────────────
router = DefaultRouter(trailing_slash=False)
router.register(r'towers',         TowerViewSet,         basename='tower')
router.register(r'owners',         OwnerViewSet,         basename='owner')
router.register(r'operators',      OperatorViewSet,      basename='operator')
router.register(r'rent-payments',  RentPaymentViewSet,   basename='rent-payment')
router.register(r'users',          UserViewSet,          basename='user')
router.register(r'districts',      DistrictViewSet,      basename='district')
router.register(r'talukas',        TalukaViewSet,        basename='taluka')
router.register(r'constituencies', ConstituencyViewSet,  basename='constituency')
router.register(r'areas',          AreaViewSet,          basename='area')

urlpatterns = [
    # ── Health check routes (public for LAN discovery & monitoring) ──
    path('api/health/',              auth_views.health_check),
    path('api/health',               auth_views.health_check),

    # ── Auth routes (public) ──────────────────────────────────
    path('api/auth/login',           auth_views.login),
    path('api/auth/register',        auth_views.register),

    # ── Auth routes (protected) ───────────────────────────────
    path('api/user',                  auth_views.me),
    path('api/auth/me',              auth_views.me),
    path('api/auth/profile',         auth_views.update_profile),
    path('api/auth/change-password', auth_views.change_password),
    path('api/auth/logout',          auth_views.logout),
    path('api/auth/logout-all',      auth_views.logout_all),

    # ── User management ───────────────────────────────────────
    path('api/users/<int:pk>/reset-password', auth_views.reset_password),

    # ── Dashboard & Reports ───────────────────────────────────
    path('api/dashboard', dashboard),
    path('api/reports',   reports),

    # ── All resource routes (towers, owners, operators, etc.) ─
    path('api/', include(router.urls)),
]
