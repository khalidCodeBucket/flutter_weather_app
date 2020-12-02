import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  var minTemperatureForecast = new List(7);
  var maxTemperatureForecast = new List(7);
  String location = 'San Fransisco';
  int woeid = 2487956;
  String weather = 'clear';
  String abbreviation = '';
  var abbreviationForecast = new List(7);
  String errorMessage = '';

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';

  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry we don't have data about this city. try another one.";
      });
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbreviation = data["weather_state_abbr"];
    });
  }

  /// 7 days forecast
  void fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i <= 7; i++) {
      var locationDayResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString());

      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbreviationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.locality);
      print(place.locality);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'images/$weather.png',
              ),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.dstATop),
            ),
          ),
          child: temperature == null
              ? Container(
                  child: CircularProgressIndicator(),
                )
              : Scaffold(
                  appBar: AppBar(
                    actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            _getCurrentLocation();
                          },
                          child: Icon(
                            Icons.location_city,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  backgroundColor: Colors.transparent,
                  body: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Center(
                              child: Image.network(
                                'https://www.metaweather.com/static/img/weather/png/' +
                                    abbreviation +
                                    '.png',
                                width: 100,
                              ),
                            ),
                            Center(
                              child: Text(
                                temperature.toString() + ' °C',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 60),
                              ),
                            ),
                            Center(
                              child: Text(
                                location,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 40),
                              ),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              forecastElement(
                                  1,
                                  abbreviationForecast[0],
                                  minTemperatureForecast[0],
                                  maxTemperatureForecast[0]),
                              forecastElement(
                                  2,
                                  abbreviationForecast[1],
                                  minTemperatureForecast[1],
                                  maxTemperatureForecast[1]),
                              forecastElement(
                                  3,
                                  abbreviationForecast[2],
                                  minTemperatureForecast[2],
                                  maxTemperatureForecast[2]),
                              forecastElement(
                                  4,
                                  abbreviationForecast[3],
                                  minTemperatureForecast[3],
                                  maxTemperatureForecast[3]),
                              forecastElement(
                                  5,
                                  abbreviationForecast[4],
                                  minTemperatureForecast[4],
                                  maxTemperatureForecast[4]),
                              forecastElement(
                                  6,
                                  abbreviationForecast[5],
                                  minTemperatureForecast[5],
                                  maxTemperatureForecast[5]),
                              forecastElement(
                                  7,
                                  abbreviationForecast[6],
                                  minTemperatureForecast[6],
                                  maxTemperatureForecast[6]),
                            ],
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            Container(
                              width: 300,
                              child: TextField(
                                onSubmitted: (String input) {
                                  onTextFieldSubmitted(input);
                                },
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25),
                                decoration: InputDecoration(
                                  hintText: 'Search another location...',
                                  hintStyle: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: Platform.isAndroid ? 15 : 20),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
        ));
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, mimTemperature, maxTemperature) {
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              new DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbreviation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High: ' + maxTemperature.toString() + ' °C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Low: ' + mimTemperature.toString() + ' °C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
