export interface Technician {
  id: string;
  name: string;
  photoUrl: string;
  rating: number;
  jobCount: number;
  specialty: string;
  experienceYears: number;
  inspectionFee: number;
  discountPercent?: number;
  bio: string;
}

export interface Booking {
  technicianId: string;
  date: string;
  time: string;
  address: string;
  totalPrice: number;
}
