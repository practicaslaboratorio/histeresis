#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

#define TERM_PIN A0
#define RELAY_PELTIER 5
#define RELAY_FAN 6

float Tamb = 0;   
float Tsup = 0;   
float consigna = 0; 
float dT1 = 0;
float dT2 = 0;

bool peltierON = false;
bool fanON = false; // control manual desde Processing

unsigned long lastSerial = 0;

void setup() {
  Serial.begin(9600);
  dht.begin();
  
  pinMode(RELAY_PELTIER, OUTPUT);
  pinMode(RELAY_FAN, OUTPUT);
  
  digitalWrite(RELAY_PELTIER, LOW);
  digitalWrite(RELAY_FAN, LOW);    
}

void loop() {
  Tamb = dht.readTemperature();
  Tsup = leerTermistor();

  // Histéresis Peltier (solo si consigna >0)
  if(consigna>0){
    if (peltierON) {
      if (Tsup <= consigna - dT2) peltierON = false;
      else if (Tsup >= consigna + dT1) peltierON = true;
    } else {
      if (Tsup >= consigna + dT1) peltierON = true;
    }
  }

  digitalWrite(RELAY_PELTIER, peltierON ? HIGH : LOW);
  digitalWrite(RELAY_FAN, fanON ? HIGH : LOW);

  // Enviar datos cada 500 ms
  if (millis() - lastSerial > 500) {
    lastSerial = millis();
    Serial.print(Tamb,2); Serial.print(",");
    Serial.print(Tsup,2); Serial.print(",");
    Serial.print(peltierON?"1":"0"); Serial.print(",");
    Serial.println(fanON?"1":"0");
  }

  // Comandos desde Processing
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd.startsWith("SET")) {
      int idx1 = cmd.indexOf(',');
      int idx2 = cmd.indexOf(',', idx1 + 1);
      int idx3 = cmd.indexOf(',', idx2 + 1);
      if (idx1>0 && idx2>0 && idx3>0){
        consigna = cmd.substring(idx1+1, idx2).toFloat();
        dT1 = cmd.substring(idx2+1, idx3).toFloat();
        dT2 = cmd.substring(idx3+1).toFloat();
        peltierON = true; // activar Peltier al iniciar ensayo
      }
    } else if (cmd.startsWith("FAN_ON")) fanON = true;
    else if (cmd.startsWith("FAN_OFF")) fanON = false;
  }
}

// Función termistor ajustada
float leerTermistor() {
  int val = analogRead(TERM_PIN);
  float V = (val * 5.0) / 1023.0;
  // Polinomio ajustado para valores razonables
  return 0.3754*V*V*V*V - 2.1424*V*V*V + 2.8994*V*V + 23.355*V - 32.646;
}
