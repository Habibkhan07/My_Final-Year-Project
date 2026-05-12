enum SystemEventType {
  jobNewRequest,
  jobAccepted,
  bookingRejected,
  quoteGenerated,
  quoteApproved,
  quoteRevisionRequested,
  quoteDeclined,
  techEnRoute,
  techArrived,
  customerArriving,
  inspectionStarted,
  jobCompleted,
  paymentReceived,
  chatMessage,
  disputeOpened,
  disputeResolved,
  walletLowBalance,
  bookingCancelled,
  bookingNoShow,
  bookingRescheduled,
  unknown;

  static const Map<String, SystemEventType> _lookup = {
    'job_new_request': SystemEventType.jobNewRequest,
    'job_accepted': SystemEventType.jobAccepted,
    'booking_rejected': SystemEventType.bookingRejected,
    'quote_generated': SystemEventType.quoteGenerated,
    'quote_approved': SystemEventType.quoteApproved,
    'quote_revision_requested': SystemEventType.quoteRevisionRequested,
    'quote_declined': SystemEventType.quoteDeclined,
    'tech_en_route': SystemEventType.techEnRoute,
    'tech_arrived': SystemEventType.techArrived,
    'customer_arriving': SystemEventType.customerArriving,
    'inspection_started': SystemEventType.inspectionStarted,
    'job_completed': SystemEventType.jobCompleted,
    'payment_received': SystemEventType.paymentReceived,
    'chat_message': SystemEventType.chatMessage,
    'dispute_opened': SystemEventType.disputeOpened,
    'dispute_resolved': SystemEventType.disputeResolved,
    'wallet_low_balance': SystemEventType.walletLowBalance,
    'booking_cancelled': SystemEventType.bookingCancelled,
    'booking_no_show': SystemEventType.bookingNoShow,
    'booking_rescheduled': SystemEventType.bookingRescheduled,
  };

  static SystemEventType fromRawType(String raw) =>
      _lookup[raw] ?? SystemEventType.unknown;
}
