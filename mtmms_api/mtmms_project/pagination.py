"""
Laravel-compatible pagination class for Django REST Framework.
Mirrors Laravel's pagination structure:
{
    "data": [...],
    "total": 12,
    "per_page": 50,
    "current_page": 1,
    "last_page": 1,
    "next_page_url": null,
    "prev_page_url": null,
    "results": [...]  // DRF compatibility
}
"""

from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class LaravelCompatiblePagination(PageNumberPagination):
    page_size = 50
    page_size_query_param = 'per_page'
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response({
            'data':          data,
            'results':       data,
            'count':         self.page.paginator.count,
            'total':         self.page.paginator.count,
            'current_page':  self.page.number,
            'per_page':      self.get_page_size(self.request),
            'last_page':     self.page.paginator.num_pages,
            'next':          self.get_next_link(),
            'previous':      self.get_previous_link(),
            'next_page_url': self.get_next_link(),
            'prev_page_url': self.get_previous_link(),
        })
