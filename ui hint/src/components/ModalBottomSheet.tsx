import { motion, AnimatePresence } from "motion/react";
import { X } from "lucide-react";
import { ReactNode } from "react";

interface ModalBottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  footer?: ReactNode;
}

export default function ModalBottomSheet({
  isOpen,
  onClose,
  title,
  children,
  footer,
}: ModalBottomSheetProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-on-surface/20 backdrop-blur-[2px] z-40"
          />
          
          {/* Sheet */}
          <motion.div
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            transition={{ type: "spring", damping: 25, stiffness: 200 }}
            className="fixed bottom-0 left-0 right-0 z-50 flex flex-col max-h-[90vh] bg-surface-container-lowest rounded-t-[24px] ambient-shadow w-full max-w-2xl mx-auto overflow-hidden"
          >
            {/* Drag Handle & Header */}
            <div className="flex flex-col items-center pt-3 pb-4">
              <div className="w-12 h-1.5 bg-outline-variant rounded-full mb-4 opacity-40" />
              <div className="px-6 w-full flex items-center justify-between">
                <h3 className="font-headline font-bold text-2xl tracking-tight text-on-surface">
                  {title}
                </h3>
                <button 
                  onClick={onClose}
                  className="p-2 hover:bg-surface-container rounded-full transition-colors"
                >
                  <X className="w-6 h-6 text-primary" />
                </button>
              </div>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-6">
              {children}
            </div>

            {/* Footer */}
            {footer && (
              <div className="px-6 py-6 bg-surface-container-lowest border-t border-outline-variant/15">
                {footer}
              </div>
            )}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
