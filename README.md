# beacon_demo_ui

This project is a smart anti-theft system using ESP32 and a Flutter mobile app.

## Features
- BLE-based device tracking
- RSSI signal strength monitoring
- Distance estimation (Very Near / Medium / Far)
- Real-time alerts
- Buzzer alarm for theft warning

## Technologies
- Flutter (Mobile App)
- ESP32 (BLE Beacon)
- Arduino IDE (Embedded Programming)

## How it works
The ESP32 acts as a Bluetooth beacon.  
The mobile app scans the signal strength (RSSI) and estimates distance.  
When the signal becomes weak, the app sends an alert and activates the buzzer.
