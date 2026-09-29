import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6FAF8),

      appBar: AppBar(
        backgroundColor: const Color(0xff004D3B),
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text(
          "Platform Administration",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Platform\nAdministration",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff063B2C),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Lead Admin: Minoshi • DineQueue Global",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(child: _infoCard("Restaurants", "5", Icons.store)),

                const SizedBox(width: 15),

                Expanded(child: _infoCard("Platform Users", "4", Icons.people)),
              ],
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("Restaurants"),

                Text("Users"),

                Text("Broadcasts"),

                Text("System"),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Partner Restaurants (5)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff063B2C),
              ),
            ),

            const SizedBox(height: 15),

            restaurantCard("Ocean Bistro", "Italian • Seafood • \$\$\$"),

            restaurantCard("The Mango Tree", "Indian • North Indian"),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String number, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Icon(icon, color: Color(0xff006B50)),

          const SizedBox(height: 8),

          Text(
            number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget restaurantCard(String name, String details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            name,

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(details, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,

            children: const [
              Text("Toggle Status", style: TextStyle(color: Colors.green)),

              SizedBox(width: 20),

              Text("Edit"),

              SizedBox(width: 20),

              Icon(Icons.delete, color: Colors.orange, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
