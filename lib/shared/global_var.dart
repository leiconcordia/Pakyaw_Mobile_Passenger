import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String googleMapKey = "AIzaSyCktX1ob4acTROgV1-hdSgXiSwZwREe3X4";
String password = "bnov hkwg ywts lgci";
String email = "gorduizlancecarlos@gmail.com";

const CameraPosition googlePlexInitPos = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();