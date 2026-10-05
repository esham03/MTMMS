from django.db import models
from apps.towers.models import Tower


class RentPayment(models.Model):
    STATUS_CHOICES = [
        ('pending',   'Pending'),
        ('paid',      'Paid'),
        ('overdue',   'Overdue'),
        ('cancelled', 'Cancelled'),
    ]

    tower             = models.ForeignKey(Tower, on_delete=models.CASCADE, related_name='rent_payments')
    amount            = models.FloatField()
    payment_date      = models.DateField(null=True, blank=True)
    payment_reference = models.CharField(max_length=100, null=True, blank=True)
    payment_status    = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    period_start      = models.DateField(null=True, blank=True)
    period_end        = models.DateField(null=True, blank=True)
    payment_method    = models.CharField(max_length=50, null=True, blank=True)
    remarks           = models.TextField(null=True, blank=True)
    created_at        = models.DateTimeField(auto_now_add=True)
    updated_at        = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'rent_payments'

    def __str__(self):
        return f"Payment #{self.id} — Tower {self.tower_id}"
