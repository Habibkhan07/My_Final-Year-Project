"""Lazy registry resolver for ``PaymentGatewayPort`` adapters.

Settings shape::

    PAYMENT_GATEWAYS = {
        'mock':     'wallet.adapters.mock_jazzcash_gateway.MockJazzCashGateway',
        'jazzcash': 'wallet.adapters.jazzcash_gateway.JazzCashGateway',  # Thu
    }
    DEFAULT_PAYMENT_GATEWAY = 'mock'

Adapter modules are imported lazily inside ``get_gateway`` so importing this
module never pulls in (e.g.) the real JazzCash HTTP client at Django startup.
Matches the lazy-factory pattern already used in
``bookings.adapters.__init__.get_default_finance_adapter``.
"""
from __future__ import annotations

from django.conf import settings
from django.utils.module_loading import import_string

from wallet.services.gateway_ports import PaymentGatewayPort


def get_gateway(name: str | None = None) -> PaymentGatewayPort:
    """Resolve a registered gateway adapter by its registry key.

    ``name=None`` → uses ``settings.DEFAULT_PAYMENT_GATEWAY``. Raises
    ``ImproperlyConfigured`` if the key is unknown — fail-loud at first
    use rather than silently falling back to a mock in production.
    """
    from django.core.exceptions import ImproperlyConfigured

    name = name or getattr(settings, 'DEFAULT_PAYMENT_GATEWAY', 'mock')
    registry = getattr(settings, 'PAYMENT_GATEWAYS', {})
    try:
        dotted_path = registry[name]
    except KeyError as exc:
        raise ImproperlyConfigured(
            f"Payment gateway '{name}' not registered in settings.PAYMENT_GATEWAYS. "
            f"Known keys: {list(registry.keys())}"
        ) from exc
    cls = import_string(dotted_path)
    return cls()
