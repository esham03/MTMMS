from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import District, Constituency, Taluka, Area
from .serializers import (
    DistrictSerializer, ConstituencySerializer,
    TalukaSerializer, AreaSerializer,
)


class DistrictViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only — mirrors Laravel DistrictController"""
    permission_classes = [IsAuthenticated]
    queryset           = District.objects.all().order_by('name')
    serializer_class   = DistrictSerializer
    pagination_class   = None

    def list(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response({'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({'data': serializer.data})


class ConstituencyViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = ConstituencySerializer
    pagination_class   = None

    def get_queryset(self):
        qs = Constituency.objects.select_related('district').order_by('name')
        if district_id := self.request.query_params.get('district_id'):
            qs = qs.filter(district_id=district_id)
        return qs

    def list(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response({'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({'data': serializer.data})


class TalukaViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = TalukaSerializer
    pagination_class   = None

    def get_queryset(self):
        qs = Taluka.objects.select_related('constituency__district').order_by('name')
        if constituency_id := self.request.query_params.get('constituency_id'):
            qs = qs.filter(constituency_id=constituency_id)
        if district_id := self.request.query_params.get('district_id'):
            qs = qs.filter(constituency__district_id=district_id)
        return qs

    def list(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response({'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({'data': serializer.data})


class AreaViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = AreaSerializer
    pagination_class   = None

    def get_queryset(self):
        qs = Area.objects.select_related('taluka__constituency__district').order_by('name')
        if taluka_id := self.request.query_params.get('taluka_id'):
            qs = qs.filter(taluka_id=taluka_id)
        return qs

    def list(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response({'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({'data': serializer.data})
