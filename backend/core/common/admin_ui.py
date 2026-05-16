"""Admin UX helpers — shared across every app's admin.py.

Two reasons this lives in core.common rather than each app:

* Visual consistency: every status pill, money cell, and thumbnail
  renders the same way regardless of which feature owns the model.
  A reviewer scanning the admin sidebar sees one design language.
* DRY: the alternative is 10 copies of ``format_html`` with subtly
  different inline CSS, and they would drift the first time anyone
  edits one.

Everything here is presentation-only — no business logic, no DB
reads. Safe to import from any admin.py without circular-import risk.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from decimal import Decimal
from typing import Iterable, Mapping, Optional

from django.utils.html import format_html
from django.utils.safestring import SafeString, mark_safe


# Tone palette — same five tones the Flutter UI uses (positive /
# warning / negative / neutral / info) so admin and app match.
_TONE_STYLES: Mapping[str, str] = {
    'positive': 'background:#dcfce7;color:#166534;border:1px solid #86efac;',
    'warning':  'background:#fef3c7;color:#92400e;border:1px solid #fcd34d;',
    'negative': 'background:#fee2e2;color:#991b1b;border:1px solid #fca5a5;',
    'neutral':  'background:#e5e7eb;color:#374151;border:1px solid #d1d5db;',
    'info':     'background:#dbeafe;color:#1e40af;border:1px solid #93c5fd;',
}


_PILL_BASE = (
    'display:inline-block;'
    'padding:2px 8px;'
    'border-radius:10px;'
    'font-size:11px;'
    'font-weight:600;'
    'letter-spacing:0.02em;'
    'text-transform:uppercase;'
    'white-space:nowrap;'
)


def pill(label: str, tone: str = 'neutral') -> SafeString:
    """Render a coloured status pill for list_display cells.

    ``tone`` falls back to ``neutral`` for any unknown key so a
    forgotten mapping degrades gracefully instead of 500-ing.
    """
    style = _PILL_BASE + _TONE_STYLES.get(tone, _TONE_STYLES['neutral'])
    return format_html('<span style="{}">{}</span>', style, label)


def money_rs(value) -> str:
    """Format a Decimal/int/None as ``Rs. 1,234`` (or em-dash if missing).

    Whole-rupee on integers; two-decimal on paisa fractions. Matches the
    Flutter ``formatRs`` policy so admin and app numbers line up.
    """
    if value is None:
        return '—'
    if isinstance(value, Decimal):
        # Whole-rupee shortcut when no paisa
        if value == value.to_integral_value():
            return f'Rs. {int(value):,}'
        return f'Rs. {value:,.2f}'
    try:
        return f'Rs. {int(value):,}'
    except (TypeError, ValueError):
        return str(value)


def thumb(image_field, size: int = 48, hover_zoom: bool = False) -> SafeString:
    """Tiny rounded thumbnail for ImageField list_display cells.

    Returns em-dash placeholder when the field is empty so the column
    still renders rather than collapsing the row layout.
    """
    if not image_field:
        return format_html('<span style="color:#9ca3af;">{}</span>', '—')
    style = (
        f'width:{size}px;height:{size}px;'
        'object-fit:cover;border-radius:8px;'
        'box-shadow:0 1px 2px rgba(0,0,0,0.1);'
    )
    cls = 'fx-hover-zoom' if hover_zoom else ''
    return format_html(
        '<img src="{}" class="{}" style="{}"/>',
        image_field.url, cls, style,
    )


def lightbox_thumb(
    image_field,
    *,
    size: int = 80,
    alt: str = '',
) -> SafeString:
    """Click-to-zoom thumbnail. Pure CSS via ``:target`` — no JS.

    Markup pattern: an anchor wraps the small image, navigating to
    ``#fx-lb-<unique>``. A sibling overlay element matches that id via
    ``:target`` and blows up to full viewport. Click the backdrop or
    the close × to navigate back to ``#``, hiding the overlay.

    Returns the anchor + overlay markup glued together; callers drop
    it straight into any HTML context. Multiple thumbs on the same
    page get unique ids via ``uuid.uuid4()``.
    """
    if not image_field:
        return format_html('<span style="color:#9ca3af;">{}</span>', '—')

    lid = 'fx-lb-' + uuid.uuid4().hex[:10]
    thumb_style = (
        f'width:{size}px;height:{size}px;'
        'object-fit:cover;border-radius:8px;'
        'box-shadow:0 1px 3px rgba(0,0,0,0.15);'
        'cursor:zoom-in;transition:transform 0.1s;'
    )
    return format_html(
        '<a class="fx-lightbox-link" href="#{lid}">'
        '<img src="{url}" alt="{alt}" style="{ts}"/></a>'
        '<a class="fx-lightbox" id="{lid}" href="#" aria-hidden="true">'
        '<span class="fx-lightbox-close" aria-label="Close">×</span>'
        '<img src="{url}" alt="{alt}"/></a>',
        lid=lid, url=image_field.url, alt=alt, ts=thumb_style,
    )


@dataclass(frozen=True)
class ImageGridItem:
    """One cell in an image_grid()."""
    image_field: object         # ImageField file (has .url) or None
    caption: str
    subcaption: str = ''


def image_grid(
    items: Iterable[Optional[ImageGridItem]],
    *,
    size: int = 140,
    empty_message: str = 'No images uploaded.',
) -> SafeString:
    """Render a side-by-side grid of captioned, clickable thumbnails.

    Used at the top of TechnicianProfile / SupportTicket / quick-action
    confirmation pages so the supervisor sees every relevant photo
    without scrolling. Each thumbnail opens via the shared lightbox.

    None items are skipped silently so callers can pass conditional
    lists like ``[profile_item, cnic_item] + license_items``.
    """
    valid = [i for i in items if i is not None and i.image_field]
    if not valid:
        return format_html(
            '<div class="fx-img-grid-empty">{}</div>',
            empty_message,
        )

    cells: list[str] = []
    for item in valid:
        lid = 'fx-lb-' + uuid.uuid4().hex[:10]
        cell_style = (
            f'width:{size}px;'
            'display:flex;flex-direction:column;gap:6px;'
        )
        thumb_style = (
            f'width:{size}px;height:{size}px;'
            'object-fit:cover;border-radius:10px;'
            'box-shadow:0 2px 6px rgba(0,0,0,0.10);'
            'cursor:zoom-in;'
        )
        cell = format_html(
            '<div class="fx-img-grid-cell" style="{cs}">'
            '<a class="fx-lightbox-link" href="#{lid}">'
            '<img src="{url}" style="{ts}"/></a>'
            '<div class="fx-img-grid-caption">{cap}</div>'
            '{sub}'
            '<a class="fx-lightbox" id="{lid}" href="#" aria-hidden="true">'
            '<span class="fx-lightbox-close" aria-label="Close">×</span>'
            '<img src="{url}"/></a>'
            '</div>',
            cs=cell_style,
            lid=lid,
            url=item.image_field.url,
            ts=thumb_style,
            cap=item.caption,
            sub=format_html(
                '<div class="fx-img-grid-subcaption">{}</div>',
                item.subcaption,
            ) if item.subcaption else '',
        )
        cells.append(str(cell))

    return mark_safe(
        '<div class="fx-img-grid">' + ''.join(cells) + '</div>'
    )


def kvs(items: Mapping[str, object]) -> SafeString:
    """Render a tight key/value block — handy in change-view readonly summaries."""
    rows = ''.join(
        f'<tr><td style="padding:2px 12px 2px 0;color:#6b7280;">{k}</td>'
        f'<td style="padding:2px 0;font-weight:500;">{v}</td></tr>'
        for k, v in items.items()
    )
    return format_html('<table style="font-size:12px;">{}</table>', SafeString(rows))


def truncate(text: str | None, limit: int = 60) -> str:
    if not text:
        return '—'
    text = str(text)
    return text if len(text) <= limit else text[: limit - 1] + '…'
