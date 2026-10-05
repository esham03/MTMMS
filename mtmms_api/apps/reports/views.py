"""
Reports view — replaces Laravel ReportsController
7 report types matching original exactly
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum
from django.utils import timezone
from collections import defaultdict

from apps.towers.models        import Tower
from apps.operators.models     import Operator
from apps.rent_payments.models import RentPayment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def reports(request):
    report_type = request.query_params.get('type', 'all')
    data        = {}

    # ── 1. District-wise ────────────────────────────────────
    if report_type in ('all', 'district'):
        groups = defaultdict(list)
        for t in Tower.objects.select_related('area__taluka__constituency__district'):
            try:
                name = t.area.taluka.constituency.district.name
            except AttributeError:
                name = 'Unknown'
            groups[name].append(t)

        data['district_wise'] = [
            {
                'district':          dist,
                'total_towers':      len(towers),
                'government_towers': sum(1 for t in towers if t.land_type == 'government'),
                'private_towers':    sum(1 for t in towers if t.land_type == 'private'),
                'active_towers':     sum(1 for t in towers if t.status == 'active'),
            }
            for dist, towers in groups.items()
        ]

    # ── 2. Taluka-wise ──────────────────────────────────────
    if report_type in ('all', 'taluka'):
        groups = defaultdict(list)
        for t in Tower.objects.select_related('area__taluka__constituency__district'):
            try:
                name = t.area.taluka.name
            except AttributeError:
                name = 'Unknown'
            groups[name].append(t)

        data['taluka_wise'] = [
            {
                'taluka':       taluka,
                'district':     _safe_district(towers[0]) if towers else 'Goa',
                'tower_count':  len(towers),
                'active_count': sum(1 for t in towers if t.status == 'active'),
            }
            for taluka, towers in groups.items()
        ]

    # ── 3. Operator-wise ────────────────────────────────────
    if report_type in ('all', 'operator'):
        data['operator_wise'] = [
            {
                'id':          f"OPR-{str(op.id).zfill(3)}",
                'name':        op.name,
                'short_name':  op.short_name,
                'tower_count': op.towers.count(),
                'contact':     op.phone or op.contact_person or 'N/A',
            }
            for op in Operator.objects.prefetch_related('towers')
        ]

    # ── 4. Land-type ────────────────────────────────────────
    if report_type in ('all', 'land'):
        data['land_type'] = {
            'government': {
                'count':       Tower.objects.filter(land_type='government').count(),
                'yearly_rent': float(Tower.objects.filter(land_type='government').aggregate(t=Sum('yearly_rent'))['t'] or 0),
            },
            'private': {
                'count':       Tower.objects.filter(land_type='private').count(),
                'yearly_rent': float(Tower.objects.filter(land_type='private').aggregate(t=Sum('yearly_rent'))['t'] or 0),
            },
        }

    # ── 5. Rent Due ─────────────────────────────────────────
    if report_type in ('all', 'rent_due'):
        data['rent_due'] = [
            {
                'tower_id':      t.tower_unique_id or f"TWR-{str(t.id).zfill(4)}",
                'owner':         t.owner.name if t.owner else 'Government',
                'location':      f"{_safe_area(t)}, {_safe_taluka(t)}",
                'yearly_rent':   float(t.yearly_rent or 0),
                'rent_due_date': str(t.rent_due_date) if t.rent_due_date else 'N/A',
                'status':        'Overdue',
            }
            for t in Tower.objects.select_related('area__taluka', 'owner').filter(
                rent_due_date__lte=timezone.now().date()
            )
        ]

    # ── 6. Rent Collection ──────────────────────────────────
    if report_type in ('all', 'collection'):
        data['rent_collection'] = {
            'total_collected': float(RentPayment.objects.filter(payment_status='paid').aggregate(t=Sum('amount'))['t'] or 0),
            'total_pending':   float(RentPayment.objects.filter(payment_status__in=['pending', 'overdue']).aggregate(t=Sum('amount'))['t'] or 0),
            'paid_count':      RentPayment.objects.filter(payment_status='paid').count(),
            'pending_count':   RentPayment.objects.filter(payment_status__in=['pending', 'overdue']).count(),
        }

    # ── 7. Payment History ──────────────────────────────────
    if report_type in ('all', 'payments'):
        data['payments'] = [
            {
                'receipt_no':   p.payment_reference or f"RCP-{p.id}",
                'tower_id':     p.tower.tower_unique_id if p.tower else f"TWR-{str(p.tower_id).zfill(4)}",
                'amount':       float(p.amount),
                'payment_date': str(p.payment_date) if p.payment_date else 'N/A',
                'status':       (p.payment_status or 'paid').capitalize(),
                'mode':         p.payment_method or 'Bank Transfer / NEFT',
            }
            for p in RentPayment.objects.select_related('tower').order_by('-payment_date')[:50]
        ]

    return Response({'data': data})


# ─── Helpers ────────────────────────────────────────────────
def _safe_district(tower):
    try:
        return tower.area.taluka.constituency.district.name
    except AttributeError:
        return 'Goa'

def _safe_area(tower):
    try:
        return tower.area.name
    except AttributeError:
        return 'N/A'

def _safe_taluka(tower):
    try:
        return tower.area.taluka.name
    except AttributeError:
        return 'N/A'
