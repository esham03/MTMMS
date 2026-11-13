"""
Tower views — replaces Laravel TowerController
All endpoints match exactly: list, create, retrieve, update, destroy,
plus custom actions: rent, payments, sync_operators, renewals, preview_renewal, confirm_renewal
"""

import datetime
import re
import uuid
from decimal import Decimal

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from .models import Tower, TowerRentRenewal
from .serializers import TowerSerializer, TowerRentRenewalSerializer


def _add_years(d, years):
    try:
        return d.replace(year=d.year + years)
    except ValueError:
        return d + datetime.timedelta(days=years * 365)


def _parse_date(val):
    if not val:
        return None
    if isinstance(val, (datetime.date, datetime.datetime)):
        return val.date() if isinstance(val, datetime.datetime) else val
    try:
        clean = str(val).split('T')[0].strip()
        return datetime.date.fromisoformat(clean)
    except Exception:
        return None


class TowerViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = TowerSerializer

    def get_queryset(self):
        qs = Tower.objects.select_related(
            'area__taluka__constituency__district',
            'owner',
        ).prefetch_related(
            'operators',
            'rent_payments',
            'renewals',
        ).order_by('-created_at')

        params = self.request.query_params

        # Full-text search — mirrors Laravel orWhere/orWhereHas
        if search := params.get('search'):
            qs = qs.filter(
                Q(tower_unique_id__icontains=search) |
                Q(address__icontains=search) |
                Q(area__name__icontains=search) |
                Q(operators__name__icontains=search) |
                Q(operators__short_name__icontains=search) |
                Q(owner__name__icontains=search)
            ).distinct()

        # Location filters — mirrors Laravel whereHas chains
        if v := params.get('district_id'):
            qs = qs.filter(area__taluka__constituency__district_id=v)
        if v := params.get('constituency_id'):
            qs = qs.filter(area__taluka__constituency_id=v)
        if v := params.get('taluka_id'):
            qs = qs.filter(area__taluka_id=v)
        if v := params.get('area_id'):
            qs = qs.filter(area_id=v)

        # Other filters
        if v := params.get('land_type'):
            qs = qs.filter(land_type=v)
        if v := params.get('status'):
            qs = qs.filter(status=v)
        if v := params.get('operator_id'):
            qs = qs.filter(operators__id=v)
        if v := params.get('owner_id'):
            qs = qs.filter(owner_id=v)

        return qs

    def retrieve(self, request, *args, **kwargs):
        """Support lookup by numeric ID or tower_unique_id (e.g., TWR-0001)"""
        pk = kwargs.get('pk')
        tower = Tower.objects.select_related(
            'area__taluka__constituency__district', 'owner'
        ).prefetch_related('operators', 'rent_payments', 'renewals').filter(
            Q(id=pk) | Q(tower_unique_id=pk)
        ).first()

        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(tower)
        return Response({'data': serializer.data})

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()

        # Return all without pagination if requested
        if request.query_params.get('all') == 'true' or request.query_params.get('paginate') == 'false':
            serializer = self.get_serializer(qs, many=True)
            return Response({'data': serializer.data})

        # Paginated
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(qs, many=True)
        return Response({'data': serializer.data})

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tower = serializer.save()
        return Response(
            {'message': 'Tower created successfully', 'data': self.get_serializer(tower).data},
            status=status.HTTP_201_CREATED
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        pk      = kwargs.get('pk')
        tower   = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(tower, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        tower = serializer.save()
        return Response({'message': 'Tower updated successfully', 'data': self.get_serializer(tower).data})

    def destroy(self, request, *args, **kwargs):
        pk    = kwargs.get('pk')
        tower = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        tower.operators.clear()
        tower.rent_payments.all().delete()
        tower.renewals.all().delete()
        tower.delete()
        return Response({'message': 'Tower deleted successfully'})

    # ── GET /api/towers/{id}/rent ──────────────────────────
    @action(detail=True, methods=['get'])
    def rent(self, request, pk=None):
        tower = Tower.objects.prefetch_related('rent_payments', 'renewals').filter(
            Q(id=pk) | Q(tower_unique_id=pk)
        ).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        last_payment = tower.rent_payments.order_by('-payment_date').first()
        last_renewal = tower.renewals.order_by('-effective_date', '-created_at').first()
        from apps.rent_payments.serializers import RentPaymentSerializer

        return Response({'data': {
            'tower_id':              tower.id,
            'tower_unique_id':       tower.tower_unique_id,
            'monthly_rent':          tower.monthly_rent,
            'yearly_rent':           tower.yearly_rent,
            'rent_cycle_years':      tower.rent_cycle_years,
            'escalation_enabled':    tower.escalation_enabled,
            'escalation_percentage': float(tower.escalation_percentage or 0),
            'agreement_start_date':  str(tower.agreement_start_date) if tower.agreement_start_date else None,
            'agreement_end_date':    str(tower.agreement_end_date) if tower.agreement_end_date else None,
            'next_renewal_date':     str(tower.next_renewal_date) if tower.next_renewal_date else None,
            'last_revised_rent':     float(tower.last_revised_rent) if tower.last_revised_rent is not None else tower.yearly_rent,
            'last_escalation_date':  str(tower.last_escalation_date) if tower.last_escalation_date else None,
            'rent_due_date':         str(tower.rent_due_date) if tower.rent_due_date else None,
            'rent_start_date':       str(tower.rent_start_date) if tower.rent_start_date else None,
            'last_payment':          RentPaymentSerializer(last_payment).data if last_payment else None,
            'last_renewal':          TowerRentRenewalSerializer(last_renewal).data if last_renewal else None,
        }})

    # ── GET /api/towers/{id}/payments ─────────────────────
    @action(detail=True, methods=['get'])
    def payments(self, request, pk=None):
        tower = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        from apps.rent_payments.serializers import RentPaymentSerializer
        payments = tower.rent_payments.order_by('-payment_date')
        return Response({'data': RentPaymentSerializer(payments, many=True).data})

    # ── POST /api/towers/{id}/operators ───────────────────
    @action(detail=True, methods=['post'], url_path='operators')
    def sync_operators(self, request, pk=None):
        tower = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        operator_ids = request.data.get('operator_ids', [])
        tower.operators.set(operator_ids)

        from apps.operators.serializers import OperatorSerializer
        return Response({
            'message': 'Operators synchronized successfully',
            'data': {'operators': OperatorSerializer(tower.operators.all(), many=True).data},
        })

    # ── GET /api/towers/{id}/renewals ─────────────────────
    @action(detail=True, methods=['get'], url_path='renewals')
    def renewals(self, request, pk=None):
        tower = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        renewals = tower.renewals.all().order_by('-effective_date', '-created_at')
        return Response({'data': TowerRentRenewalSerializer(renewals, many=True).data})

    # ── POST /api/towers/{id}/preview-renewal ─────────────
    @action(detail=True, methods=['post'], url_path='preview-renewal')
    def preview_renewal(self, request, pk=None):
        tower = Tower.objects.select_related(
            'area__taluka__constituency__district', 'owner'
        ).prefetch_related('operators').filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        # Configured escalation settings
        is_enabled = bool(request.data.get('escalation_enabled', tower.escalation_enabled))
        try:
            custom_pct = request.data.get('escalation_percentage')
            if custom_pct is not None and str(custom_pct).strip() != '':
                percentage = Decimal(str(custom_pct))
                if percentage < 0:
                    return Response({'error': 'Escalation percentage cannot be negative.'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                percentage = Decimal(str(tower.escalation_percentage if tower.escalation_percentage is not None else 10.00))
        except Exception:
            percentage = Decimal('10.00')

        try:
            cycle_years = int(request.data.get('renewal_cycle_years') or tower.rent_cycle_years or 5)
            if cycle_years < 1:
                cycle_years = 1
        except Exception:
            cycle_years = 5

        # Current annual rent
        previous_rent = Decimal(str(tower.yearly_rent or 0.00))

        # Calculation
        if is_enabled and percentage > 0:
            increase_amount = round(previous_rent * (percentage / Decimal('100.00')), 2)
            proposed_rent   = previous_rent + increase_amount
        else:
            increase_amount = Decimal('0.00')
            proposed_rent   = previous_rent

        # Dates
        prev_start = tower.agreement_start_date or tower.rent_start_date
        prev_end   = tower.agreement_end_date or tower.next_renewal_date
        if prev_start and not prev_end:
            prev_end = _add_years(prev_start, tower.rent_cycle_years or 5)

        new_start = _parse_date(request.data.get('new_agreement_start_date'))
        if not new_start:
            new_start = prev_end or timezone.now().date()

        new_end = _parse_date(request.data.get('new_agreement_end_date'))
        if not new_end:
            new_end = _add_years(new_start, cycle_years)

        effective_date = _parse_date(request.data.get('effective_date')) or new_start

        # Location and operator strings
        try:
            location_str = f"{tower.area.name}, {tower.area.taluka.name}"
        except Exception:
            location_str = tower.address or "Goa"

        owner_name = tower.owner.name if tower.owner else ("Government of Goa" if tower.land_type == 'government' else "Private")
        operator_names = [op.short_name or op.name for op in tower.operators.all()]

        return Response({'data': {
            'tower_id':                      tower.id,
            'tower_unique_id':               tower.tower_unique_id,
            'location':                      location_str,
            'owner_name':                    owner_name,
            'operator_names':                operator_names,
            'land_type':                     tower.land_type,
            'previous_yearly_rent':          float(previous_rent),
            'previous_annual_rent':          float(previous_rent),
            'escalation_enabled':            is_enabled,
            'is_escalation_enabled':         is_enabled,
            'escalation_percentage':         float(percentage),
            'increase_amount':               float(increase_amount),
            'proposed_yearly_rent':          float(proposed_rent),
            'proposed_new_annual_rent':      float(proposed_rent),
            'new_annual_rent':               float(proposed_rent),
            'proposed_monthly_rent':         round(float(proposed_rent) / 12.0, 2),
            'previous_agreement_start_date': str(prev_start) if prev_start else None,
            'previous_agreement_end_date':   str(prev_end) if prev_end else None,
            'new_agreement_start_date':      str(new_start),
            'new_agreement_end_date':        str(new_end),
            'renewal_cycle_years':           cycle_years,
            'effective_date':                str(effective_date),
        }})

    # ── POST /api/towers/{id}/confirm-renewal ────────────
    @action(detail=True, methods=['post'], url_path='confirm-renewal')
    def confirm_renewal(self, request, pk=None):
        """
        Executes rental agreement renewal and applies rent escalation atomically.
        Guarantees:
        - DB Transaction
        - Concurrency lock (select_for_update)
        - Role check (override requires admin)
        - Mandatory override reason
        - Duplicate renewal prevention
        - Historical payment & rent record preservation
        """
        # Role-based validation
        user_role = getattr(request.user, 'role', 'admin').lower() if request.user else 'viewer'
        if user_role not in ['admin', 'officer']:
            return Response(
                {'error': 'Unauthorized: Only designated administrators or nodal officers may confirm agreement renewals.'},
                status=status.HTTP_403_FORBIDDEN
            )

        with transaction.atomic():
            tower = Tower.objects.select_for_update().filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
            if not tower:
                return Response({'error': 'Tower not found.'}, status=status.HTTP_404_NOT_FOUND)

            # Extract inputs
            new_start_raw = request.data.get('new_agreement_start_date')
            new_end_raw   = request.data.get('new_agreement_end_date')
            eff_raw       = request.data.get('effective_date')

            new_start = _parse_date(new_start_raw)
            new_end   = _parse_date(new_end_raw)
            effective = _parse_date(eff_raw) or new_start

            if not new_start:
                return Response({'error': 'Valid new agreement start date is required.'}, status=status.HTTP_400_BAD_REQUEST)

            try:
                cycle_years = int(request.data.get('renewal_cycle_years') or tower.rent_cycle_years or 5)
                if cycle_years < 1:
                    cycle_years = 1
            except Exception:
                cycle_years = 5

            if not new_end:
                new_end = _add_years(new_start, cycle_years)

            if new_end <= new_start:
                return Response({'error': 'New agreement end date must be after the start date.'}, status=status.HTTP_400_BAD_REQUEST)

            # Prevent duplicate renewal execution
            existing_duplicate = TowerRentRenewal.objects.filter(
                tower=tower,
                new_agreement_start_date=new_start,
                new_agreement_end_date=new_end,
                status__in=['confirmed', 'overridden'],
            ).exists()
            if existing_duplicate:
                return Response(
                    {'error': f'Duplicate Renewal Prevented: An active agreement renewal covering {new_start} to {new_end} has already been confirmed for {tower.tower_unique_id}.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Calculate Escalation
            prev_yearly_rent = Decimal(str(tower.yearly_rent or 0.00))

            # Configured or manually adjusted escalation settings
            if 'escalation_enabled' in request.data:
                esc_en_val = request.data.get('escalation_enabled')
                is_enabled = bool(esc_en_val is True or str(esc_en_val).lower() in ('true', '1'))
            else:
                is_enabled = tower.escalation_enabled

            custom_pct = request.data.get('escalation_percentage')
            if custom_pct is not None and str(custom_pct).strip() != '':
                try:
                    pct_val = Decimal(str(custom_pct))
                    if pct_val < 0:
                        return Response({'error': 'Escalation percentage cannot be negative.'}, status=status.HTTP_400_BAD_REQUEST)
                    if pct_val > 100:
                        return Response({'error': 'Escalation percentage cannot exceed 100%.'}, status=status.HTTP_400_BAD_REQUEST)
                except Exception:
                    pct_val = Decimal(str(tower.escalation_percentage or 10.00))
            else:
                pct_val = Decimal(str(tower.escalation_percentage or 10.00))

            if is_enabled and pct_val > 0:
                calc_increase = round(prev_yearly_rent * (pct_val / Decimal('100.00')), 2)
                calc_new_rent = prev_yearly_rent + calc_increase
            else:
                calc_increase = Decimal('0.00')
                calc_new_rent = prev_yearly_rent

            # Check Manual Override
            is_override_flag = request.data.get('is_manual_override', False)
            override_val = request.data.get('override_yearly_rent') if request.data.get('override_yearly_rent') is not None else request.data.get('manual_new_rent')
            override_reason = (request.data.get('override_reason') or request.data.get('manual_override_reason') or '').strip()
            is_override = False

            if is_override_flag or (override_val is not None and str(override_val).strip() != ''):
                # Role check: only admin can override
                if user_role != 'admin':
                    return Response(
                        {'error': 'Unauthorized: Only full Administrators are permitted to manually override calculated rent.'},
                        status=status.HTTP_403_FORBIDDEN
                    )
                if not override_reason:
                    return Response(
                        {'error': 'A comprehensive justification reason is mandatory when manually overriding rent escalation.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                if override_val is None or str(override_val).strip() == '':
                    return Response(
                        {'error': 'Please provide the manual overridden annual rent amount.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                try:
                    final_yearly_rent = round(Decimal(str(override_val)), 2)
                    if final_yearly_rent <= 0:
                        return Response({'error': 'Overridden yearly rent must be a positive amount.'}, status=status.HTTP_400_BAD_REQUEST)
                except Exception:
                    return Response({'error': 'Invalid overridden yearly rent amount.'}, status=status.HTTP_400_BAD_REQUEST)

                is_override = True
                final_increase = final_yearly_rent - prev_yearly_rent
                status_code = 'overridden'
            else:
                final_yearly_rent = calc_new_rent
                final_increase    = calc_increase
                status_code       = 'confirmed'

            # Generate unique audit reference ID
            clean_code = re.sub(r'[^A-Za-z0-9]', '', tower.tower_unique_id)
            ref = f"REN-{clean_code}-{effective.strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

            user_obj = request.user if request.user.is_authenticated else None
            user_display_name = getattr(user_obj, 'name', None) or getattr(user_obj, 'email', None) or 'Administrator'

            # 1. Create audit log record
            renewal = TowerRentRenewal.objects.create(
                tower=tower,
                renewal_reference=ref,
                previous_yearly_rent=prev_yearly_rent,
                escalation_percentage=pct_val if is_enabled else Decimal('0.00'),
                increase_amount=final_increase,
                new_yearly_rent=final_yearly_rent,
                calculated_yearly_rent=calc_new_rent,
                is_manual_override=is_override,
                manual_override_reason=override_reason if is_override else None,
                prev_agreement_start_date=tower.agreement_start_date or tower.rent_start_date,
                prev_agreement_end_date=tower.agreement_end_date or tower.next_renewal_date,
                new_agreement_start_date=new_start,
                new_agreement_end_date=new_end,
                effective_date=effective,
                renewal_cycle_years=cycle_years,
                status=status_code,
                approved_by=user_obj,
                approved_by_name=user_display_name,
                remarks=request.data.get('remarks') or f"Official agreement renewal for {cycle_years} years.",
            )

            # 2. Update Tower record
            tower.last_revised_rent    = final_yearly_rent
            tower.yearly_rent          = float(final_yearly_rent)
            tower.monthly_rent         = round(float(final_yearly_rent) / 12.0, 2)
            tower.last_escalation_date = effective
            tower.agreement_start_date = new_start
            tower.agreement_end_date   = new_end
            tower.next_renewal_date    = new_end
            tower.rent_due_date        = new_start
            tower.rent_cycle_years     = cycle_years
            tower.escalation_enabled   = is_enabled
            if custom_pct is not None and str(custom_pct).strip() != '':
                tower.escalation_percentage = pct_val
            tower.save()

            return Response({
                'message': f"Agreement renewed successfully for {tower.tower_unique_id}. Revised Annual Rent: ₹{final_yearly_rent:,.2f}",
                'data': {
                    'renewal': TowerRentRenewalSerializer(renewal).data,
                    'tower':   self.get_serializer(tower).data,
                }
            }, status=status.HTTP_201_CREATED)

    # ── POST /api/towers/{id}/update-escalation ───────────
    @action(detail=True, methods=['post', 'patch'], url_path='update-escalation')
    def update_escalation(self, request, pk=None):
        """Allows direct adjustment of a tower's rent escalation configuration."""
        tower = Tower.objects.filter(Q(id=pk) | Q(tower_unique_id=pk)).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        if 'escalation_enabled' in request.data:
            val = request.data.get('escalation_enabled')
            tower.escalation_enabled = bool(val is True or str(val).lower() in ('true', '1'))

        if 'escalation_percentage' in request.data:
            try:
                pct = Decimal(str(request.data.get('escalation_percentage')))
                if pct < 0:
                    return Response({'error': 'Escalation percentage cannot be negative.'}, status=status.HTTP_400_BAD_REQUEST)
                if pct > 100:
                    return Response({'error': 'Escalation percentage cannot exceed 100%.'}, status=status.HTTP_400_BAD_REQUEST)
                tower.escalation_percentage = pct
            except Exception:
                return Response({'error': 'Invalid escalation percentage value.'}, status=status.HTTP_400_BAD_REQUEST)

        tower.save()
        return Response({
            'message': f'Escalation configuration updated for {tower.tower_unique_id}',
            'data': {
                'id': tower.id,
                'tower_unique_id': tower.tower_unique_id,
                'escalation_enabled': tower.escalation_enabled,
                'escalation_percentage': float(tower.escalation_percentage or 0),
            }
        })

    # ── GET /api/towers/all-renewals ──────────────────────
    @action(detail=False, methods=['get'], url_path='all-renewals')
    def all_renewals(self, request):
        renewals = TowerRentRenewal.objects.select_related('tower', 'approved_by').order_by('-effective_date', '-created_at')
        if tower_id := request.query_params.get('tower_id'):
            renewals = renewals.filter(tower__id=tower_id)
        return Response({'data': TowerRentRenewalSerializer(renewals, many=True).data})

    # ── GET /api/towers/upcoming-renewals ─────────────────
    @action(detail=False, methods=['get'], url_path='upcoming-renewals')
    def upcoming_renewals(self, request):
        today = timezone.now().date()
        days_ahead = int(request.query_params.get('days', 90))
        target_date = today + datetime.timedelta(days=days_ahead)

        towers = Tower.objects.select_related(
            'area__taluka__constituency__district', 'owner'
        ).prefetch_related('operators').filter(
            Q(agreement_end_date__lte=target_date) | Q(next_renewal_date__lte=target_date)
        ).order_by('next_renewal_date', 'agreement_end_date')

        return Response({'data': self.get_serializer(towers, many=True).data})
