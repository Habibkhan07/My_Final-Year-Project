from django.db import transaction
from ..models import TechnicianProfile, TechnicianSkill
import os
def finalize_registration(*, user, validated_data):
    # 1. Pop the data as you did before
    skills_data = validated_data.pop('skills')
    profile_file = validated_data.pop('profile_picture_file')
    cnic_file = validated_data.pop('cnic_picture_file')
    
    first_name = validated_data.pop('first_name')
    last_name = validated_data.pop('last_name')

    with transaction.atomic():
        # 2. Update core user details
        user.first_name = first_name
        user.last_name = last_name
        user.save()

        # 3. Create the profile WITHOUT the images first
        profile = TechnicianProfile(
            user=user,
            **validated_data
        )

        # 4. Explicitly migrate the binary data to trigger upload_to logic
        if profile_file:
            # This triggers the 'tech_profiles/' path defined in your model
            clean_name = os.path.basename(profile_file.name)
            profile.profile_picture.save(clean_name, profile_file, save=False)
            
        if cnic_file:
            clean_name = os.path.basename(cnic_file.name)
            # This triggers the 'tech_docs/cnic/' path defined in your model
            profile.cnic_front_image.save(clean_name, cnic_file, save=False)

        profile.save()

        # 5. Handle skills and license migration
        for skill in skills_data:
            new_skill = TechnicianSkill(
                technician=profile,
                sub_service_id=skill['sub_service_id'],
                years_of_experience=skill['years_of_experience'],
            )
            
            # Explicitly save the license to 'tech_docs/license_picture/'
            if skill.get('license_file'):
                clean_name = os.path.basename(skill['license_file'].name)
                new_skill.license_picture.save(
                    clean_name, 
                    skill['license_file'], 
                    save=False
                )
            
            new_skill.save()
            
    return profile