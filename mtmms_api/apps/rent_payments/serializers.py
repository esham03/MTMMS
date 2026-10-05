from rest_framework import serializers
from .models import RentPayment


class RentPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model  = RentPayment
        fields = '__all__'
