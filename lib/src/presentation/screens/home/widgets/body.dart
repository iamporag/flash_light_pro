// ignore_for_file: library_private_types_in_public_api, prefer_final_fields

import 'dart:async';

import 'package:flash_light_pro/src/presentation/screens/home/widgets/bg.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'sun.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  bool isFullSun = false;
  bool isDayMood = false;
  Duration _duration = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        isFullSun = true;
      });
    });
  }

  void changeMood(bool isDay) async {
    // Set initial state based on isDay
    setState(() {
      isDayMood = isDay;
      isFullSun = isDay; // Set isFullSun based on isDay
    });

    // Introduce a delay if it's a transition to night
    if (!isDay) {
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        isDayMood = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Color> lightBgColors = [
      Color.fromARGB(255, 67, 76, 129),
      Color.fromARGB(255, 63, 75, 152),
      Color.fromARGB(255, 77, 118, 174),
      if (isFullSun) Color(0xFFFF9D80),
    ];
    var darkBgColors = [
      Color(0xFF0D1441),
      Color(0xFF283584),
      Color(0xFF376AB2),
    ];
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeInOut,
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDayMood ? lightBgColors : darkBgColors,
        ),
      ),
      child: Stack(
        children: [
          Sun(
            duration: _duration,
            isFullSun: isFullSun,
          ),
          Bg(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(20),

                  ElevatedButton(
                      onPressed: () {
                        changeMood(true);
                      },
                      child: Text("True")),
                  ElevatedButton(
                      onPressed: () {
                        changeMood(false);
                      },
                      child: Text("False")),
                  // Tabs(
                  //   press: (value) {
                  //     changeMood(value);
                  //   },
                  // ),
                  Gap(5),
                  Text(
                    "Good Morning",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
