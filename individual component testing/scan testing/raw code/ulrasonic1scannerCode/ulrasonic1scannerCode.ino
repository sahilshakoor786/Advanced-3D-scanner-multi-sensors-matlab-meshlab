const int sensorPin = A3;  // Connect IR sensor output to A0

void setup() {
  Serial.begin(9600);      // Initialize serial communication
}

void loop() {
  const int samples = 10;
  long sensorValue = 0;
  
  // Take multiple samples for a better average reading
  for (int i = 0; i < samples; i++) {
    sensorValue += analogRead(sensorPin);
    delay(10);  // Short delay between readings
  }
  sensorValue /= samples;  // Average the readings

  // Prevent division by zero or negative values in the formula.
  // (Threshold value chosen based on calibration experience.)
  if (sensorValue <= 31) {
    Serial.println("Error: Invalid reading");
    delay(50);
    return;
  }
  
  // Calculate distance using an empirical formula calibrated for a 2–15 cm IR sensor.
  // The formula below is: distance = 738.46 / (sensorValue - 30.77)
  // where the constants were chosen such that:
  //   When sensorValue ~ 400, distance ~ 2 cm, and
  //   When sensorValue ~ 80,  distance ~ 15 cm.
  // You should adjust these numbers based on your own calibration.
  float distance = 738.46 / (sensorValue - 30.77);
  
  // Constrain the calculated distance to the sensor's valid range (2–15 cm)
  distance = constrain(distance, 2.0, 15.0);
  
  // Display the result
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");
  
  delay(500);  // Adjust delay between measurements as needed
}
