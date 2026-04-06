from django.db import transaction
from ..models import TechnicianProfile, TechnicianSkill, TechnicianServiceLicense
import os
def finalize_registration(*, user, validated_data):
    # 1. Pop the data as you did before
    skills_data = validated_data.pop('skills')
    category_licenses_data = validated_data.pop('category_licenses', [])
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

        # 4. NEW: Handle Category-Level Licenses
        for cat_lic in category_licenses_data:
            new_license = TechnicianServiceLicense(
                technician=profile,
                service_id=cat_lic['service_id']
            )
            
            if cat_lic.get('license_file'):
                clean_name = os.path.basename(cat_lic['license_file'].name)
                new_license.license_picture.save(
                    clean_name, 
                    cat_lic['license_file'], 
                    save=False
                )
            new_license.save()

        # 5. UPDATED: Handle Skills (Clean, no licenses here!)
        for skill in skills_data:
            TechnicianSkill.objects.create(
                technician=profile,
                sub_service_id=skill['sub_service_id'],
                years_of_experience=skill['years_of_experience'],
                base_rate=skill.get('base_rate'),
                max_rate=skill.get('max_rate'),
            )
            
    return profile