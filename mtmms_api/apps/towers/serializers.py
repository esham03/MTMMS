from rest_framework import serializers
from .models import Tower, TowerRentRenewal
from apps.operators.serializers import OperatorSerializer
from apps.owners.serializers    import OwnerSerializer
from apps.locations.serializers import AreaNestedSerializer
import datetime


class TowerRentRenewalSerializer(serializers.ModelSerializer):
    approved_by_details = serializers.SerializerMethodField()
    tower_unique_id     = serializers.CharField(source='tower.tower_unique_id', read_only=True)

    class Meta:
        model  = TowerRentRenewal
        fields = [
            'id', 'tower', 'tower_unique_id', 'renewal_reference',
            'previous_yearly_rent', 'escalation_percentage', 'increase_amount',
            'new_yearly_rent', 'calculated_yearly_rent',
            'is_manual_override', 'manual_override_reason',
            'prev_agreement_start_date', 'prev_agreement_end_date',
            'new_agreement_start_date', 'new_agreement_end_date',
            'effective_date', 'renewal_date', 'renewal_cycle_years',
            'status', 'approved_by', 'approved_by_name', 'approved_by_details',
            'remarks', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'renewal_reference', 'created_at', 'updated_at']

    def get_approved_by_details(self, obj):
        if obj.approved_by:
            return {
                'id': obj.approved_by.id,
                'name': obj.approved_by.name,
                'email': obj.approved_by.email,
                'role': obj.approved_by.role,
            }
        return {'name': obj.approved_by_name or 'System Administrator'}


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
    renewals      = serializers.SerializerMethodField()

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
            'escalation_enabled', 'escalation_percentage',
            'agreement_start_date', 'agreement_end_date',
            'next_renewal_date', 'last_revised_rent', 'last_escalation_date',
            'address', 'latitude', 'longitude', 'remarks',
            'rent_payments', 'renewals',
            'created_at', 'updated_at',
        ]

    def get_rent_payments(self, obj):
        from apps.rent_payments.serializers import RentPaymentSerializer
        return RentPaymentSerializer(obj.rent_payments.all().order_by('-payment_date'), many=True).data

    def get_renewals(self, obj):
        return TowerRentRenewalSerializer(obj.renewals.all().order_by('-effective_date', '-created_at'), many=True).data

    def create(self, validated_data):
        operator_ids = validated_data.pop('operator_ids', [])

        # Auto-calculate monthly rent if yearly is provided
        if validated_data.get('yearly_rent'):
            validated_data['monthly_rent'] = round(float(validated_data['yearly_rent']) / 12, 2)
        elif validated_data.get('monthly_rent') and not validated_data.get('yearly_rent'):
            validated_data['yearly_rent'] = round(float(validated_data['monthly_rent']) * 12, 2)

        # Sync agreement dates
        if not validated_data.get('agreement_start_date') and validated_data.get('rent_start_date'):
            validated_data['agreement_start_date'] = validated_data['rent_start_date']

        start = validated_data.get('agreement_start_date')
        cycle = validated_data.get('rent_cycle_years') or 5
        if start and not validated_data.get('agreement_end_date'):
            try:
                validated_data['agreement_end_date'] = start.replace(year=start.year + cycle)
            except ValueError:
                validated_data['agreement_end_date'] = start + datetime.timedelta(days=cycle*365)

        if not validated_data.get('next_renewal_date') and validated_data.get('agreement_end_date'):
            validated_data['next_renewal_date'] = validated_data['agreement_end_date']

        if validated_data.get('last_revised_rent') is None and validated_data.get('yearly_rent'):
            validated_data['last_revised_rent'] = validated_data['yearly_rent']

        tower = Tower.objects.create(**validated_data)
        if operator_ids:
            tower.operators.set(operator_ids, through_defaults={'status': 'active'})
        return tower

    def update(self, instance, validated_data):
        operator_ids = validated_data.pop('operator_ids', None)

        # Auto-calc monthly rent on update too
        if 'yearly_rent' in validated_data and validated_data.get('yearly_rent') is not None:
            validated_data['monthly_rent'] = round(float(validated_data['yearly_rent']) / 12, 2)
        elif 'monthly_rent' in validated_data and ('yearly_rent' not in validated_data or validated_data.get('yearly_rent') is None):
            validated_data['yearly_rent'] = round(float(validated_data['monthly_rent']) * 12, 2)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # Sync next renewal date if agreement_end_date is updated
        if instance.agreement_end_date and not instance.next_renewal_date:
            instance.next_renewal_date = instance.agreement_end_date

        instance.save()

        if operator_ids is not None:
            instance.operators.set(operator_ids, through_defaults={'status': 'active'})
        return instance
