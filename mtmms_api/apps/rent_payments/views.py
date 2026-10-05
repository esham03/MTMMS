"""
Rent Payment views — replaces Laravel RentPaymentController
Full CRUD with search and filters matching Laravel implementation
"""

from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q

from .models import RentPayment
from .serializers import RentPaymentSerializer


class RentPaymentViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = RentPaymentSerializer

    def get_queryset(self):
        qs = RentPayment.objects.select_related(
            'tower__owner',
            'tower__area__taluka__constituency__district',
        ).prefetch_related(
            'tower__operators',
        ).order_by('-created_at')

        params = self.request.query_params

        if v := params.get('tower_id'):
            qs = qs.filter(tower_id=v)
        if v := params.get('payment_status'):
            qs = qs.filter(payment_status=v)
        if v := params.get('payment_method'):
            qs = qs.filter(payment_method=v)

        if search := params.get('search'):
            qs = qs.filter(
                Q(payment_reference__icontains=search) |
                Q(payment_method__icontains=search) |
                Q(tower__tower_unique_id__icontains=search) |
                Q(tower__address__icontains=search) |
                Q(tower__operators__name__icontains=search) |
                Q(tower__operators__short_name__icontains=search) |
                Q(tower__owner__name__icontains=search)
            ).distinct()

        return qs

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()

        if request.query_params.get('all') == 'true' or request.query_params.get('paginate') == 'false':
            return Response({'data': self.get_serializer(qs, many=True).data})

        page = self.paginate_queryset(qs)
        if page is not None:
            return self.get_paginated_response(self.get_serializer(page, many=True).data)

        return Response({'data': self.get_serializer(qs, many=True).data})

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payment = serializer.save()
        return Response(
            {'message': 'Rent payment created successfully', 'data': self.get_serializer(payment).data},
            status=status.HTTP_201_CREATED
        )

    def update(self, request, *args, **kwargs):
        partial    = kwargs.pop('partial', False)
        instance   = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        payment = serializer.save()
        return Response({'message': 'Rent payment updated successfully', 'data': self.get_serializer(payment).data})

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({'message': 'Rent payment deleted successfully'})
