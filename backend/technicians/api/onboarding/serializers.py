from rest_framework import serializers
from ...models import TemporaryMedia, TechnicianProfile, TechnicianSkill
from rest_framework.exceptions import NotFound
# 1. MEDIA STAGING SERIALIZER
class MediaUploadSerializer(serializers.ModelSerializer):
    """Validates raw binary uploads and returns a UUID for tracking"""
    class Meta:
        model = TemporaryMedia
        fields = ['id', 'file']
        read_only_fields = ['id']

# 2. NESTED SKILL SERIALIZER
class SkillInputSerializer(serializers.Serializer):
    """Deserializes a single skill pick from the onboarding wizard.

    Sub-service id only. The 2026-05-17 refactor dropped
    ``years_of_experience`` (write-only legacy) and ``labor_rate`` (the
    platform sets the labor figure now via ``catalog.SubService.base_price``).
    """
    sub_service_id = serializers.IntegerField()

# 2. NEW: Handles the new Category-level uploads
class CategoryLicenseInputSerializer(serializers.Serializer):
    service_id = serializers.IntegerField()
    media_uuid = serializers.UUIDField()

# 3. THE CORE REGISTRATION SERIALIZER
class TechnicianFinalizeSerializer(serializers.Serializer):
    """
    The Complete Data Contract.
    Handles Ingress (Request) and Egress (Response) transformation.
   
    """
    # --- REQUEST DATA (Incoming JSON) ---
    # ``experience_years`` and ``bio`` were dropped in the 2026-05-17
    # onboarding refactor — see migration 0013_drop_profile_metadata
    # and ``[[project_tech_onboarding_refactor]]``. The wizard step that
    # collected them was deleted (former step 2).
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    city = serializers.ChoiceField(choices=TechnicianProfile.CITY_CHOICES)
    cnic_number = serializers.CharField(max_length=15)
    category_licenses = CategoryLicenseInputSerializer(many=True, required=False)
    profile_picture_uuid = serializers.UUIDField()
    cnic_picture_uuid = serializers.UUIDField()
    # Optional work-location coordinates. The refactor merged the
    # previously-standalone work-location capture into the onboarding
    # wizard's final step. Older clients that don't yet send these can
    # still finalize — the tech will hit the dashboard work-location
    # banner instead. ``base_latitude``/``base_longitude``/``max_travel_radius_km``
    # mirror the column names on ``TechnicianProfile`` for a clean assign.
    base_latitude = serializers.FloatField(required=False, allow_null=True)
    base_longitude = serializers.FloatField(required=False, allow_null=True)
    max_travel_radius_km = serializers.IntegerField(
        required=False, min_value=1, max_value=50,
    )
    work_address_label = serializers.CharField(
        required=False, allow_blank=True, max_length=200,
    )
    skills = SkillInputSerializer(many=True)

    

    # --- VALIDATION (Business Rules) ---
    def validate_cnic_number(self, value):
        import re
        pattern = r'^\d{5}-\d{7}-\d{1}$'
        if not re.match(pattern, value):
            raise serializers.ValidationError("Format must be 00000-0000000-0")
        return value
    
    # ADD THIS NEW VALIDATION
    def validate_skills(self, value):
        if not value or len(value) == 0:
            raise serializers.ValidationError("You must select at least one skill to register as a technician.")
        return value

    # --- REQUEST CONVERSION (JSON to Python Objects) ---
    def to_internal_value(self, data):
        """
        Senior Approach: This method 'converts' the request.
        It takes the UUIDs and finds the actual TemporaryMedia objects 
        so the Service Layer doesn't have to do it.
        """
        internal_data = super().to_internal_value(data)
        
        try:
            # We map UUIDs to actual File instances here
            internal_data['profile_picture_file'] = TemporaryMedia.objects.get(
                id=internal_data.pop('profile_picture_uuid')
            ).file
            
            internal_data['cnic_picture_file'] = TemporaryMedia.objects.get(
                id=internal_data.pop('cnic_picture_uuid')
            ).file

            # THE NEW LOGIC: Map the Category License UUIDs to Files
            for cat_license in internal_data.get('category_licenses', []):
                l_uuid = cat_license.pop('media_uuid')
                cat_license['license_file'] = TemporaryMedia.objects.get(id=l_uuid).file
            
            
                    
        except TemporaryMedia.DoesNotExist:
            raise NotFound(detail="One or more image UUIDs are invalid or expired.")            
        return internal_data

    # --- RESPONSE CONVERSION (Model to JSON) ---
    def to_representation(self, instance):
        """
        Senior Approach: Formats the response for Flutter.
        Converts internal model states into user-friendly JSON.
        """
        return {
            "profile_id": instance.id,
            "full_name": instance.user.get_full_name(),
            "status": instance.get_status_display(), # 'Pending Approval' instead of 'PENDING'
            "city": instance.get_city_display(),
            "profile_picture": instance.profile_picture.url if instance.profile_picture else None,
            "verification_status": "Documents Received",
            "joined_date": instance.user.date_joined.strftime("%Y-%m-%d")
        }