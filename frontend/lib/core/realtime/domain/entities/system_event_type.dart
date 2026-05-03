enum SystemEventType {
  jobNewRequest,
  jobAccepted,
  bookingRejected,
  quoteGenerated,
  quoteApproved,
  techEnRoute,
  techArrived,
  jobCompleted,
  paymentReceived,
  chatMessage,
  disputeOpened,
  disputeResolved,
  walletLowBalance,
  unknown;

  static const Map<String, SystemEventType> _lookup = {
    'job_new_request': SystemEventType.jobNewRequest,
    'job_accepted': SystemEventType.jobAccepted,
    'booking_rejected': SystemEventType.bookingRejected,
    'quote_generated': SystemEventType.quoteGenerated,
    'quote_approved': SystemEventType.quoteApproved,
    'tech_en_route': SystemEventType.techEnRoute,
    'tech_arrived': SystemEventType.techArrived,
    'job_completed': SystemEventType.jobCompleted,
    'payment_received': SystemEventType.paymentReceived,
    'chat_message': SystemEventType.chatMessage,
    'dispute_opened': SystemEventType.disputeOpened,
    'dispute_resolved': SystemEventType.disputeResolved,
    'wallet_low_balance': SystemEventType.walletLowBalance,
  };

  static SystemEventType fromRawType(String raw) =>
      _lookup[raw] ?? SystemEventType.unknown;
}
