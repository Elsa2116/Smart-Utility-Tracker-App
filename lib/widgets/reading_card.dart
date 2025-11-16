import 'package:flutter/material.dart';
import '../models/reading.dart';

class ReadingCard extends StatelessWidget {
  final Reading reading;

  const ReadingCard({Key? key, required this.reading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reading.type.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${reading.usage} ${reading.type == 'electricity' ? 'kWh' : reading.type == 'water' ? 'L' : 'm³'}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${reading.date.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (reading.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Notes: ${reading.notes}'),
              ),
          ],
        ),
      ),
    );
  }
}
