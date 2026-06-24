"""URL routes for the chatbot framework.

Mounted at /api/chat/ in core/urls.py. Routes are persona-agnostic —
adding a new persona requires zero edits here; the persona_key in the
``start/`` URL routes to the appropriate plugin via the registry.
"""
from django.urls import path

from chatbot import views

#This is a comnent
# This is a comment

urlpatterns = [
    # Open or resume a conversation with the named persona.
    # Example: POST /api/chat/dispute/start/
    path(
        "<str:persona_key>/start/",
        views.start_view,
        name="chat-start",
    ),

    # Resource paths on the conversation itself.
    path(
        "conversations/<int:conversation_id>/",
        views.get_view,
        name="chat-get",
    ),
    path(
        "conversations/<int:conversation_id>/message/",
        views.message_view,
        name="chat-message",
    ),
    path(
        "conversations/<int:conversation_id>/attachments/",
        views.attachment_view,
        name="chat-attachment",
    ),
    path(
        "conversations/<int:conversation_id>/close/",
        views.close_view,
        name="chat-close",
    ),
]
