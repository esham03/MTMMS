"""
Location models — District → Constituency → Taluka → Area
Uses existing MySQL tables (districts, constituencies, talukas, areas)
Replaces Laravel's District/Constituency/Taluka/Area models
"""

from django.db import models


class District(models.Model):
    name       = models.CharField(max_length=150)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'districts'

    def __str__(self):
        return self.name


class Constituency(models.Model):
    district   = models.ForeignKey(District, on_delete=models.RESTRICT, related_name='constituencies')
    name       = models.CharField(max_length=150)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'constituencies'

    def __str__(self):
        return self.name


class Taluka(models.Model):
    constituency = models.ForeignKey(Constituency, on_delete=models.RESTRICT, related_name='talukas')
    name         = models.CharField(max_length=150)
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'talukas'

    def __str__(self):
        return self.name


class Area(models.Model):
    taluka     = models.ForeignKey(Taluka, on_delete=models.RESTRICT, related_name='areas')
    name       = models.CharField(max_length=150)
    pincode    = models.CharField(max_length=10, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'areas'
        unique_together = [['taluka', 'name']]

    def __str__(self):
        return self.name
