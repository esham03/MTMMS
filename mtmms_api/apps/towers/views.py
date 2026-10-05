"""
Tower views — replaces Laravel TowerController
All endpoints match exactly: list, create, retrieve, update, destroy,
plus custom actions: rent, payments, sync_operators
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404

from .models import Tower
from .serializers import TowerSerializer


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
        ).prefetch_related('operators', 'rent_payments').filter(
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

        tower.operators.clear()               # replaces ->operators()->detach()
        tower.rent_payments.all().delete()    # replaces ->rentPayments()->delete()
        tower.delete()
        return Response({'message': 'Tower deleted successfully'})

    # ── GET /api/towers/{id}/rent ──────────────────────────
    @action(detail=True, methods=['get'])
    def rent(self, request, pk=None):
        tower = Tower.objects.prefetch_related('rent_payments').filter(
            Q(id=pk) | Q(tower_unique_id=pk)
        ).first()
        if not tower:
            return Response({'message': 'Tower not found'}, status=status.HTTP_404_NOT_FOUND)

        last_payment = tower.rent_payments.order_by('-payment_date').first()
        from apps.rent_payments.serializers import RentPaymentSerializer

        return Response({'data': {
            'tower_id':        tower.id,
            'tower_unique_id': tower.tower_unique_id,
            'monthly_rent':    tower.monthly_rent,
            'yearly_rent':     tower.yearly_rent,
            'rent_due_date':   str(tower.rent_due_date) if tower.rent_due_date else None,
            'rent_start_date': str(tower.rent_start_date) if tower.rent_start_date else None,
            'last_payment':    RentPaymentSerializer(last_payment).data if last_payment else None,
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
        tower.operators.set(operator_ids)    # replaces ->sync()

        from apps.operators.serializers import OperatorSerializer
        return Response({
            'message': 'Operators synchronized successfully',
            'data': {'operators': OperatorSerializer(tower.operators.all(), many=True).data},
        })
