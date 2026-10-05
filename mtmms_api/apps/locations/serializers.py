from rest_framework import serializers
from .models import District, Constituency, Taluka, Area


class DistrictSerializer(serializers.ModelSerializer):
    class Meta:
        model  = District
        fields = '__all__'


class TalukaSerializer(serializers.ModelSerializer):
    district_id   = serializers.IntegerField(source='constituency.district_id', read_only=True)
    district_name = serializers.CharField(source='constituency.district.name', read_only=True)

    class Meta:
        model  = Taluka
        fields = '__all__'


class ConstituencySerializer(serializers.ModelSerializer):
    district_id   = serializers.IntegerField(read_only=True)
    district_name = serializers.CharField(source='district.name', read_only=True)

    class Meta:
        model  = Constituency
        fields = '__all__'


class AreaSerializer(serializers.ModelSerializer):
    taluka_id   = serializers.IntegerField(read_only=True)
    taluka_name = serializers.CharField(source='taluka.name', read_only=True)

    class Meta:
        model  = Area
        fields = '__all__'


# Nested serializers for full location chain (used in Tower serializer)
class DistrictNestedSerializer(serializers.ModelSerializer):
    class Meta:
        model  = District
        fields = ['id', 'name']


class ConstituencyNestedSerializer(serializers.ModelSerializer):
    district = DistrictNestedSerializer(read_only=True)

    class Meta:
        model  = Constituency
        fields = ['id', 'name', 'district']


class TalukaNestedSerializer(serializers.ModelSerializer):
    constituency = ConstituencyNestedSerializer(read_only=True)

    class Meta:
        model  = Taluka
        fields = ['id', 'name', 'constituency']


class AreaNestedSerializer(serializers.ModelSerializer):
    taluka = TalukaNestedSerializer(read_only=True)

    class Meta:
        model  = Area
        fields = ['id', 'name', 'pincode', 'taluka']
