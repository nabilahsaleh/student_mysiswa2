import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';

class AppointmentWebPage extends StatefulWidget {
  const AppointmentWebPage({Key? key}) : super(key: key);

  @override
  _AppointmentWebPageState createState() => _AppointmentWebPageState();
}

class _AppointmentWebPageState extends State<AppointmentWebPage> {
  late Stream<List<Map<String, dynamic>>> _appointmentStream;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Get the current user's ID

  @override
  void initState() {
    super.initState();
    _setUpFirestoreListener();
  }

  void _setUpFirestoreListener() {
    _appointmentStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUserId) // Filter by user ID
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BBFDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9BBFDD),
        title: const Center(
          child: Text(
            'A P P O I N T M E N T ',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _appointmentStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No appointments found.'));
            }

            final upcomingAppointments = snapshot.data!
                .where((booking) =>
                    booking['status'] == 'scheduled')
                .toList();
            final pastAppointments = snapshot.data!
                .where((booking) =>
                    booking['status'] == 'canceled' ||
                    booking['status'] == 'completed' ||
                    booking['status'] == 'canceled by admin' ||
                    booking['status'] == 'missed')
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (upcomingAppointments.isEmpty)
                    const Text('No upcoming appointments.'),
                  for (var appointment in upcomingAppointments)
                    _buildAppointmentCard(
                      context: context,
                      date: (appointment['date'] as Timestamp).toDate(),
                      time: appointment['timeSlot'],
                      status: appointment['status'],
                      isUpcoming: true,
                      appointmentId: appointment['id'],
                    ),
                  const SizedBox(height: 40),
                  const Text(
                    'Past Appointments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pastAppointments.isEmpty)
                    const Text('No past appointments.'),
                  for (var appointment in pastAppointments)
                    _buildAppointmentCard(
                      context: context,
                      date: (appointment['date'] as Timestamp).toDate(),
                      time: appointment['timeSlot'],
                      status: appointment['status'],
                      isUpcoming: false,
                      appointmentId: appointment['id'],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required DateTime date,
    required String time,
    required String status,
    required bool isUpcoming,
    required String appointmentId,
  }) {
    final formattedDate = "${date.day} ${_monthName(date.month)} ${date.year}";

    // Define a color based on the status
    Color statusColor;
    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'missed':
        statusColor = Colors.orange;
        break;
      case 'canceled':
      case 'canceled by admin':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.black;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Adjust padding as needed
      child: Container(
        width: MediaQuery.of(context).size.width, // Responsive width
        child: Card(
          color: const Color(0xFFC7DCED),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: $formattedDate',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Time: $time',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Location: Banggunan Sarjana, Bilik Peralatan Komputer',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold, // Make the text bold
                    color: statusColor, // Change the text color based on status
                  ),
                ),
                const SizedBox(height: 10),

                // Conditionally render buttons only for upcoming appointments
                if (isUpcoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'Cancel Appointment',
                            content: 'Are you sure you want to cancel this appointment?',
                            onConfirm: () {
                              _cancelAppointment(context, appointmentId);
                            },
                          );
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthNames[month - 1];
  }

  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onConfirm(); // Execute the confirmed action
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(BuildContext context, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(appointmentId)
          .update({'status': 'canceled'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }
}
