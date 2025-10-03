from rest_framework.permissions import BasePermission

from rest_framework.permissions import BasePermission

from .models import PortalUser


def get_portal_profile(user):
    try:
        return user.portal_profile
    except AttributeError:
        return None


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        profile = get_portal_profile(request.user)
        return bool(profile and profile.role == PortalUser.ROLE_ADMIN)


class IsInspector(BasePermission):
    def has_permission(self, request, view):
        profile = get_portal_profile(request.user)
        return bool(profile and profile.role == PortalUser.ROLE_INSPECTOR)


class IsCustomer(BasePermission):
    def has_permission(self, request, view):
        profile = get_portal_profile(request.user)
        return bool(profile and profile.role == PortalUser.ROLE_CUSTOMER)


class IsInspectorOrAdmin(BasePermission):
    def has_permission(self, request, view):
        profile = get_portal_profile(request.user)
        return bool(profile and profile.role in [PortalUser.ROLE_INSPECTOR, PortalUser.ROLE_ADMIN])


class IsCustomerOrAdmin(BasePermission):
    def has_permission(self, request, view):
        profile = get_portal_profile(request.user)
        return bool(profile and profile.role in [PortalUser.ROLE_CUSTOMER, PortalUser.ROLE_ADMIN])
