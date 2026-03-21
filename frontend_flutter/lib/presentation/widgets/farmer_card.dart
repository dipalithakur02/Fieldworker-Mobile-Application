import 'package:flutter/material.dart';
import '../../data/models/farmer_model.dart';
import 'package:url_launcher/url_launcher.dart';
class FarmerCard extends StatelessWidget {
  final FarmerModel farmer;

  FarmerCard({required this.farmer});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri launchUri = Uri.parse('https://wa.me/$phoneNumber');
    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF2E7D32),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          farmer.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_city, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(farmer.village),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(farmer.mobile),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: farmer.syncStatus == 'SYNCED' ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            farmer.syncStatus,
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (farmer.latitude != null && farmer.longitude != null)
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.red),
                    title: Text('Location'),
                    subtitle: Text('${farmer.latitude!.toStringAsFixed(4)}, ${farmer.longitude!.toStringAsFixed(4)}'),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(farmer.mobile),
                      icon: Icon(Icons.call, size: 18),
                      label: Text('Call'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _sendSMS(farmer.mobile),
                      icon: Icon(Icons.sms, size: 18),
                      label: Text('SMS'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(farmer.mobile),
                      icon: Icon(Icons.chat, size: 18),
                      label: Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (farmer.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Farmer ID not available")),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/crop-entry',
                      arguments: farmer.id!,
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Crop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (farmer.id == null) {
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      '/crops',
                      arguments: farmer.id!,
                    );
                  },
                  icon: Icon(Icons.list_alt),
                  label: Text('View Crops'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
