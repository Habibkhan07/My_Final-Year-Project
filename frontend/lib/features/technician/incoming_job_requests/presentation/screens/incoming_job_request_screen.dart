// Stub screen — the real card UI lands in a follow-up task.
//
// What's wired:
//   • Route `/technician/incoming-job-request` registered in `app_router.dart`.
//   • Pushed by `EventUrgencyRouter` on every `job_new_request` event (until
//     the screen is already mounted, in which case the list-route guard skips
//     the push and this screen reacts via `ref.watch` on the queue notifier).
//   • Reads typed `JobNewRequest` entries from `IncomingJobQueueNotifier`.
//
// What's stubbed:
//   • The body renders a flat list of `jobId`s. Replace with the real card
//     widget that switches on `BookingType` per BOOKINGS_API.md §2.4.
//
// Empty-queue behavior: auto-pop after frame. The screen is router-pushed,
// not user-navigated; an empty queue means there's nothing to look at.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/incoming_job_queue_notifier.dart';

class IncomingJobRequestScreen extends ConsumerWidget {
  const IncomingJobRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(incomingJobQueueProvider).queue;

    if (queue.isEmpty) {
      // Defer the pop one frame — popping during build throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Job Requests')),
      body: ListView.builder(
        itemCount: queue.length,
        itemBuilder: (context, index) {
          final request = queue[index];
          return ListTile(
            title: Text('Job #${request.jobId} — ${request.serviceName}'),
            subtitle: Text(
              'Rs. ${request.payoutRupees} · '
              '${request.bookingType.name}',
            ),
            trailing: TextButton(
              onPressed: () => ref
                  .read(incomingJobQueueProvider.notifier)
                  .removeRequest(request.jobId),
              child: const Text('Dismiss'),
            ),
          );
        },
      ),
    );
  }
}
