import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class BookingWebPage extends StatefulWidget {
  const BookingWebPage({super.key});

  @override
  _BookingWebPageState createState() => _BookingWebPageState();
}

class _BookingWebPageState extends State<BookingWebPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _selectedTimeSlot = '';
  String _name = '';
  String _phoneNumber = '';

  List<String> timeSlots = [
    '8:30 - 9:30',
    '9:30 - 10:30',
    '10:30 - 11:30',
    '11:30 - 12:30',
    '2:30 - 3:30',
    '3:30 - 4:30',
  ];

  // Method to save booking data
  void _bookSlot() async {
    final currentUser = FirebaseAuth.instance.currentUser; // Get the current user
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to book an appointment.')),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedTimeSlot.isNotEmpty) {
      final booking = {
        'name': _name,
        'phoneNumber': _phoneNumber,
        'date': _selectedDate,
        'timeSlot': _selectedTimeSlot,
        'status': 'scheduled',
        'userId': currentUser.uid, // Include user ID
      };

      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('bookings').add(booking);

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select a time slot')),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Text fields for Name and Phone Number
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
                      return value!.isEmpty ? 'Please enter your name' : null;
                    },
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),

                  // For large screens, show calendar and time slot side by side
                  isSmallScreen
                      ? Column(
                          children: _buildBookingComponents(isSmallScreen),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildBookingComponents(isSmallScreen),
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
          margin: const EdgeInsets.only(bottom: 20.0),
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
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFFFCBCB),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 247, 108, 108),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
      if (!isSmallScreen) const SizedBox(width: 20),

      // Time slots on the right
      Expanded(
        flex: isSmallScreen ? 0 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = timeSlots[index];
                  });
                },
                child: Card(
                  color: _selectedTimeSlot == timeSlots[index]
                      ? const Color(0xFF121481)
                      : Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      timeSlots[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTimeSlot == timeSlots[index]
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}
