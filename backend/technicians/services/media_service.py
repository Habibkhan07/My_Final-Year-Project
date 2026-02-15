from ..models import TemporaryMedia

def save_temporary_media(*, file_obj):
    """
    Phase 1: Directly implements your robust staging logic.
    Stores binary stream in TemporaryMedia and returns the object (with its UUID).
    """
    return TemporaryMedia.objects.create(file=file_obj)