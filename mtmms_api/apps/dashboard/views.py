"""
Dashboard view — replaces Laravel DashboardController
Returns JSON structure with all core stats + distributions + renewal & escalation telemetry
"""

import datetime
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Q
from django.utils import timezone
from collections import defaultdict

from apps.towers.models        import Tower, TowerRentRenewal
from apps.operators.models     import Operator
from apps.rent_payments.models import RentPayment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard(request):
    today = timezone.now().date()
    target_date = today + datetime.timedelta(days=90)

    # ── Core stats ──────────────────────────────────────────
    total_towers      = Tower.objects.count()
    government_towers = Tower.objects.filter(land_type='government').count()
    private_towers    = Tower.objects.filter(land_type='private').count()
    active_towers     = Tower.objects.filter(status='active').count()
    inactive_towers   = Tower.objects.filter(status='inactive').count()
    total_operators   = Operator.objects.count()
    rent_due          = Tower.objects.filter(rent_due_date__lte=today).count()
    rent_collected    = RentPayment.objects.filter(payment_status='paid').aggregate(
        t=Sum('amount')
    )['t'] or 0.0
    pending_payments  = RentPayment.objects.filter(
        payment_status__in=['pending', 'overdue']
    ).count()

    total_annual_demand = Tower.objects.aggregate(t=Sum('yearly_rent'))['t'] or 0.0

    # ── Upcoming Renewals Telemetry ──────────────────────────
    upcoming_qs = Tower.objects.select_related('area__taluka', 'owner').filter(
        Q(agreement_end_date__lte=target_date) | Q(next_renewal_date__lte=target_date)
    ).order_by('next_renewal_date', 'agreement_end_date')

    upcoming_renewals_count = upcoming_qs.count()
    upcoming_renewals = [
        {
            'tower_id':              t.id,
            'tower_unique_id':       t.tower_unique_id,
            'owner':                 t.owner.name if t.owner else ('Government of Goa' if t.land_type == 'government' else 'Private Landholder'),
            'location':              f"{t.area.name if t.area else 'N/A'}, {t.area.taluka.name if (t.area and t.area.taluka) else 'Goa'}",
            'yearly_rent':           float(t.yearly_rent or 0),
            'escalation_enabled':    t.escalation_enabled,
            'escalation_percentage': float(t.escalation_percentage or 0),
            'next_renewal_date':     str(t.next_renewal_date or t.agreement_end_date) if (t.next_renewal_date or t.agreement_end_date) else None,
            'is_overdue':            bool((t.next_renewal_date or t.agreement_end_date) and (t.next_renewal_date or t.agreement_end_date) <= today),
        }
        for t in upcoming_qs[:10]
    ]

    # ── Recent Escalations Telemetry ─────────────────────────
    recent_escalations_qs = TowerRentRenewal.objects.select_related('tower').order_by('-effective_date', '-created_at')
    recent_escalations_count = recent_escalations_qs.count()
    recent_escalations = [
        {
            'id':                    r.id,
            'renewal_reference':     r.renewal_reference,
            'tower_id':              r.tower_id,
            'tower_unique_id':       r.tower.tower_unique_id,
            'previous_yearly_rent':  float(r.previous_yearly_rent),
            'escalation_percentage': float(r.escalation_percentage),
            'increase_amount':       float(r.increase_amount),
            'new_yearly_rent':       float(r.new_yearly_rent),
            'effective_date':        str(r.effective_date),
            'is_manual_override':    r.is_manual_override,
            'approved_by_name':      r.approved_by_name or 'Administrator',
        }
        for r in recent_escalations_qs[:10]
    ]

    # ── District-wise distribution ───────────────────────────
    district_counts = defaultdict(int)
    for tower in Tower.objects.select_related('area__taluka__constituency__district'):
        try:
            name = tower.area.taluka.constituency.district.name
        except AttributeError:
            name = 'Unknown'
        district_counts[name] += 1
    district_wise = [{'district': k, 'tower_count': v} for k, v in district_counts.items()]

    # ── Taluka-wise distribution ─────────────────────────────
    taluka_counts = defaultdict(int)
    for tower in Tower.objects.select_related('area__taluka'):
        try:
            name = tower.area.taluka.name
        except AttributeError:
            name = 'Unknown'
        taluka_counts[name] += 1
    taluka_wise = [{'taluka': k, 'tower_count': v} for k, v in taluka_counts.items()]

    # ── Operator-wise distribution ───────────────────────────
    operator_wise = [
        {
            'operator_id': op.id,
            'operator':    op.name,
            'short_name':  op.short_name,
            'tower_count': op.towers.count(),
        }
        for op in Operator.objects.prefetch_related('towers')
    ]

    return Response({'data': {
        'total_towers':             total_towers,
        'government_towers':        government_towers,
        'private_towers':           private_towers,
        'active_towers':            active_towers,
        'inactive_towers':          inactive_towers,
        'total_operators':          total_operators,
        'rent_due':                 rent_due,
        'rent_collected':           float(rent_collected),
        'total_annual_demand':      float(total_annual_demand),
        'pending_payments':         pending_payments,
        'upcoming_renewals_count':  upcoming_renewals_count,
        'upcoming_renewals':        upcoming_renewals,
        'recent_escalations_count': recent_escalations_count,
        'recent_escalations':       recent_escalations,
        'district_wise':            district_wise,
        'taluka_wise':              taluka_wise,
        'operator_wise':            operator_wise,
    }})
