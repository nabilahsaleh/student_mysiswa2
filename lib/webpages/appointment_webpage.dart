import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentWebPage extends StatefulWidget {
  @override
  _AppointmentWebPageState createState() => _AppointmentWebPageState();
}

class _AppointmentWebPageState extends State<AppointmentWebPage> {
  late Stream<List<Map<String, dynamic>>> _appointmentStream;

  @override
  void initState() {
    super.initState();
    _setUpFirestoreListener();
  }

  void _setUpFirestoreListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    _appointmentStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUser.uid)
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
          child: Text('A P P O I N T M E N T'),
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

            final now = DateTime.now();
            final upcomingAppointments = snapshot.data!.where((booking) {
              final date = (booking['date'] as Timestamp).toDate();
              return booking['status'] == 'scheduled' || 
                     booking['status'] == 'in-progress' && date.isAfter(now);
            }).toList();

            final pastAppointments = snapshot.data!.where((booking) {
              final date = (booking['date'] as Timestamp).toDate();
              return booking['status'] == 'completed' || 
                     booking['status'] == 'canceled' || 
                     date.isBefore(now);
            }).toList();

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
  }) {
    final formattedDate = "${date.day} ${_monthName(date.month)} ${date.year}";
    
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define card width as a fraction of the screen width
    final cardWidth = screenWidth * 0.9; // 90% of the screen width

    // Define a color based on the status
    Color statusColor;
    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'in-progress':
        statusColor = Colors.orange;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.black;
    }

    return Card(
      color: const Color(0xFFC7DCED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: SizedBox(
        width: cardWidth,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: $formattedDate', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text('Time: $time', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              const Text(
                'Location: Banggunan Sarjana, Bilik Peralatan Komputer',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Status: $status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
}
