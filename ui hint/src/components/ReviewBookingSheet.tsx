import { Clock, Wallet, MapPin, Map as MapIcon, Lock, X } from "lucide-react";
import ModalBottomSheet from "./ModalBottomSheet";
import { motion } from "motion/react";

interface ReviewBookingSheetProps {
  isOpen: boolean;
  onClose: () => void;
  booking: {
    date: string;
    time: string;
    address: string;
    totalPrice: number;
  };
  onConfirm: () => void;
}

export default function ReviewBookingSheet({ isOpen, onClose, booking, onConfirm }: ReviewBookingSheetProps) {
  return (
    <ModalBottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title="Review Booking"
      footer={
        <div className="flex items-center gap-4">
          <button 
            onClick={onClose}
            className="flex flex-col items-center justify-center text-on-surface-variant px-4 py-2 hover:opacity-90 transition-opacity active:scale-[0.98]"
          >
            <X className="w-6 h-6" />
            <span className="font-semibold text-[10px] uppercase mt-1">Cancel</span>
          </button>
          <button 
            onClick={onConfirm}
            className="flex-1 flex items-center justify-center gap-3 bg-gradient-to-br from-primary to-primary-container text-white rounded-xl px-8 py-4 shadow-lg shadow-primary/20 hover:opacity-90 transition-all active:scale-[0.98]"
          >
            <Lock className="w-5 h-5" />
            <span className="font-semibold text-base">Confirm & Lock</span>
          </button>
        </div>
      }
    >
      <div className="flex flex-col gap-8">
        {/* Summary List */}
        <section className="flex flex-col gap-5">
          {[
            { icon: <Clock className="w-6 h-6" />, label: "Date & Time", value: `Tue ${booking.date}th, ${booking.time}` },
            { icon: <Wallet className="w-6 h-6" />, label: "Total (Fixed Price)", value: `Rs. ${booking.totalPrice.toLocaleString()}` },
            { icon: <MapPin className="w-6 h-6" />, label: "Service Address", value: booking.address },
          ].map((item, index) => (
            <div 
              key={index}
              className="flex items-start gap-5 p-4 rounded-xl bg-surface-container-low/50 hover:bg-surface-container-low transition-colors group"
            >
              <div className="p-3 bg-surface-container-lowest rounded-xl shadow-sm text-primary">
                {item.icon}
              </div>
              <div className="flex flex-col">
                <span className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider mb-1">
                  {item.label}
                </span>
                <span className="text-on-surface text-base font-bold font-headline">
                  {item.value}
                </span>
              </div>
            </div>
          ))}
        </section>

        {/* Map Preview */}
        <div className="relative h-40 w-full rounded-2xl overflow-hidden shadow-inner group">
          <img 
            className="w-full h-full object-cover grayscale opacity-80 group-hover:grayscale-0 transition-all duration-500" 
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuDM3SxdvWZLgtsL7EvuIZSkCtQ0gdhSR3-xlH3CaDFVfvvgNykLJ0E9JvhpRLHaAb9iIdfH8FbTPhejjMQYuadD46ier0JrcGIX4BiZJWHuYblnWcnfbSEh2fdSYTUBC8e4VQJsXopFwNs8rEBl6pJbGcQsDqJ9obHUGFKWxlAcP37fdY-OkSSM6GEJFkShHZT6OKYjtytH220ImqZVGFdBFKYgfNbuP5pssBec54MOm6CLT19u9AFXO10O3FAN82si1wYy3wEo8Uw"
            alt="Map Preview"
            referrerPolicy="no-referrer"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-white/40 to-transparent" />
          <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-md px-3 py-1.5 rounded-full flex items-center gap-2 border border-outline-variant/10">
            <MapIcon className="w-3 h-3 text-primary" />
            <span className="text-[10px] font-bold uppercase tracking-widest text-on-surface">
              Live Location Active
            </span>
          </div>
        </div>

        {/* Legal Note */}
        <p className="text-on-surface-variant text-[11px] leading-relaxed text-center px-4">
          By tapping the button below, you agree to our <span className="text-primary font-semibold">Terms of Service</span> and authorize the hold for this transaction on your selected card.
        </p>
      </div>
    </ModalBottomSheet>
  );
}
