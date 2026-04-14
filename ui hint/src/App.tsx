import { useState } from "react";
import ProfileScreen from "./screens/ProfileScreen";
import SelectTimeSheet from "./components/SelectTimeSheet";
import ReviewBookingSheet from "./components/ReviewBookingSheet";
import { MOCK_TECHNICIAN } from "./constants";

export default function App() {
  const [isSelectTimeOpen, setIsSelectTimeOpen] = useState(false);
  const [isReviewOpen, setIsReviewOpen] = useState(false);
  const [booking, setBooking] = useState({
    date: "13",
    time: "10:00 AM",
    address: "Home (Default Address)",
    totalPrice: 1500,
  });

  const handleSelectTime = () => {
    setIsSelectTimeOpen(true);
  };

  const handleTimeSelected = (date: string, time: string) => {
    setBooking((prev) => ({ ...prev, date, time }));
    setIsSelectTimeOpen(false);
    setIsReviewOpen(true);
  };

  const handleConfirmBooking = () => {
    alert("Booking Confirmed!");
    setIsReviewOpen(false);
  };

  return (
    <div className="min-h-screen bg-surface">
      <ProfileScreen 
        technician={MOCK_TECHNICIAN} 
        onSelectTime={handleSelectTime} 
      />

      <SelectTimeSheet
        isOpen={isSelectTimeOpen}
        onClose={() => setIsSelectTimeOpen(false)}
        onContinue={handleTimeSelected}
      />

      <ReviewBookingSheet
        isOpen={isReviewOpen}
        onClose={() => setIsReviewOpen(false)}
        booking={booking}
        onConfirm={handleConfirmBooking}
      />
    </div>
  );
}
