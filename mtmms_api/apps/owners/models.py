from django.db import models


class Owner(models.Model):
    name       = models.CharField(max_length=255)
    type       = models.CharField(max_length=50, default='government', null=True, blank=True)
    phone      = models.CharField(max_length=20, null=True, blank=True)
    email      = models.EmailField(null=True, blank=True)
    address    = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'owners'

    def __str__(self):
        return self.name
