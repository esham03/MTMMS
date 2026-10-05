from rest_framework import serializers
from .models import Owner


class OwnerSerializer(serializers.ModelSerializer):
    contact_number = serializers.CharField(source='phone', required=False, allow_null=True, allow_blank=True)
    towers_count   = serializers.SerializerMethodField()
    towers         = serializers.SerializerMethodField()
    type           = serializers.CharField(required=False, allow_null=True, allow_blank=True, write_only=True)

    class Meta:
        model  = Owner
        fields = [
            'id', 'name', 'phone', 'contact_number', 'email', 'address',
            'towers_count', 'towers', 'type', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_towers_count(self, obj):
        return obj.towers.count()

    def get_towers(self, obj):
        return [
            {
                'id':              t.id,
                'tower_unique_id': t.tower_unique_id,
                'land_type':       t.land_type,
                'status':          t.status,
            }
            for t in obj.towers.all()
        ]

    def create(self, validated_data):
        validated_data.pop('type', None)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        validated_data.pop('type', None)
        return super().update(instance, validated_data)
