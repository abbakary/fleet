from django.urls import include, path
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AuthTokenView,
    ChecklistItemViewSet,
    CustomerViewSet,
    InspectionCategoryViewSet,
    InspectionViewSet,
    InspectorProfileViewSet,
    VehicleAssignmentViewSet,
    VehicleViewSet,
)
from . import views_web

router = DefaultRouter()
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'inspectors', InspectorProfileViewSet, basename='inspector')
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'assignments', VehicleAssignmentViewSet, basename='assignment')
router.register(r'inspections', InspectionViewSet, basename='inspection')
router.register(r'categories', InspectionCategoryViewSet, basename='category')
router.register(r'checklist-items', ChecklistItemViewSet, basename='checklist-item')

urlpatterns = [
    # Web admin shell and partials (HTMX)
    path('app/', views_web.app_shell, name='portal-app'),
    path('app/customers/', views_web.customers_view, name='portal-customers'),
    path('app/customers/new/', views_web.customer_create, name='portal-customers-new'),
    path('app/customers/<int:pk>/edit/', views_web.customer_edit, name='portal-customers-edit'),
    path('app/customers/<int:pk>/delete/', views_web.customer_delete, name='portal-customers-delete'),

    path('app/users/', views_web.users_view, name='portal-users'),
    path('app/users/new/', views_web.user_create, name='portal-users-new'),
    path('app/users/<int:pk>/edit/', views_web.user_edit, name='portal-users-edit'),
    path('app/users/<int:pk>/delete/', views_web.user_delete, name='portal-users-delete'),

    path('app/vehicles/', views_web.vehicles_view, name='portal-vehicles'),
    path('app/vehicles/new/', views_web.vehicle_create, name='portal-vehicles-new'),
    path('app/vehicles/<int:pk>/edit/', views_web.vehicle_edit, name='portal-vehicles-edit'),
    path('app/vehicles/<int:pk>/delete/', views_web.vehicle_delete, name='portal-vehicles-delete'),

    path('app/inspectors/', views_web.inspectors_view, name='portal-inspectors'),
    path('app/inspectors/new/', views_web.inspector_create, name='portal-inspectors-new'),
    path('app/inspectors/<int:pk>/edit/', views_web.inspector_edit, name='portal-inspectors-edit'),
    path('app/inspectors/<int:pk>/delete/', views_web.inspector_delete, name='portal-inspectors-delete'),

    path('app/assignments/', views_web.assignments_view, name='portal-assignments'),
    path('app/assignments/new/', views_web.assignment_create, name='portal-assignments-new'),
    path('app/assignments/<int:pk>/edit/', views_web.assignment_edit, name='portal-assignments-edit'),
    path('app/assignments/<int:pk>/delete/', views_web.assignment_delete, name='portal-assignments-delete'),

    path('app/inspections/', views_web.inspections_view, name='portal-inspections'),
    path('app/inspections/new/', views_web.inspection_create, name='portal-inspections-new'),
    path('app/inspections/<int:pk>/edit/', views_web.inspection_edit, name='portal-inspections-edit'),
    path('app/inspections/<int:pk>/delete/', views_web.inspection_delete, name='portal-inspections-delete'),

    path('app/categories/', views_web.categories_view, name='portal-categories'),
    path('app/categories/new/', views_web.category_create, name='portal-categories-new'),
    path('app/categories/<int:pk>/edit/', views_web.category_edit, name='portal-categories-edit'),
    path('app/categories/<int:pk>/delete/', views_web.category_delete, name='portal-categories-delete'),

    path('app/checklist-items/new/', views_web.checklist_item_create, name='portal-checklist-items-new'),
    path('app/checklist-items/<int:pk>/edit/', views_web.checklist_item_edit, name='portal-checklist-items-edit'),
    path('app/checklist-items/<int:pk>/delete/', views_web.checklist_item_delete, name='portal-checklist-items-delete'),

    # API
    path('auth/token/', AuthTokenView.as_view(), name='auth-token'),
    path('', include(router.urls)),
]
