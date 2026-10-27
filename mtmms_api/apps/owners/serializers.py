from rest_framework import serializers
from .models import Owner


class OwnerSerializer(serializers.ModelSerializer):
    contact_number = serializers.CharField(source='phone', required=False, allow_null=True, allow_blank=True)
    towers_count   = serializers.SerializerMethodField()
    towers         = serializers.SerializerMethodField()
    type           = serializers.CharField(required=False, allow_null=True, allow_blank=True)

    class Meta:
        model  = Owner
        fields = [
            'id', 'name', 'type', 'phone', 'contact_number', 'email', 'address',
            'towers_count', 'towers', 'created_at', 'updated_at',
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

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # If type is empty or null, derive from associated towers' land_type
        if not data.get('type'):
            first_tower = instance.towers.first()
            if first_tower and first_tower.land_type:
                data['type'] = first_tower.land_type
            else:
                data['type'] = 'government'
        return data
