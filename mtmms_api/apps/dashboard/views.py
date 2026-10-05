"""
Dashboard view — replaces Laravel DashboardController
Returns identical JSON structure with all 9 stats + 3 distributions
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum
from django.utils import timezone
from collections import defaultdict

from apps.towers.models       import Tower
from apps.operators.models    import Operator
from apps.rent_payments.models import RentPayment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard(request):
    # ── Core stats ──────────────────────────────────────────
    total_towers      = Tower.objects.count()
    government_towers = Tower.objects.filter(land_type='government').count()
    private_towers    = Tower.objects.filter(land_type='private').count()
    active_towers     = Tower.objects.filter(status='active').count()
    inactive_towers   = Tower.objects.filter(status='inactive').count()
    total_operators   = Operator.objects.count()
    rent_due          = Tower.objects.filter(rent_due_date__lte=timezone.now().date()).count()
    rent_collected    = RentPayment.objects.filter(payment_status='paid').aggregate(
        t=Sum('amount')
    )['t'] or 0.0
    pending_payments  = RentPayment.objects.filter(
        payment_status__in=['pending', 'overdue']
    ).count()

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
        'total_towers':      total_towers,
        'government_towers': government_towers,
        'private_towers':    private_towers,
        'active_towers':     active_towers,
        'inactive_towers':   inactive_towers,
        'total_operators':   total_operators,
        'rent_due':          rent_due,
        'rent_collected':    float(rent_collected),
        'pending_payments':  pending_payments,
        'district_wise':     district_wise,
        'taluka_wise':       taluka_wise,
        'operator_wise':     operator_wise,
    }})
