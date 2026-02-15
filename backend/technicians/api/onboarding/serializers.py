from rest_framework import serializers
from ...models import TemporaryMedia, TechnicianProfile, TechnicianSkill

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
    license_media_uuid = serializers.UUIDField(required=False, allow_null=True)

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
            
            # Map license UUIDs within the skills list
            for skill in internal_data['skills']:
                l_uuid = skill.pop('license_media_uuid', None)
                if l_uuid:
                    skill['license_file'] = TemporaryMedia.objects.get(id=l_uuid).file
                else:
                    skill['license_file'] = None
                    
        except TemporaryMedia.DoesNotExist:
            raise serializers.ValidationError({"uuid_error": "One or more image UUIDs are invalid or expired."})            
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