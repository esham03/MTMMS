from rest_framework import serializers
from .models import Tower
from apps.operators.serializers import OperatorSerializer
from apps.owners.serializers    import OwnerSerializer
from apps.locations.serializers import AreaNestedSerializer


class TowerSerializer(serializers.ModelSerializer):
    # Read-only nested objects (for GET responses)
    area      = AreaNestedSerializer(read_only=True)
    owner     = OwnerSerializer(read_only=True)
    operators = OperatorSerializer(many=True, read_only=True)

    # Write-only IDs (for POST/PUT)
    area_id      = serializers.PrimaryKeyRelatedField(
        queryset=__import__('apps.locations.models', fromlist=['Area']).Area.objects.all(),
        source='area', write_only=True, required=False, allow_null=True
    )
    owner_id     = serializers.PrimaryKeyRelatedField(
        queryset=__import__('apps.owners.models', fromlist=['Owner']).Owner.objects.all(),
        source='owner', write_only=True, required=False, allow_null=True
    )
    operator_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True, required=False
    )
    rent_payments = serializers.SerializerMethodField()

    class Meta:
        model  = Tower
        fields = [
            'id', 'tower_unique_id',
            'area', 'area_id',
            'owner', 'owner_id',
            'operators', 'operator_ids',
            'land_type', 'height', 'width', 'frequency', 'status',
            'monthly_rent', 'yearly_rent', 'rent_cycle_years',
            'installation_date', 'rent_start_date', 'rent_due_date',
            'address', 'latitude', 'longitude', 'remarks',
            'rent_payments',
            'created_at', 'updated_at',
        ]

    def get_rent_payments(self, obj):
        from apps.rent_payments.serializers import RentPaymentSerializer
        return RentPaymentSerializer(obj.rent_payments.all(), many=True).data

    def create(self, validated_data):
        operator_ids = validated_data.pop('operator_ids', [])

        # Auto-calculate monthly rent if only yearly is provided (mirrors Laravel)
        if not validated_data.get('monthly_rent') and validated_data.get('yearly_rent'):
            validated_data['monthly_rent'] = round(validated_data['yearly_rent'] / 12, 2)

        tower = Tower.objects.create(**validated_data)
        if operator_ids:
            tower.operators.set(operator_ids)
        return tower

    def update(self, instance, validated_data):
        operator_ids = validated_data.pop('operator_ids', None)

        # Auto-calc monthly rent on update too
        if 'yearly_rent' in validated_data and 'monthly_rent' not in validated_data:
            validated_data['monthly_rent'] = round(validated_data['yearly_rent'] / 12, 2)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if operator_ids is not None:
            instance.operators.set(operator_ids)
        return instance
