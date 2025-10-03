"""URL configuration for fleet_manager project."""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from portal import views_web

urlpatterns = [
    # Custom admin portal (templates-based)
    path('admin/', views_web.app_shell, name='portal-admin'),
    # Keep Django admin accessible at a different path
    path('django-admin/', admin.site.urls),
    # Django auth (login/logout, password views)
    path('accounts/', include('django.contrib.auth.urls')),
    path('api/', include('portal.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
