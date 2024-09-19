import 'package:flutter/material.dart';
import 'package:student_mysiswa2/webpages/appointment_webpage.dart';
import 'package:student_mysiswa2/webpages/booking_webpage.dart';

class HomeWebPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Kad MySiswa')),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Appointment Details'),
              Tab(text: 'Booking Appointment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AppointmentWebPage(),
            BookingWebPage(),
          ],
        ),
      ),
    );
  }
}
