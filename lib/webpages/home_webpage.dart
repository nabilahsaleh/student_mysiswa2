import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Needed for clipboard functionality
import 'package:student_mysiswa2/webpages/appointment_webpage.dart';
import 'package:student_mysiswa2/webpages/booking_webpage.dart';
import 'package:url_launcher/url_launcher.dart'; // Needed to open WhatsApp

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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAdminWhatsAppDialog(context);
          },
          child: const Icon(Icons.call), // You can use Icons.help or Icons.call
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  // Function to open WhatsApp with the admin's number
  Future<void> _openWhatsApp() async {
    final whatsappNumber = "093515208";
    final whatsappUrl = "https://wa.me/60$whatsappNumber"; // WhatsApp API link
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl); // Open WhatsApp
    } else {
      throw "Could not launch WhatsApp";
    }
  }

  // Function to show the dialog with WhatsApp number
  void _showAdminWhatsAppDialog(BuildContext context) {
    final adminNumber = "093515208"; // Admin's WhatsApp number

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Contact Admin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                adminNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // WhatsApp Icon
                  IconButton(
                    icon: Image.asset(
                        'assets/whatsapp_icon.png',
                        height: 35,
                      ),
                    onPressed: _openWhatsApp,
                    tooltip: 'Open in WhatsApp',
                    iconSize: 25,
                  ),
                  const SizedBox(width: 20),
                  // Copy Icon
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: adminNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Number copied to clipboard")),
                      );
                    },
                    tooltip: 'Copy number',
                    iconSize: 25,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
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
        .where('status', isEqualTo: 'scheduled') // Only get scheduled appointments
        .get();

    for (var doc in appointmentsSnapshot.docs) {
      final appointmentData = doc.data() as Map<String, dynamic>;

      // Get the end time of the appointment
      final endTime = (appointmentData['endTime'] as Timestamp).toDate(); // Convert to DateTime

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
