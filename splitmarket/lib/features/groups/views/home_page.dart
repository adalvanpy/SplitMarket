import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import '../../../widgets/custom_buttom_navbar.dart';

import '../../../services/location_service.dart';

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {

  final LocationService
      locationService =
          LocationService();

  Position? currentPosition;

  String address = '';

  final MapController mapController =
      MapController();

  bool loading = false;

  Future<void> getLocation() async {

    setState(() {

      loading = true;
    });

    final position =
        await locationService
            .getCurrentLocation();

    if (position != null) {

      final endereco =
          await locationService
              .getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {

        currentPosition = position;

        address = endereco;

        loading = false;
      });

    } else {

      setState(() {

        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      body: SingleChildScrollView(

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // Header com Degradê
            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                24,
                60,
                24,
                40,
              ),

              decoration: const BoxDecoration(

                gradient: LinearGradient(

                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                  colors: [

                    Color(0xFF8E76F7),

                    Color(0xFFB993F9),
                  ],
                ),

                borderRadius:
                    BorderRadius.only(

                  bottomLeft:
                      Radius.circular(40),

                  bottomRight:
                      Radius.circular(40),
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Bem-vinda ao SplitMarket!',

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 26,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(

                    'Gerencie despesas em grupo de forma simples.',

                    style: TextStyle(

                      color:
                          Colors.white
                              .withOpacity(
                        0.7,
                      ),

                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(

              padding:
                  const EdgeInsets.all(24),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    'Visão Geral',

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          Theme.of(context)

                              .textTheme

                              .bodyLarge

                              ?.color,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(

                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(

                      onPressed: loading
                          ? null
                          : getLocation,

                      style:
                          ElevatedButton
                              .styleFrom(

                        backgroundColor:
                            const Color(
                          0xFF8E76F7,
                        ),

                        foregroundColor:
                            Colors.white,
                      ),

                      child: loading

                          ? const CircularProgressIndicator(
                              color:
                                  Colors.white,
                            )

                          : const Text(

                              'Obter Localização',

                              style:
                                  TextStyle(
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (currentPosition != null)
                    Column(

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(

                          address,

                          style:
                              const TextStyle(

                            fontSize: 16,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Text(

                          'Latitude: ${currentPosition!.latitude}',

                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(

                          'Longitude: ${currentPosition!.longitude}',

                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        SizedBox(

                          height: 300,

                          child: ClipRRect(

                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),

                            child: FlutterMap(

                              mapController:
                                  mapController,

                              options:
                                  MapOptions(

                                initialCenter:
                                    LatLng(

                                  currentPosition!
                                      .latitude,

                                  currentPosition!
                                      .longitude,
                                ),

                                initialZoom: 15,
                              ),

                              children: [

                                TileLayer(

                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                                  userAgentPackageName:
                                      'com.example.splitmarket',
                                ),

                                MarkerLayer(

                                  markers: [

                                    Marker(

                                      point:
                                          LatLng(

                                        currentPosition!
                                            .latitude,

                                        currentPosition!
                                            .longitude,
                                      ),

                                      width: 80,

                                      height: 80,

                                      child:
                                          const Icon(

                                        Icons
                                            .location_on,

                                        color:
                                            Colors.red,

                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation reutilizável
      bottomNavigationBar:
          const CustomBottomNavbar(
        currentIndex: 0,
      ),
    );
  }
}