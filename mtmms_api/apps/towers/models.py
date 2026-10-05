"""
Tower model — replaces Laravel Tower.php
Relationships:
  - BelongsTo Area (area → taluka → constituency → district)
  - BelongsTo Owner
  - BelongsToMany Operator (through TowerOperator pivot)
  - HasMany RentPayment
"""

from django.db import models
from apps.locations.models import Area
from apps.owners.models    import Owner
from apps.operators.models import Operator


class TowerOperator(models.Model):
    """Pivot table: tower_operator — replaces Laravel withPivot()"""
    tower                = models.ForeignKey('Tower', on_delete=models.CASCADE)
    operator             = models.ForeignKey(Operator, on_delete=models.CASCADE)
    frequency            = models.CharField(max_length=100, null=True, blank=True)
    agreement_start_date = models.DateField(null=True, blank=True)
    agreement_end_date   = models.DateField(null=True, blank=True)
    status               = models.CharField(max_length=50, null=True, blank=True)
    created_at           = models.DateTimeField(auto_now_add=True)
    updated_at           = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tower_operator'


class Tower(models.Model):
    tower_unique_id   = models.CharField(max_length=100, unique=True)
    area              = models.ForeignKey(Area, on_delete=models.SET_NULL, null=True, blank=True, related_name='towers')
    owner             = models.ForeignKey(Owner, on_delete=models.SET_NULL, null=True, blank=True, related_name='towers')
    operators         = models.ManyToManyField(Operator, through=TowerOperator, related_name='towers', blank=True)
    land_type         = models.CharField(max_length=50)
    height            = models.FloatField(null=True, blank=True)
    width             = models.FloatField(null=True, blank=True)
    frequency         = models.CharField(max_length=100, null=True, blank=True)
    status            = models.CharField(max_length=50, null=True, blank=True, default='active')
    monthly_rent      = models.FloatField(null=True, blank=True)
    yearly_rent       = models.FloatField(null=True, blank=True)
    rent_cycle_years  = models.IntegerField(null=True, blank=True)
    installation_date = models.DateField(null=True, blank=True)
    rent_start_date   = models.DateField(null=True, blank=True)
    rent_due_date     = models.DateField(null=True, blank=True)
    address           = models.TextField(null=True, blank=True)
    latitude          = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude         = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    remarks           = models.TextField(null=True, blank=True)
    created_at        = models.DateTimeField(auto_now_add=True)
    updated_at        = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'towers'

    def __str__(self):
        return self.tower_unique_id
