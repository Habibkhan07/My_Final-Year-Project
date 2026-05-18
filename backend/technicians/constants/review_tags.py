"""Predefined customer review tag vocabulary.

Two buckets keyed by rating polarity:

* ``POSITIVE_TAGS`` — surfaced when the customer's star rating is **≥ 4**.
  Frames the follow-up question as "what made it great?"
* ``CONSTRUCTIVE_TAGS`` — surfaced when the rating is **≤ 3**. Frames the
  follow-up as "what went wrong?"

Wire contract: the persisted ``Review.tags`` column stores **keys only**
(short snake_case identifiers), never the display labels. Reasons:

* Copy edits don't require a data migration.
* Localisation in v2 maps key → translated label at the serializer; the
  database stays language-agnostic.
* Analytics aggregation across rephrased copy stays stable
  ("on_time" yesterday is "on_time" tomorrow even if the label flips
  from "On time" to "Punctual").

``ALL_TAG_KEYS`` is the validation gate at the serializer layer.
Anything the client sends outside this set is rejected with the
standard ``validation_error`` envelope — prevents arbitrary
client-injected strings polluting the JSON column.

Editing this file:
1. Add new entries to the appropriate bucket.
2. ``ALL_TAG_KEYS`` rebuilds automatically.
3. Restart the Django/Celery process — no migration needed.
4. The FE picks up the new list on the next call to
   ``GET /api/bookings/<id>/review/`` (which echoes the tag dictionary
   for that booking's rating-bucket choice).
"""
from __future__ import annotations

from typing import Final, TypedDict


class PredefinedTag(TypedDict):
    key: str
    label: str


POSITIVE_TAGS: Final[list[PredefinedTag]] = [
    {"key": "on_time",      "label": "On time"},
    {"key": "professional", "label": "Professional"},
    {"key": "quality_work", "label": "Quality work"},
    {"key": "clean",        "label": "Clean"},
    {"key": "polite",       "label": "Polite"},
    {"key": "fair_price",   "label": "Fair price"},
]

CONSTRUCTIVE_TAGS: Final[list[PredefinedTag]] = [
    {"key": "late",       "label": "Late"},
    {"key": "messy",      "label": "Messy"},
    {"key": "rude",       "label": "Rude"},
    {"key": "overpriced", "label": "Overpriced"},
    {"key": "incomplete", "label": "Incomplete work"},
    {"key": "unsafe",     "label": "Unsafe"},
]

#: Validation set. Frozen so accidental mutation at import-time fails loudly.
ALL_TAG_KEYS: Final[frozenset[str]] = frozenset(
    t["key"] for t in (*POSITIVE_TAGS, *CONSTRUCTIVE_TAGS)
)


def tags_for_rating(rating: int) -> list[PredefinedTag]:
    """Return the chip vocabulary that matches a star rating.

    The threshold is ``rating >= 4`` — 4 and 5 stars get the positive
    chip set, 1 through 3 get the constructive set. Lifted into a
    helper so the policy lives in one place (the serializer and any
    future debug/admin view both call this).
    """
    return POSITIVE_TAGS if rating >= 4 else CONSTRUCTIVE_TAGS
