/* 
Lectura de DHT11 en D4
Lectura de termistor en A0
Control de celda Peltier y ventilador mediante relés (D5 y D6)
Visualización de datos por Serial
NO1 / NO2 : Active HIGH (HIGH enciende, LOW apaga)
*/
#include <TimerOne.h>
#include <DHT.h>
#define DHTPIN 4
#define DHTTYPE DHT11
#define RELAY_PELTIER 5
#define RELAY_FAN 6
DHT dht(DHTPIN, DHTTYPE);
float Tamb = 0;      // Temperatura ambientalfloat Tsup = 0;      // Temperatura en la superficie de la celda
int inicio = 0, estado = 0, fin = 1, eT = -1;
float dT1 = 1.0, dT2 = 1.5;
unsigned long tiempo_1 = 0, tiempo_2 = 0, tiempo_3 = 0, control_tiempos = 0;
void setup() {
Serial.begin(9600);
dht.begin();
pinMode(RELAY_PELTIER, OUTPUT);
pinMode(RELAY_FAN, OUTPUT);
digitalWrite(RELAY_PELTIER, LOW);  // Inicial apagado
digitalWrite(RELAY_FAN, LOW);      // Inicial apagado
Timer1.initialize(1000000);
Timer1.attachInterrupt(intu);
Serial.println("Sistema listo. Envíe comando: c <modo> <t1> <t2> <t3>");
}

void intu() {
Serial.print(Tamb);
Serial.print(",");
Serial.println(Tsup);
control_tiempos++;
}
// Control ON / OFF simple (Active HIGH)
void controlTemperatura() {
if (eT == -1) {
digitalWrite(RELAY_PELTIER, HIGH);  // Encender
digitalWrite(RELAY_FAN, HIGH);      // Encender
eT = 1;
} else {
digitalWrite(RELAY_PELTIER, LOW);   // Apagar
digitalWrite(RELAY_FAN, LOW);       // Apagar
eT = -1;
  }
}
float leerTermistor() {
int val = analogRead(A0);
float V = (val * 5.0) / 1023.0;
return 1.7842 * V * V * V - 11.597 * V * V + 45.702 * V - 44.733;
}

void loop() {
Tamb = dht.readTemperature();
Tsup = leerTermistor();
switch (inicio) {

case 0:
digitalWrite(RELAY_PELTIER, LOW);
digitalWrite(RELAY_FAN, LOW);
estado = 0;
break;
case 1:
estado = 1;
break;
case 2:
if (control_tiempos < tiempo_1) {
estado = 1;
} else if (control_tiempos < tiempo_1 + tiempo_2) {
controlTemperatura();
estado = 2;
} else if (control_tiempos < tiempo_1 + tiempo_2 + tiempo_3) {
digitalWrite(RELAY_PELTIER, LOW);
digitalWrite(RELAY_FAN, LOW);
estado = 3;
} else {
fin = 0;
inicio = 0;
estado = 4;
control_tiempos = 0;
}
break;

default:
inicio = 0;
break;
   }
}

void serialEvent() {
if (Serial.peek() == 'c') {
Timer1.detachInterrupt();
Serial.read();
inicio = Serial.parseInt();
tiempo_1 = Serial.parseInt();
tiempo_2 = Serial.parseInt();
tiempo_3 = Serial.parseInt();
dT1 = Serial.parseFloat();
dT2 = Serial.parseFloat();
fin = 1;
control_tiempos = 0;
Timer1.attachInterrupt(intu);
}
while (Serial.available() > 0) Serial.read();
}
// Ejemplo comando serial: c 2 5 10 5 1.0 1.5