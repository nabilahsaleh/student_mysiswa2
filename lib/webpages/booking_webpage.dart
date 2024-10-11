import 'package:flutter/material.dart';
import 'package:student_mysiswa2/webpages/home_webpage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingWebPage extends StatefulWidget {
  const BookingWebPage({super.key});

  @override
  _BookingWebPageState createState() => _BookingWebPageState();
}

class _BookingWebPageState extends State<BookingWebPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _name = '';
  String _phoneNumber = '';
  String _studentId = '';
  String _selectedFaculty = '';
  String _selectedPurpose = '';
  String _selectedSession = '';
  String? _selectedTime;

  // List of faculties for dropdown
  List<String> faculties = [
    'Faculty of Science',
    'Faculty of Engineering',
    'Faculty of Arts',
    'Faculty of Medicine',
    'Faculty of Business',
  ];

  // List of purposes for dropdown
  List<String> purposes = [
    'Card Renewal',
    'Card Replacement',
    'Damaged Card',
    'Other',
  ];

  // List of sessions for dropdown
  List<String> sessions = [
    'Morning',
    'Evening',
  ];

  List<String> morningTimeSlots = [
    '8:30 AM - 8:45 AM',
    '8:45 AM - 9:00 AM',
    '9:00 AM - 9:15 AM',
    '9:15 AM - 9:30 AM',
    '9:30 AM - 9:45 AM',
    '9:45 AM - 10:00 AM',
    '10:00 AM - 10:15 AM',
    '10:15 AM - 10:30 AM',
    '10:30 AM - 10:45 AM',
    '10:45 AM - 11:00 AM',
    '11:00 AM - 11:15 AM',
    '11:15 AM - 11:30 AM',
    '11:30 AM - 11:45 AM',
  ];

  List<String> eveningTimeSlots = [
    '3:00 PM - 3:15 PM',
    '3:15 PM - 3:30 PM',
    '3:30 PM - 3:45 PM',
    '3:45 PM - 4:00 PM',
    '4:00 PM - 4:15 PM',
    '4:15 PM - 4:30 PM',
  ];

  // Method to save booking data
// Method to save booking data
  void _bookSlot() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be logged in to book an appointment.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Parse the selected time to get start and end times
      String startTime;
      String endTime;

      if (_selectedSession == 'Morning') {
        startTime = _selectedTime!.split(' - ')[0]; // Get the start time
        endTime = _selectedTime!.split(' - ')[1]; // Get the end time
      } else {
        startTime = _selectedTime!.split(' - ')[0]; // Get the start time
        endTime = _selectedTime!.split(' - ')[1]; // Get the end time
      }

      // Convert the 12-hour format to 24-hour format
      DateTime startDateTime = DateFormat("h:mm a").parse(startTime);
      DateTime endDateTime = DateFormat("h:mm a").parse(endTime);

      // Format to 24-hour format
      String startTime24 = DateFormat('HH:mm').format(startDateTime);
      String endTime24 = DateFormat('HH:mm').format(endDateTime);

      final booking = {
        'name': _name,
        'phoneNumber': _phoneNumber,
        'studentId': _studentId,
        'faculty': _selectedFaculty,
        'purpose': _selectedPurpose,
        'session': _selectedSession,
        'date': _selectedDate,
        'time': _selectedTime,
        'startTime': startTime24,
        'endTime': endTime24,
        'status': 'scheduled',
        'notification': 'no',
        'userId': currentUser.uid,
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').add(booking);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeWebPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF9BBFDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9BBFDD),
        title: const Center(
          child: Text('B O O K I N G'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 100.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Create two columns for form fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            // Full Name field
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _name = value;
                                });
                              },
                              validator: (value) {
                                return value!.isEmpty
                                    ? 'Please enter your name'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Phone Number field
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                setState(() {
                                  _phoneNumber = value;
                                });
                              },
                              validator: (value) {
                                return value!.isEmpty
                                    ? 'Please enter your phone number'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Faculty dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Faculty',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedFaculty.isNotEmpty
                                  ? _selectedFaculty
                                  : null,
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedFaculty = newValue!;
                                });
                              },
                              items: faculties.map((faculty) {
                                return DropdownMenuItem<String>(
                                  value: faculty,
                                  child: Text(faculty),
                                );
                              }).toList(),
                              validator: (value) {
                                return value == null
                                    ? 'Please select your faculty'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            // Student ID field
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Student ID',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _studentId = value;
                                });
                              },
                              validator: (value) {
                                return value!.isEmpty
                                    ? 'Please enter your Student ID'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Purpose dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedPurpose.isEmpty
                                  ? null
                                  : _selectedPurpose,
                              items: purposes.map((String purpose) {
                                return DropdownMenuItem<String>(
                                  value: purpose,
                                  child: Text(purpose),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPurpose = value!;
                                });
                              },
                              validator: (value) {
                                return value == null
                                    ? 'Please select a purpose'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Session dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Session',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedSession.isEmpty
                                  ? null
                                  : _selectedSession,
                              items: sessions.map((String session) {
                                return DropdownMenuItem<String>(
                                  value: session,
                                  child: Text(session),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSession = value!;
                                  _selectedTime =
                                      null; // Reset time when session changes
                                });
                              },
                              validator: (value) {
                                return value == null
                                    ? 'Please select a session'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // For large screens, show calendar
                  isSmallScreen
                      ? Column(
                          children: _buildBookingComponents(isSmallScreen),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildBookingComponents(isSmallScreen),
                        ),

                  // Time slot dropdown
                  const SizedBox(height: 20),
                  if (_selectedSession.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTime,
                      items: (_selectedSession == 'Morning'
                              ? morningTimeSlots
                              : eveningTimeSlots)
                          .map((timeSlot) {
                        return DropdownMenuItem<String>(
                          value: timeSlot,
                          child: Text(timeSlot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTime = value!;
                        });
                      },
                      validator: (value) {
                        return value == null
                            ? 'Please select a time slot'
                            : null;
                      },
                    ),
                  // Booking button
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: _bookSlot,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 13),
                          backgroundColor:
                              const Color.fromARGB(255, 247, 108, 108),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'BOOK',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBookingComponents(bool isSmallScreen) {
    return [
      // Calendar on the left
      Expanded(
        flex: isSmallScreen ? 0 : 1,
        child: Container(
            color: Colors.white,
            margin: const EdgeInsets.only(right: 40, left: 40, top: 15),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime(2100),
              focusedDay: _selectedDate,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              enabledDayPredicate: (day) {
                // Disable weekends (Saturday and Sunday)
                return day.weekday != DateTime.saturday &&
                    day.weekday != DateTime.sunday;
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFFFFCBCB),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color.fromARGB(255, 247, 108, 108),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            )),
      ),
    ];
  }
}
