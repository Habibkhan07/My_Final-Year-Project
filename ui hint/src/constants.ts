import { Technician } from "./types";

export const MOCK_TECHNICIAN: Technician = {
  id: "1",
  name: "Zain Ahmed",
  photoUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuB1th_rucUN_zCzn_CmC2WiT8NQ6IaBQgdXuY9hOUYBl4Bpfzrhwk6y0qHY76HBjRvFi9YGxJbO-gun8uQoAIOVqvYsCJ4aK27Ye1wDfDjq_CbcrhXrZBNXQiEwW0Blq7exNnvwPhAiMcmzVNi2BgzC65T1Rb4Fr15-iEY9HelmBw37X4LAxlchn1Cw9cbIO7WSbxTglVKl8OS-5zFHv8ENmSbCIMHsrs6HGpd3Wuz4ch-uk3PE5bLYKE46eXPPPTQh-W7EjFs50zw",
  rating: 4.97,
  jobCount: 120,
  specialty: "Certified HVAC specialist",
  experienceYears: 8,
  inspectionFee: 1500,
  discountPercent: 20,
  bio: "Certified HVAC specialist with over 8 years of experience in residential maintenance and repair. Known for precision and efficient service delivery."
};

export const TIME_SLOTS = {
  morning: ["09:00 AM", "10:00 AM", "11:00 AM", "11:30 AM"],
  afternoon: ["02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM", "05:30 PM"]
};

export const DATES = [
  { day: "Mon", date: "12" },
  { day: "Tue", date: "13" },
  { day: "Wed", date: "14" },
  { day: "Thu", date: "15" },
  { day: "Fri", date: "16" },
  { day: "Sat", date: "17" },
];
