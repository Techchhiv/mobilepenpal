import 'package:flutter/material.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';

class ParentHome extends StatelessWidget {
  final HomeController homeController;

  const ParentHome({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopButton(Icons.settings, 'ការកំណត់'),
            _buildTopButton(Icons.bar_chart_outlined, 'របាយការណ៍'),
            _buildTopButton(Icons.calendar_today_outlined, 'កាលវិភាគ'),
          ],
        ),

        const SizedBox(height: 24),

        _buildChildProgressCard(),

        const SizedBox(height: 24),

        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildTopButton(IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00897B)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildProgressCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ដំណើរការ របស់កូនសិស្ស"),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 356,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ឈី អរុណា',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ថ្នាក់ទី ៣ក',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C9684),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'កំពុងសកម្ម',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
        
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'មុខវិជ្ជា៖',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'គណិតវិឡា',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        
              Spacer(),
              Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  Text(
                    '4/10 lessons',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
        
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.4,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF00897B),
                  minHeight: 8,
                ),
              ),
        
              const SizedBox(height: 12),
        
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 6),
                  Text('Recent: ', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 6),
                  Text(
                    'Finished Solar System Quiz',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.access_time, color: Colors.grey, size: 18),
                  SizedBox(width: 6),
                  Text('Time: ', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 6),
                  Text(
                    '1h 45m Today',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
        
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.school_rounded),
                label: const Text('ចូលមើលរបាយការណ៍'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EC4B6),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("របាយការណ៍សង្ខេប"),
        SizedBox(height: 12,),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'សង្ខេបសកម្មភាព',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('មេរៀនបានរៀន', '24', Colors.lightBlueAccent),
                  _buildSummaryItem('ពេលវេលាសិក្សា', '8h 30m', Colors.greenAccent),
                  _buildSummaryItem('លទ្ធផលល្អ', '95%', Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
