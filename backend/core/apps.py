from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "core"
    verbose_name = "Core — Event Dispatch Hub"

    def ready(self) -> None:
        # Replace Django's default app-grouped sidebar with task-oriented
        # tabs (Operations / People / Catalog / Reviews). Lives at module
        # ``core.admin_site``; idempotent so dev autoreload is safe.
        from core.admin_site import install_grouped_sidebar
        install_grouped_sidebar()
