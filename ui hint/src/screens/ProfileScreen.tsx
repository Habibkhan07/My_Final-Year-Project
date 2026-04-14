import { Star, Verified, User, ChevronRight, Share2, ArrowLeft, Calendar } from "lucide-react";
import { Technician } from "../types";
import { motion } from "motion/react";

interface ProfileScreenProps {
  technician: Technician;
  onSelectTime: () => void;
}

export default function ProfileScreen({ technician, onSelectTime }: ProfileScreenProps) {
  return (
    <div className="min-h-screen bg-surface pb-32">
      {/* Header */}
      <header className="fixed top-0 w-full z-30 flex justify-between items-center px-6 h-20 bg-transparent">
        <button className="w-12 h-12 flex items-center justify-center rounded-full bg-white/20 backdrop-blur-xl transition-all active:scale-90 shadow-sm border border-white/30">
          <ArrowLeft className="w-6 h-6 text-on-surface" />
        </button>
        <div className="flex gap-2">
          <button className="w-12 h-12 flex items-center justify-center rounded-full bg-white/20 backdrop-blur-xl transition-all active:scale-90 shadow-sm border border-white/30">
            <Share2 className="w-6 h-6 text-on-surface" />
          </button>
        </div>
      </header>

      <main className="max-w-xl mx-auto px-6 pt-24">
        {/* Hero Section */}
        <section className="flex flex-col items-center text-center mb-10">
          <div className="relative mb-6">
            <div className="w-32 h-32 rounded-full overflow-hidden shadow-2xl shadow-primary/10 ring-4 ring-white">
              <img 
                src={technician.photoUrl} 
                alt={technician.name}
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            </div>
            <div className="absolute -bottom-1 -right-1 bg-green-500 w-6 h-6 rounded-full border-4 border-white" />
          </div>
          <h1 className="font-headline font-bold text-3xl tracking-tight text-on-surface mb-2">
            {technician.name}
          </h1>
          <div className="flex items-center gap-1.5 px-4 py-2 rounded-full bg-primary/5 border border-primary/5">
            <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
            <span className="text-primary font-semibold text-sm">{technician.rating}</span>
            <span className="text-on-surface-variant/70 text-sm">({technician.jobCount} jobs)</span>
          </div>
        </section>

        {/* Price Card */}
        <section className="mb-10 relative">
          {technician.discountPercent && (
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 z-10 bg-primary text-white text-[10px] font-bold tracking-widest px-3 py-1 rounded-full uppercase">
              {technician.discountPercent}% OFF!
            </div>
          )}
          <div className="bg-primary/5 rounded-xl p-10 flex flex-col items-center justify-center text-center">
            <div className="font-headline font-extrabold text-5xl text-primary tracking-tighter mb-1">
              Rs. {technician.inspectionFee.toLocaleString()}
            </div>
            <div className="text-on-surface-variant font-medium text-sm">
              Inspection Fee
            </div>
          </div>
        </section>

        {/* Info List */}
        <section className="space-y-4">
          {[
            { icon: <Star className="w-5 h-5 text-primary" />, label: `Read ${technician.jobCount} Reviews` },
            { icon: <Verified className="w-5 h-5 text-primary" />, label: "Skills & Licenses" },
            { icon: <User className="w-5 h-5 text-primary" />, label: "About Me" },
          ].map((item, index) => (
            <motion.div 
              key={index}
              whileTap={{ scale: 0.98 }}
              className="bg-white rounded-xl p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex items-center justify-between group cursor-pointer transition-transform"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-surface-container-low flex items-center justify-center">
                  {item.icon}
                </div>
                <span className="font-semibold text-on-surface">{item.label}</span>
              </div>
              <ChevronRight className="w-5 h-5 text-outline-variant" />
            </motion.div>
          ))}
        </section>

        {/* Bio */}
        <section className="mt-8 px-2">
          <p className="text-on-surface-variant leading-relaxed text-sm">
            {technician.bio}
          </p>
        </section>
      </main>

      {/* Sticky Bottom Bar */}
      <nav className="fixed bottom-0 left-0 w-full bg-white px-6 pt-4 pb-8 flex justify-between items-center gap-4 shadow-[0_-10px_40px_rgba(0,0,0,0.06)] rounded-t-[2.5rem] z-30">
        <button 
          onClick={onSelectTime}
          className="flex-1 h-14 bg-primary text-white rounded-full font-headline font-bold text-lg flex items-center justify-center gap-2 shadow-lg shadow-primary/20 active:scale-[0.97] transition-all"
        >
          <Calendar className="w-5 h-5" />
          Select Time
        </button>
      </nav>
    </div>
  );
}
