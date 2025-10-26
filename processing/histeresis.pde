import processing.serial.*;
import controlP5.*;
import java.text.SimpleDateFormat;
import java.util.Date;

Serial myPort;
ControlP5 cp5;

float Tamb=0, Tsup=0;
float consigna=0, dT1=0, dT2=0;

boolean peltierON=false, fanON=false;
boolean isLogging=false;
PrintWriter output;
String currentFileName="data_log.txt";
int startTime;

ArrayList<Float> histTamb=new ArrayList<Float>();
ArrayList<Float> histTsup=new ArrayList<Float>();
int maxHist=600;

Button btnGuardar, btnVentilador, btnGuardarGrafica;
Textfield txtConsigna, txtDT1, txtDT2, txtFile;

void setup() {
  size(950,600);
  surface.setTitle("Práctica de Laboratorio - Histéresis");
  textFont(createFont("Arial",14));

  println(Serial.list());
  myPort=new Serial(this, Serial.list()[0],9600);
  myPort.bufferUntil('\n');

  cp5 = new ControlP5(this);

  txtConsigna=cp5.addTextfield("Consigna").setPosition(40,100).setSize(200,30).setText(str(consigna)).setAutoClear(false);
  txtDT1=cp5.addTextfield("dT1").setPosition(40,150).setSize(200,30).setText(str(dT1)).setAutoClear(false);
  txtDT2=cp5.addTextfield("dT2").setPosition(40,200).setSize(200,30).setText(str(dT2)).setAutoClear(false);
  txtFile=cp5.addTextfield("Archivo").setPosition(40,250).setSize(200,30).setText(currentFileName).setAutoClear(false);

  // 🔹 Ocultar labels automáticos que causaban el texto blanco
  txtConsigna.getCaptionLabel().hide();
  txtDT1.getCaptionLabel().hide();
  txtDT2.getCaptionLabel().hide();
  txtFile.getCaptionLabel().hide();

  btnGuardar=cp5.addButton("toggleGuardar").setPosition(40,300).setSize(200,40)
    .setLabel("Iniciar ensayo").setColorBackground(color(200,0,0))
    .setFont(createFont("Arial Bold",16));
    
  btnVentilador=cp5.addButton("toggleVentilador").setPosition(40,360).setSize(200,40)
    .setLabel("Ventilador OFF").setColorBackground(color(200,0,0))
    .setFont(createFont("Arial Bold",16));
    
  btnGuardarGrafica=cp5.addButton("guardarGrafica").setPosition(40,420).setSize(200,40)
    .setLabel("Guardar gráfica").setColorBackground(color(0,120,200))
    .setFont(createFont("Arial Bold",16));
}


void draw() {
  background(240); 
  fill(255); noStroke(); rect(20,80,245,400,10); 

  // Títulos alineados
  textAlign(LEFT);
  textSize(22); fill(0,70,130); text("Práctica de laboratorio",40,40);
  textSize(16); text("Histéresis",40,60);

  // Etiquetas campos (10% más pequeñas)
  fill(0); textSize(11);
  text("Consigna (°C)",40,95); 
  text("ΔT1 (°C)",40,145); 
  text("ΔT2 (°C)",40,195); 
  text("Archivo de datos",40,245);

  // Datos sensores
  textSize(15); fill(0);
  text("Temp. Ambiental: "+nf(Tamb,1,2)+" °C",320,110);
  text("Temp. Celda: "+nf(Tsup,1,2)+" °C",320,140);

  // Tiempo ensayo
  textSize(13); fill(50);
  if(isLogging){
    int elapsed=(millis()-startTime)/1000; 
    int min=elapsed/60; 
    int sec=elapsed%60;
    text("Tiempo ensayo: "+nf(min,2)+":"+nf(sec,2),320,170);
  }

  // Estado Peltier automático
  textSize(15); 
  fill(peltierON?color(0,180,0):color(200,0,0));
  text("Peltier "+(peltierON?"ON":"OFF"),320,200);

  drawGraph();

  // Estado grabación debajo del botón, alineado
  textSize(13);
  if(isLogging){ 
    fill(150,0,0); textSize(11);
    text("Grabando en: "+currentFileName,102,350);
  } else { 
    fill(150,0,0); textSize(11);
    text("Ensayo detenido",80,350);
  }
}

