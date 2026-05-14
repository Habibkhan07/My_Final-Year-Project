"""Persona registry.

Each persona is a Python package (e.g. ``chatbot.personas.dispute``) whose
module-level code calls ``register(MyPersona())`` once at import time. The
import is triggered from ``chatbot.apps.ChatbotConfig.ready()``.

Adding a new persona is a folder-add: write the package, add one import line
to ``ready()``. No edits to ``chatbot.services`` or ``chatbot.views``.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    # Protocol lives in services.ports; import only for type-checking to
    # avoid a circular import at runtime (services imports from personas
    # indirectly via the registry).
    from chatbot.services.ports import Persona


class PersonaAlreadyRegistered(Exception):
    pass


class PersonaNotFound(Exception):
    pass


_REGISTRY: dict[str, "Persona"] = {}


def register(persona: "Persona") -> None:
    if persona.key in _REGISTRY:
        raise PersonaAlreadyRegistered(persona.key)
    _REGISTRY[persona.key] = persona


def unregister(key: str) -> None:
    """Test-only: clear a registration so fixtures can re-register."""
    _REGISTRY.pop(key, None)


def get(key: str) -> "Persona":
    if key not in _REGISTRY:
        raise PersonaNotFound(key)
    return _REGISTRY[key]


def all_personas() -> list["Persona"]:
    return list(_REGISTRY.values())
