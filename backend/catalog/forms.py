"""Admin form widgets for the catalog.

These exist purely to make the catalog admin friendlier for non-
technical operators. Backed-store shapes are unchanged — only the
admin input rendering differs.
"""
from __future__ import annotations

from django import forms

from catalog.icon_choices import ICON_CHOICES, ICON_KEYS
from catalog.models import Service, SubService


class IconRadioWidget(forms.RadioSelect):
    """Renders each icon as a visual tile with its SVG preview.

    SVGs are served from ``static/catalog/icons/{key}.svg`` (a mirror
    of ``frontend/assets/icons/`` populated via ``collectstatic``).
    """
    template_name = 'admin/catalog/icon_radio.html'


class IconNameField(forms.ChoiceField):
    """Validated dropdown over ``ICON_CHOICES``.

    Empty string is allowed (renders as "— None —") because
    ``icon_name`` is ``null=True, blank=True`` on the model.
    """

    def __init__(self, *args, **kwargs):
        kwargs.setdefault('choices', [('', '— None —')] + ICON_CHOICES)
        kwargs.setdefault('widget', IconRadioWidget)
        kwargs.setdefault('required', False)
        kwargs.setdefault(
            'help_text',
            'Maps to ``frontend/assets/icons/{key}.svg`` on the Flutter side. '
            'Add a new icon there + an entry in ``catalog.icon_choices`` to '
            'extend this list.',
        )
        super().__init__(*args, **kwargs)

    def to_python(self, value):
        v = super().to_python(value)
        return v or None  # store NULL rather than ''

    def validate(self, value):
        if value and value not in ICON_KEYS:
            raise forms.ValidationError(f'Unknown icon key "{value}".')
        # don't call super().validate — its "required" check would reject ''


class CommaSeparatedTagsField(forms.CharField):
    """Bidirectional adapter: ``list[str]`` (DB) ↔ ``"a, b, c"`` (form).

    Storage stays as a ``JSONField(default=list)`` on the model. Admin
    renders the value as a comma-separated string; on save the string
    is split on commas, whitespace-stripped, and empties dropped.

    DB-agnostic — works on the project's MySQL (no Postgres ArrayField
    dependency). Zero migration.
    """

    widget = forms.TextInput(attrs={
        'size': 60,
        'placeholder': 'bijli, drip, leak',
        'style': 'width:480px;',
    })

    def __init__(self, *args, **kwargs):
        kwargs.setdefault('required', False)
        kwargs.setdefault(
            'help_text',
            'Colloquial / local-language terms customers search for. '
            'Comma-separated, e.g. "bijli, light, current" for an '
            'electrician gig. Each term is stripped of surrounding spaces.',
        )
        super().__init__(*args, **kwargs)

    def prepare_value(self, value):
        # Called on form rendering. ``value`` is the DB-stored list.
        if isinstance(value, list):
            return ', '.join(value)
        return value or ''

    def to_python(self, value):
        # Called on form clean. ``value`` is the raw textbox content.
        if not value:
            return []
        if isinstance(value, list):
            return value
        return [t.strip() for t in str(value).split(',') if t.strip()]

    def validate(self, value):
        super().validate(value)
        for tag in value:
            if len(tag) > 40:
                raise forms.ValidationError(f'Tag too long: "{tag}"')


class SubServiceAdminForm(forms.ModelForm):
    search_tags = CommaSeparatedTagsField()
    icon_name = IconNameField()

    class Meta:
        model = SubService
        fields = '__all__'


class ServiceAdminForm(forms.ModelForm):
    icon_name = IconNameField()

    class Meta:
        model = Service
        fields = '__all__'
