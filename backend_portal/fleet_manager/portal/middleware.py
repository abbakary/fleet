from __future__ import annotations

from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.utils.deprecation import MiddlewareMixin


class DevCorsMiddleware(MiddlewareMixin):
    """Lightweight CORS for development only.

    - Applies only when settings.DEBUG is True
    - Applies only to paths starting with /api/
    - Adds Access-Control-Allow-* headers
    - Responds to OPTIONS preflight with 204
    """

    def process_request(self, request: HttpRequest):
        if not settings.DEBUG:
            return None
        if not request.path.startswith("/api/"):
            return None
        if request.method == "OPTIONS":
            response = HttpResponse(status=204)
            self._apply_headers(response)
            return response
        return None

    def process_response(self, request: HttpRequest, response: HttpResponse):
        if not settings.DEBUG:
            return response
        if request.path.startswith("/api/"):
            self._apply_headers(response)
        return response

    @staticmethod
    def _apply_headers(response: HttpResponse) -> None:
        response["Access-Control-Allow-Origin"] = "*"
        response["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
        response["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
        response["Access-Control-Max-Age"] = "86400"
