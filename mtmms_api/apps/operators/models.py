from django.db import models


class Operator(models.Model):
    name           = models.CharField(max_length=255)
    short_name     = models.CharField(max_length=50, null=True, blank=True)
    phone          = models.CharField(max_length=20, null=True, blank=True)
    email          = models.EmailField(null=True, blank=True)
    contact_person = models.CharField(max_length=255, null=True, blank=True)
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'operators'

    def __str__(self):
        return self.name
