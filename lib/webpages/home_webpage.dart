import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:student_mysiswa2/webpages/appointment_webpage.dart';
import 'package:student_mysiswa2/webpages/booking_webpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Import for web

class HomeWebPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _checkMissedAppointments();

    return DefaultTabController(
      length: 2,
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
          child: const Icon(Icons.call),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final whatsappNumber = "93515208";
    final whatsappUrl = "https://wa.me/60$whatsappNumber";

    if (kIsWeb) {
      // Use `window.open` for web to open in new tab
      html.window.open(whatsappUrl, '_blank');
    } else {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp")),
        );
      }
    }
  }

  void _showAdminWhatsAppDialog(BuildContext context) {
    final adminNumber = "093515208";

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
                  IconButton(
                    icon: Image.asset(
                      'assets/whatsapp_icon.png',
                      height: 35,
                    ),
                    onPressed: () => _openWhatsApp(context),
                    tooltip: 'Open in WhatsApp',
                    iconSize: 25,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: adminNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Number copied to clipboard")),
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
                Navigator.of(context).pop();
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
      return;
    }

    final now = DateTime.now();

    final QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'scheduled')
        .get();

    for (var doc in appointmentsSnapshot.docs) {
      final appointmentData = doc.data() as Map<String, dynamic>;

      final endTime = (appointmentData['endTime'] as Timestamp).toDate();

      if (now.isAfter(endTime)) {
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
