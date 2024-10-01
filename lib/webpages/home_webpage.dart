import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_mysiswa2/webpages/appointment_webpage.dart';
import 'package:student_mysiswa2/webpages/booking_webpage.dart';

class HomeWebPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _checkMissedAppointments(); // Call the function to check missed appointments

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Kad MySiswa')),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Appointment Details'),
              Tab(text: 'Booking Appointment'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AppointmentWebPage(),
            BookingWebPage(),
          ],
        ),
      ),
    );
  }

  void _checkMissedAppointments() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return; // Exit if the user is not logged in
    }

    // Get the current time
    final now = DateTime.now();

    // Query for scheduled appointments
    final QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUser.uid) // Filter by current user
        .where('status',
            isEqualTo: 'scheduled') // Only get scheduled appointments
        .get();

    for (var doc in appointmentsSnapshot.docs) {
      final appointmentData = doc.data() as Map<String, dynamic>;

      // Get the end time of the appointment
      final endTime = (appointmentData['endTime'] as Timestamp)
          .toDate(); // Convert to DateTime

      // Debugging output
      print('Current Time: $now');
      print('End Time: $endTime');

      // Check if the appointment has passed (date and time)
      if (now.isAfter(endTime)) {
        // Update the appointment status to 'missed'
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(doc.id)
            .update({
          'status': 'missed',
        });
        print('Appointment ${doc.id} marked as missed.');
      }
    }
  }
}
