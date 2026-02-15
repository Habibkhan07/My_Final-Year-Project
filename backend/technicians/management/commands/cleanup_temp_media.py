from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from technicians.models import TemporaryMedia
import os

class Command(BaseCommand):
    help = 'Deletes temporary media uploads older than 24 hours'

    def handle(self, *args, **options):
        # 1. Define the expiration threshold (24 hours ago)
        threshold = timezone.now() - timedelta(hours=24)
        
        # 2. Find all 'orphaned' records
        orphaned_media = TemporaryMedia.objects.filter(uploaded_at__lt=threshold)
        count = orphaned_media.count()

        for media in orphaned_media:
            # 3. Physically delete the file from your laptop/server disk
            if media.file and os.path.isfile(media.file.path):
                os.remove(media.file.path)
            
            # 4. Delete the database record
            media.delete()

        self.stdout.write(self.style.SUCCESS(f'Successfully deleted {count} orphaned files.'))