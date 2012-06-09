/*
 * Modular Nixie Clock - Project by Federico Galli (2011)
 * Code by Riccardo and Federico Galli (2011)
 * Visit http://www.sideralis.org for source code and schematics
 *
 * Software source code is released under the
 * GPL License http://www.gnu.org/licenses/gpl.html
 *
 * Hardware boards, eagle cad files, and pictures are released under the
 * CC BY-NC-SA License http://creativecommons.org/licenses/by-nc-sa/3.0/
 */

#include "Tlc5940.h"
#include <WProgram.h>
#include <Wire.h>
#include <DS1307.h> // written by  mattt on the Arduino forum and modified by D. Sjunnesson

int aPin = A1; int bPin = 6; int cPin = 4; int dPin = 7; //sn74141 pin
int nixiePins[]={2,5,8,A0}; //output pins to AnodeControl Board
//TLC5940 pins are auto defined into the library
//A2 and A3 pin are still free for use (use them!)

int neonGrayScale=2000; //grayscale for nixie bulbs (seconds)
int grayScale;
long tempo;
boolean toggle=0;
int *time;
int minHour=2; //at 2am the display blanks
int maxHour=6; //at 2am the display switch on again
               //invert values to never blank the display
int tmpHour=-1;//base value must be a non valid number as hour
int red,green,blue=0;

int x=-1;
int colorsBrightness=2; //values from 0 (off) to 16 (full brightness)
int colors[][3] = {{255,140,0},{0,191,255},{186,85,211},{220,20,60},{0, 0, 255},
                   {124,252,0},{30,144,255},{255,10,0},{200,69,0},{60,179,113},
                   {34, 139, 34},{32, 178, 170},{148, 0, 211},{199, 21, 133},{218, 165, 32}
                  };

void setup()   {                
  Tlc.init();
  
  int sn74141Pins[]={aPin,bPin,cPin,dPin};
  for (int i=0; i<4; i++){
    pinMode(nixiePins[i],OUTPUT);
    pinMode(sn74141Pins[i],OUTPUT);
    digitalWrite(nixiePins[i],LOW);
  }
  
  time=(int*)malloc(sizeof(int)*5);
  
  Serial.begin(9600);
  time=getTime();
  tempo=millis();
  
  randomSeed(analogRead(A2)); //A2 is unconnected
  x=random(0,14); // this sucks but it works,sometimes.
}

void printTime(int *time){ //debug routine
    Serial.print("H ");
    Serial.print(time[0]);
    Serial.print(time[1]);
    Serial.print(" : M ");
    Serial.print(time[2]);
    Serial.print(time[3]);
    Serial.print(" : S ");
    Serial.println(time[4]);
}

void loop(){
  
  if (elapsed(500)) {
    getTime();
    updateNixieSeconds(time[4], grayScale);
    //printTime(time);
  }
  
  
  //if we are between minHour and maxHour we blank the display
  int actualHour=(time[0]*10)+time[1];
  if (actualHour!=tmpHour) {
    tmpHour=actualHour;
    //x+=1;
    
    x=random(0,14); // this suck.
    
    red=colors[x][0]*colorsBrightness;
    green=colors[x][1]*colorsBrightness;
    blue=colors[x][2]*colorsBrightness;
    //if (x==4) x=-1;
  }
  
  //let's see if the display should be on or off
  if ( actualHour >= minHour && actualHour <= maxHour) {
    blank();
    grayScale=0;
  }
  else {
    /*int randomizzato=(random(1,10000));
    if (randomizzato > random(1,50) && randomizzato < random(1,50) ) {
      blank();
      delay(random(1,100));
    }
    else {*/
      grayScale=neonGrayScale;
      updateNixieTime(time);
      
    //}
  }
  
  
}

void updateNixieSeconds(int seconds,int color){ //color is the grayscale
  Tlc.clear();
  for (int i=0;i<6;i++) {
      if (1<<i & seconds) Tlc.set(i, color);
  }
  
  //tlc.set from 6 to 11 is for leds. 
  Tlc.set(6,blue); //blu
  Tlc.set(7,green); //verde
  Tlc.set(8,red);//rosso
  
  //ore
  Tlc.set(9,blue); //blu
  Tlc.set(10,green); //verde
  Tlc.set(11,red); //rosso
  
  
  Tlc.update();
  
}

boolean elapsed(int milliseconds){
  long now=millis();
  //return tempo+milliseconds < (tempo=millis());
  if (tempo+milliseconds < now) {
    tempo=now;
    return true;
  } else return false;
}

void updateNixieTime(int *time){
   for(int i=0;i<4;i++){
     digitalWrite(nixiePins[i],HIGH);
     sn74141pilot(time[i]);
     delay(1);
     digitalWrite(nixiePins[i],LOW);
   }
}

void blank(){ 
  sn74141pilot(15); //1111
  delay(5);
}

void sn74141pilot(int num){
  digitalWrite(aPin, B0001&num);
  digitalWrite(bPin, B0010&num);
  digitalWrite(cPin, B0100&num);
  digitalWrite(dPin, B1000&num);
}

int *getTime(){
  int ora=RTC.get(DS1307_HR,true);
  int minuto=RTC.get(DS1307_MIN,false);
  int secondo=RTC.get(DS1307_SEC,false);
     
  time[0]=ora/10;
  time[1]=ora%10;
  time[2]=minuto/10;
  time[3]=minuto%10;
  time[4]=secondo;
  
  return time;
}

void debugDate(){
  Serial.print(RTC.get(DS1307_HR,true));   //read the hour and also update all the values by pushing in true
  Serial.print(":");
  Serial.print(RTC.get(DS1307_MIN,false)); //read minutes without update (false)
  Serial.print(":");
  Serial.print(RTC.get(DS1307_SEC,false)); //read seconds
  Serial.print("      ");                  // some space for a more happy life
  Serial.print(RTC.get(DS1307_DATE,false));//read date
  Serial.print("/");
  Serial.print(RTC.get(DS1307_MTH,false)); //read month
  Serial.print("/");
  Serial.print(RTC.get(DS1307_YR,false));  //read year 
  Serial.println();
}

/* //test for random blink
void brokenMode(){
  //randomSeed(analogRead(0));
  if (millis()-tempo <= 500) {
    //zero();
    delay(random(1,100));
    blank();
  }
  else if (millis()-tempo <= 1000) {
    //zero();
    delay(random(1,500));
    blank();
  }
}
*/
