import { Sun, Sunrise, ArrowRight } from "lucide-react";
import { DATES, TIME_SLOTS } from "../constants";
import ModalBottomSheet from "./ModalBottomSheet";
import { useState } from "react";
import { motion } from "motion/react";

interface SelectTimeSheetProps {
  isOpen: boolean;
  onClose: () => void;
  onContinue: (date: string, time: string) => void;
}

export default function SelectTimeSheet({ isOpen, onClose, onContinue }: SelectTimeSheetProps) {
  const [selectedDate, setSelectedDate] = useState("13");
  const [selectedTime, setSelectedTime] = useState("10:00 AM");

  const handleContinue = () => {
    onContinue(selectedDate, selectedTime);
  };

  return (
    <ModalBottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title="Select a Time"
      footer={
        <button 
          onClick={handleContinue}
          className="w-full flex items-center justify-center gap-3 bg-gradient-to-br from-primary to-primary-container text-white font-semibold text-base rounded-xl py-5 transition-transform duration-200 active:scale-[0.98] shadow-lg shadow-primary/20"
        >
          <span>Continue with {selectedTime}</span>
          <ArrowRight className="w-5 h-5" />
        </button>
      }
    >
      <div className="flex flex-col gap-8">
        {/* Date Strip */}
        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2">
          {DATES.map((date) => (
            <motion.button
              key={date.date}
              whileTap={{ scale: 0.95 }}
              onClick={() => setSelectedDate(date.date)}
              className={`flex-shrink-0 w-[72px] h-[88px] flex flex-col items-center justify-center rounded-xl transition-all ${
                selectedDate === date.date
                  ? "bg-secondary-container text-primary ring-2 ring-primary/10"
                  : "bg-surface-container text-on-surface-variant hover:bg-surface-container-high"
              }`}
            >
              <span className={`text-xs font-medium mb-1 ${selectedDate === date.date ? "font-bold" : ""}`}>
                {date.day}
              </span>
              <span className={`text-lg font-bold ${selectedDate === date.date ? "font-extrabold" : ""}`}>
                {date.date}
              </span>
            </motion.button>
          ))}
        </div>

        {/* Time Slots */}
        <div className="flex flex-col gap-8">
          {/* Morning */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Sunrise className="w-4 h-4 text-on-surface-variant" />
              <h4 className="font-headline font-semibold text-on-surface-variant uppercase tracking-widest text-xs">
                Morning
              </h4>
            </div>
            <div className="grid grid-cols-3 gap-3">
              {TIME_SLOTS.morning.map((time) => (
                <button
                  key={time}
                  onClick={() => setSelectedTime(time)}
                  disabled={time === "11:00 AM"} // Mock disabled
                  className={`py-3 px-4 rounded-full font-medium text-sm transition-all active:scale-95 ${
                    selectedTime === time
                      ? "bg-gradient-to-br from-primary to-primary-container text-white font-bold shadow-md ring-4 ring-primary/10"
                      : time === "11:00 AM"
                      ? "bg-surface-container text-outline-variant cursor-not-allowed opacity-60"
                      : "bg-surface-container-high text-on-surface hover:bg-surface-container-highest"
                  }`}
                >
                  {time}
                </button>
              ))}
            </div>
          </div>

          {/* Afternoon */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Sun className="w-4 h-4 text-on-surface-variant" />
              <h4 className="font-headline font-semibold text-on-surface-variant uppercase tracking-widest text-xs">
                Afternoon
              </h4>
            </div>
            <div className="grid grid-cols-3 gap-3">
              {TIME_SLOTS.afternoon.map((time) => (
                <button
                  key={time}
                  onClick={() => setSelectedTime(time)}
                  className={`py-3 px-4 rounded-full font-medium text-sm transition-all active:scale-95 ${
                    selectedTime === time
                      ? "bg-gradient-to-br from-primary to-primary-container text-white font-bold shadow-md ring-4 ring-primary/10"
                      : "bg-surface-container-high text-on-surface hover:bg-surface-container-highest"
                  }`}
                >
                  {time}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </ModalBottomSheet>
  );
}
