"""Canonical list of Flutter icon-asset keys for the catalog admin.

Source of truth: ``frontend/assets/icons/*.svg``. The Flutter side
resolves these keys via ``IconAssets.path()`` in
``lib/core/utils/icon_assets.dart`` per CLAUDE.md. Both sides MUST
stay in sync — add an SVG over there, then a line here, then run the
admin so the new icon shows up in the picker.

Why not directory-scan? The backend container does not have the
``frontend/`` tree mounted in production — coupling startup to a
frontend path is a deploy-graph mistake. A Python constant works in
every environment and makes the picker dropdown deterministic.

A complimentary one-off ``collectstatic`` mirrors the SVGs under
``static/catalog/icons/`` so the admin can render previews via
``{% static %}`` URLs.
"""
from __future__ import annotations


ICON_CHOICES: list[tuple[str, str]] = [
    ('ac_repair',    'AC Repair'),
    ('carpenter',    'Carpenter'),
    ('cleaning',     'Cleaning'),
    ('default',      'Default (fallback)'),
    ('electrician',  'Electrician'),
    ('fan',          'Ceiling Fan'),
    ('freon_gas',    'Freon Gas Refill'),
    ('geyser',       'Geyser'),
    ('kitchen',      'Kitchen / Stove'),
    ('painter',      'Painter'),
    ('pest_control', 'Pest Control'),
    ('pipe_leak',    'Pipe Leak'),
    ('plumbing',     'Plumbing'),
    ('sofa',         'Sofa / Upholstery'),
    ('toilet',       'Toilet / Commode'),
    ('water_pump',   'Water Pump / Motor'),
]

ICON_KEYS: frozenset[str] = frozenset(k for k, _ in ICON_CHOICES)


def icon_static_path(key: str) -> str:
    """Static URL fragment for a given icon key.

    The admin mirrors ``frontend/assets/icons/*.svg`` under
    ``static/catalog/icons/`` (a deploy-step / collectstatic concern,
    not a runtime symlink) so the picker can render previews via the
    standard ``{% static %}`` mechanism.
    """
    return f'catalog/icons/{key}.svg'
