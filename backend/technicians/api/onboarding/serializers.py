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
    """Deserializes skill data from JSON"""
    sub_service_id = serializers.IntegerField()
    years_of_experience = serializers.IntegerField(min_value=0)

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
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    city = serializers.ChoiceField(choices=TechnicianProfile.CITY_CHOICES)
    cnic_number = serializers.CharField(max_length=15)
    experience_years = serializers.IntegerField(min_value=0)
    bio = serializers.CharField()
    category_licenses = CategoryLicenseInputSerializer(many=True, required=False)
    profile_picture_uuid = serializers.UUIDField()
    cnic_picture_uuid = serializers.UUIDField()
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