void drawGraph(){
  int gx=320,gy=220,gw=600,gh=280;
  fill(255); stroke(180); rect(gx,gy,gw,gh,10);

  // Escala 10 a 30 °C
  float tMin=10, tMax=30;

  // Cuadrícula interna con números
  stroke(220);
  for(float t=10; t<=30; t+=2){
    float y=map(t,tMin,tMax,gy+gh,gy);
    line(gx,y,gx+gw,y);
    fill(0); textSize(10); textAlign(RIGHT); text(nf(t,2,0), gx-8, y+4);
  }
  for(int i=0;i<=10;i++){
    float x=map(i,0,10,gx,gx+gw);
    line(x,gy,x,gy+gh);
    fill(0); textSize(10); textAlign(CENTER);
    text(nf(i*10,2,0), x, gy+gh+15);
  }

  // Líneas consigna e histéresis
  float yCons=map(consigna,tMin,tMax,gy+gh,gy);
  float yMax=map(consigna+dT1,tMin,tMax,gy+gh,gy);
  float yMin=map(consigna-dT2,tMin,tMax,gy+gh,gy);

  stroke(0,0,180,150); strokeWeight(2); line(gx,yCons,gx+gw,yCons);
  stroke(0,150,150,120); line(gx,yMax,gx+gw,yMax); line(gx,yMin,gx+gw,yMin);
  noStroke(); fill(0,150,150,40); rect(gx,yMin,gw,yMax-yMin);

  // Líneas de temperatura (dentro del área)
  strokeWeight(2);
  if(histTamb.size()>1){ 
    stroke(200,0,0); noFill(); 
    beginShape();
    for(int i=0;i<histTamb.size();i++){ 
      float y=map(histTamb.get(i),tMin,tMax,gy+gh,gy); 
      float x=map(i,0,maxHist,gx,gx+gw); 
      vertex(x,y);
    } 
    endShape();
  }
  if(histTsup.size()>1){ 
    stroke(0,180,0); noFill(); 
    beginShape();
    for(int i=0;i<histTsup.size();i++){ 
      float y=map(histTsup.get(i),tMin,tMax,gy+gh,gy); 
      float x=map(i,0,maxHist,gx,gx+gw); 
      vertex(x,y);
    } 
    endShape();
  }

  // Leyenda más cerca del gráfico
  fill(200,0,0); rect(gx+570, gy-70, 15,15); fill(0); text("Temp. Ambiental", gx+520, gy-58);
  fill(0,180,0); rect(gx+570, gy-50, 15,15); fill(0); text("Temp. Celda", gx+510, gy-38);
  fill(0,0,180); rect(gx+570, gy-30, 15,15); fill(0); text("Temp. Consigna", gx+518, gy-18);

  // Ejes más cercanos y visibles
  fill(0); textSize(11); textAlign(CENTER);
  pushMatrix(); 
  translate(gx-28,gy+gh/2); 
  rotate(-HALF_PI); 
  text("Temperatura (°C)",0,0); 
  popMatrix();
  text("Tiempo (s)", gx+gw/2, gy+gh+35);

  if(histTamb.size()>maxHist){ 
    histTamb.remove(0); 
    histTsup.remove(0);
  }
}

// Serial
void serialEvent(Serial p){
  String data=p.readStringUntil('\n');
  if(data!=null){
    data=trim(data); 
    String[] valores=split(data,',');
    if(valores.length>=4){
      Tamb=float(valores[0]); 
      Tsup=float(valores[1]);
      peltierON=valores[2].equals("1"); 
      fanON=valores[3].equals("1");

      histTamb.add(Tamb); 
      histTsup.add(Tsup);

      if(isLogging && output!=null) 
        output.println(getTimestamp()+" "+Tamb+" "+Tsup);
    }
  }
}

// Botones
void toggleGuardar(){ 
  if(!isLogging){
    consigna = float(txtConsigna.getText());
    dT1 = float(txtDT1.getText());
    dT2 = float(txtDT2.getText());
    
    currentFileName=txtFile.getText();
    output=createWriter(currentFileName);
    startTime=millis();
    isLogging=true;
    btnGuardar.setColorBackground(color(0,180,0));
    btnGuardar.setLabel("Detener ensayo");
    
    // Activa Peltier automática
    myPort.write("SET,"+consigna+","+dT1+","+dT2+"\n"); 
  } else {
    output.flush();
    output.close();
    isLogging=false;
    btnGuardar.setColorBackground(color(200,0,0));
    btnGuardar.setLabel("Iniciar ensayo");
  }
}

void toggleVentilador(){
  fanON=!fanON;
  if(fanON){ 
    btnVentilador.setLabel("Ventilador ON"); 
    btnVentilador.setColorBackground(color(0,180,0)); 
    myPort.write("FAN_ON\n");
  }
  else{ 
    btnVentilador.setLabel("Ventilador OFF"); 
    btnVentilador.setColorBackground(color(200,0,0)); 
    myPort.write("FAN_OFF\n");
  }
}

void guardarGrafica(){
  String nombreImg="grafica_"+year()+"-"+month()+"-"+day()+"_"+hour()+"-"+minute()+"-"+second()+".png";
  saveFrame(nombreImg);
  println("Gráfica guardada como "+nombreImg);
}

String getTimestamp(){
  return new SimpleDateFormat("HH:mm:ss").format(new Date());
}
