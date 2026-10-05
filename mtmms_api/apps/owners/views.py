from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from .models import Owner
from .serializers import OwnerSerializer


class OwnerViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class   = OwnerSerializer

    def get_queryset(self):
        qs = Owner.objects.prefetch_related('towers').all().order_by('-id')
        if search := self.request.query_params.get('search'):
            qs = qs.filter(
                Q(name__icontains=search) |
                Q(email__icontains=search) |
                Q(phone__icontains=search) |
                Q(address__icontains=search)
            )
        return qs

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        if request.query_params.get('all') == 'true' or request.query_params.get('paginate') == 'false':
            serializer = self.get_serializer(qs, many=True)
            return Response({'data': serializer.data})

        page = self.paginate_queryset(qs)
        if page is not None:
            return self.get_paginated_response(self.get_serializer(page, many=True).data)

        serializer = self.get_serializer(qs, many=True)
        return Response({'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({'data': serializer.data})

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        owner = serializer.save()
        return Response(
            {'message': 'Owner created successfully', 'data': self.get_serializer(owner).data},
            status=status.HTTP_201_CREATED
        )

    def update(self, request, *args, **kwargs):
        partial  = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        owner = serializer.save()
        return Response({'message': 'Owner updated successfully', 'data': self.get_serializer(owner).data})

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({'message': 'Owner deleted successfully'})
