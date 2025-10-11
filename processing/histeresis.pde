import processing.serial.*;
import controlP5.*;
Serial myPort;
float Tamb = 0;    // Temperatura Ambiental
float Tsup = 0;    // Temperatura de la celda
float hMin = 25;   // Límite inferior de histéresis
float hMax = 30;   // Límite superior de histéresis
int tiempoControl = 10;  // Tiempo de control en segundos
ArrayList<Float> historialTamb = new ArrayList<Float>();
ArrayList<Float> historialTsup = new ArrayList<Float>();
int maxHist = 300;
ControlP5 cp5;
void setup() {
size(800, 500);
println(Serial.list());
myPort = new Serial(this, Serial.list()[0], 9600);
myPort.bufferUntil('\n');
cp5 = new ControlP5(this);
cp5.addSlider("hMin").setPosition(20, 20).setRange(0, 50).setValue(hMin);
cp5.addSlider("hMax").setPosition(20, 50).setRange(0, 50).setValue(hMax);
cp5.addSlider("tiempoControl").setPosition(20, 80).setRange(1, 60).setValue(tiempoControl);
textSize(14);
}
void draw() {
background(255);
fill(0);
text("Temperatura Ambiental (DHT11): " + nf(Tamb, 1, 2) + " °C", 20, 130);
text("Temperatura Celda (Termistor): " + nf(Tsup, 1, 2) + " °C", 20, 160);
text("Histéresis: [" + nf(hMin, 1, 1) + ", " + nf(hMax, 1, 1) + "] °C", 20, 190);
text("Tiempo de control: " + tiempoControl + " s", 20, 220);
historialTamb.add(Tamb);
historialTsup.add(Tsup);
if (historialTamb.size() > maxHist) {
historialTamb.remove(0);
historialTsup.remove(0);
}

stroke(200, 0, 0);
noFill();
beginShape();
for (int i = 0; i < historialTamb.size(); i++) {
float y = map(historialTamb.get(i), 0, 50, height - 50, 300);
vertex(50 + i * 2, y);
}
endShape();
stroke(0, 0, 200);
noFill();
beginShape();
for (int i = 0; i < historialTsup.size(); i++) {
float y = map(historialTsup.get(i), 0, 50, height - 50, 300);
vertex(50 + i * 2, y);
}
endShape();
stroke(0, 200, 0);
line(50, map(hMin, 0, 50, height - 50, 300), width - 50, map(hMin, 0, 50, height - 50, 300));
line(50, map(hMax, 0, 50, height - 50, 300), width - 50, map(hMax, 0, 50, height - 50, 300));
noStroke();
fill(0, 200, 0);
text("Histéresis", width - 120, map((hMin + hMax) / 2, 0, 50, height - 50, 300));
}
void serialEvent(Serial p) {
String data = p.readStringUntil('\n');
if (data != null) {
data = trim(data);
String[] valores = split(data, ',');
if (valores.length >= 2) {
Tamb = float(valores[0]);
Tsup = float(valores[1]);
  }
 }
}
