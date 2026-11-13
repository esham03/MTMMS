"""
Tower model — replaces Laravel Tower.php
Relationships:
  - BelongsTo Area (area → taluka → constituency → district)
  - BelongsTo Owner
  - BelongsToMany Operator (through TowerOperator pivot)
  - HasMany RentPayment
  - HasMany TowerRentRenewal
"""

from django.db import models
from django.conf import settings
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
    tower_unique_id       = models.CharField(max_length=100, unique=True)
    area                  = models.ForeignKey(Area, on_delete=models.SET_NULL, null=True, blank=True, related_name='towers')
    owner                 = models.ForeignKey(Owner, on_delete=models.SET_NULL, null=True, blank=True, related_name='towers')
    operators             = models.ManyToManyField(Operator, through=TowerOperator, related_name='towers', blank=True)
    land_type             = models.CharField(max_length=50)
    height                = models.FloatField(null=True, blank=True)
    width                 = models.FloatField(null=True, blank=True)
    frequency             = models.CharField(max_length=100, null=True, blank=True)
    status                = models.CharField(max_length=50, null=True, blank=True, default='active')
    monthly_rent          = models.FloatField(null=True, blank=True)
    yearly_rent           = models.FloatField(null=True, blank=True)
    rent_cycle_years      = models.IntegerField(null=True, blank=True, default=5)
    installation_date     = models.DateField(null=True, blank=True)
    rent_start_date       = models.DateField(null=True, blank=True)
    rent_due_date         = models.DateField(null=True, blank=True)

    # ── Rent Escalation & Agreement Configuration ──
    escalation_enabled    = models.BooleanField(default=True)
    escalation_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=10.00)
    agreement_start_date  = models.DateField(null=True, blank=True)
    agreement_end_date    = models.DateField(null=True, blank=True)
    next_renewal_date     = models.DateField(null=True, blank=True)
    last_revised_rent     = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    last_escalation_date  = models.DateField(null=True, blank=True)

    address               = models.TextField(null=True, blank=True)
    latitude              = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude             = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    remarks               = models.TextField(null=True, blank=True)
    created_at            = models.DateTimeField(auto_now_add=True)
    updated_at            = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'towers'

    def __str__(self):
        return self.tower_unique_id


class TowerRentRenewal(models.Model):
    """
    Renewal and rent revision history for mobile towers.
    Maintains an audit trail of previous rent, escalation %, increase amount,
    new rent, agreement periods, approving administrator, and manual overrides.
    """
    STATUS_CHOICES = [
        ('confirmed', 'Confirmed'),
        ('overridden', 'Confirmed with Override'),
        ('cancelled', 'Cancelled'),
    ]

    tower                     = models.ForeignKey(Tower, on_delete=models.CASCADE, related_name='renewals')
    renewal_reference         = models.CharField(max_length=100, unique=True)
    previous_yearly_rent      = models.DecimalField(max_digits=12, decimal_places=2)
    escalation_percentage     = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    increase_amount           = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    new_yearly_rent           = models.DecimalField(max_digits=12, decimal_places=2)
    calculated_yearly_rent    = models.DecimalField(max_digits=12, decimal_places=2)
    is_manual_override        = models.BooleanField(default=False)
    manual_override_reason    = models.TextField(null=True, blank=True)
    prev_agreement_start_date = models.DateField(null=True, blank=True)
    prev_agreement_end_date   = models.DateField(null=True, blank=True)
    new_agreement_start_date  = models.DateField(null=True, blank=True)
    new_agreement_end_date    = models.DateField(null=True, blank=True)
    effective_date            = models.DateField()
    renewal_date              = models.DateField(auto_now_add=True)
    renewal_cycle_years       = models.IntegerField(default=5)
    status                    = models.CharField(max_length=50, choices=STATUS_CHOICES, default='confirmed')
    approved_by               = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='approved_renewals',
        db_constraint=False
    )
    approved_by_name          = models.CharField(max_length=255, null=True, blank=True)
    remarks                   = models.TextField(null=True, blank=True)
    created_at                = models.DateTimeField(auto_now_add=True)
    updated_at                = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tower_rent_renewals'
        ordering = ['-effective_date', '-created_at']

    @property
    def reference_number(self):
        return self.renewal_reference

    @property
    def previous_annual_rent(self):
        return self.previous_yearly_rent

    @property
    def new_annual_rent(self):
        return self.new_yearly_rent

    @property
    def is_escalation_applied(self):
        return self.increase_amount > 0 or (self.escalation_percentage > 0 and not self.is_manual_override)

    @property
    def override_reason(self):
        return self.manual_override_reason

    def __str__(self):
        return f"{self.renewal_reference} — Tower {self.tower.tower_unique_id} (₹{self.new_yearly_rent})"
