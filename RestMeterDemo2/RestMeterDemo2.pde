import processing.serial.*;
import java.util.*;
import java.text.*;
import java.io.FileWriter;
import java.net.URL;
import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import com.cht.iot.service.api.*;
import com.cht.iot.persistence.entity.data.Rawdata;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttClientPersistence;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MqttDefaultFilePersistence;

PShape bulbOff, bulbOn, carShape;
PImage powerImg;
Serial serialPort; // Create object from Serial class
float val=0, pval=0; // Data received from the serial port
boolean ledStatus=false;
//SensorData sensorData;
//ArrayList sensorDataArray;
ArrayList<SensorData> sensors;

float svgHeight=140, svgWidth=100;
final String host = "iot.cht.com.tw";
final int port = 1883;
final String apiKey = "";  //Fill your api key here
//final String apiKey = "";  //Test Device KEY
//final String topic = "";
String deviceId = ""; //Device ID 
String baseURL="http://iot.cht.com.tw/iot";
String topicString = "/v1/device/" + deviceId + "/sensor/+/rawdata";
//String sensorId[]={"instantaneous_kva","lastGasp","event","current_date_and_time",
//                    "instantaneous_kw","LoadProfile","Midnight","Alt","tpcDelTotalWh"};
String sensorId[]={"instantaneous_kva", "instantaneous_kw", "tpcDelTotalWh", "current_date_and_time"};
String sensorName[]={"瞬時功率", "瞬時需量", "總瓦時", "電表時間"};
HashMap<String, String> sensorMap=new HashMap();
long timeStamp=0, latestTimeStamp=0;
//current_date_and_time: 電表時間, instantaneous_kva:瞬時功率,instantaneous_kw: 瞬時需量,tpcDelTotalWh:總瓦時
//String sensorId[]={"Humidity","switch","temperature"};            
StringBuffer startTime=new StringBuffer("2018-08-04T08:00:00Z");
StringBuffer endTime=new StringBuffer("2018-08-04T09:00:00Z");

void setup() {
  //carShape=loadShape("liakad-car-front.svg");
  //bulbOn=loadShape("bulbOn.svg");
  //bulbOff=loadShape("bulbOff.svg");
  //PFont font=createFont("Noto Sans CJK",20);
  //For Linux OS
  PFont font=createFont("/usr/share/fonts/NotoSansCJK-Regular/NotoSansCJK-Regular.ttc", 25);
  textFont(font, 25);

  powerImg=loadImage("power-thumb.png");
  for (int i=0; i<sensorId.length; i++) {
    sensorMap.put(sensorId[i], sensorName[i]);
  }

  timeStamp=millis(); 
  sensors=new ArrayList<SensorData>();
  for (String str : sensorId) {
    sensors.add(new SensorData(str));
    println(str+" added");
  }
  size(1024, 768);
  frameRate(30);
  strokeWeight(2);
  //String arduinoPort = Serial.list()[2];
  //serialPort = new Serial(this, arduinoPort, 9600);
  background(#FFFFFF);
  try {
    LedControlMqttTest();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

void draw() {

  //background(#FFFFFF);
  background(204);
  imageMode(CENTER);
  image(powerImg, width/5, height/5, powerImg.width/4, powerImg.height/4);
  textAlign(LEFT);
  
  //textSize(30);
  fill(#030303);
  for (int i=0; i<sensors.size(); i++) {
    SensorData s=sensors.get(i);
    int step=powerImg.height/(4*sensors.size());
    //if(i<5)
    //  s.render(powerImg.width/5,powerImg.height/5,(i%4+1)*width/5,height/5);
    //else
    s.render(powerImg.width/5, powerImg.height/5, width/5+powerImg.width/8, height/10+step*i);
  }

  if (millis()-timeStamp>5000) {
    //for(String sid:sensorId){
    try {
      //URL url=new URL(baseURL+"/v1/device/" +deviceId + "/sensor/"+ sid + "/rawdata");
      startTime=new StringBuffer();
      Calendar cal = Calendar.getInstance();
      SimpleDateFormat sdfNow = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
   
      cal.add(Calendar.HOUR, -8);
      endTime=new StringBuffer(sdfNow.format(cal.getTime()));
      cal.add(Calendar.HOUR, -1);
      startTime=new StringBuffer(sdfNow.format(cal.getTime()));
      print("start,end:"+startTime+endTime);
      URL url=new URL(baseURL+"/v1/device/" +deviceId + "/sensor/"+ "instantaneous_kva" + "/rawdata?"+"start="+startTime+"&end="+endTime);
      //Thread readThread=new Thread(new RestReadTask(url));
      println("URL:"+url);
      Thread readThread=new Thread(new RestReadIntervalTask(url, startTime.toString(), endTime.toString()));
      readThread.setName("instantaneous_kva");
      //readThread.setName(sid);
      readThread.start();
      //update sensors
      try {
        LedControlMqttTest();
      }
      catch (Exception e) {
        e.printStackTrace();
      }
      
    }
    catch(Exception e) {
    }
    // }
    timeStamp=millis();
  } else if (millis()-timeStamp<0) {
    timeStamp=millis();
  }
  
    renderLineChart(singleSensorArray, startTime.toString(), endTime.toString());
  
}


void LedControlMqttTest() throws Exception {
  MqttClientPersistence mcp = new MqttDefaultFilePersistence(System.getProperty("java.io.tmpdir")); // should not be null
  MqttClient client = new MqttClient("tcp://iot.cht.com.tw:1883", MqttClient.generateClientId(), mcp);
  println(MqttClient.generateClientId());
  client.setCallback(new MqttCallback() {

    public void messageArrived(String topic, MqttMessage message) throws Exception {
      String m = new String(message.getPayload());
      System.out.println(m);
      JSONObject json=parseJSONObject(m); 
      for (int i=0; i<sensors.size(); i++) {
        SensorData s=sensors.get(i);
        print(json.getString("id"));
        println(" vs."+ s.sensorId);
        if (json.getString("id").equals(s.sensorId.toString())) {
          println("matched");
          //s.deviceId=
          //sensorData.sensorId=new StringBuffer(json.getString("id"));
          s.deviceId=new StringBuffer(json.getString("deviceId"));
          JSONArray jsonArray=json.getJSONArray("value");
          //println(jsonArray.toString());
          s.value=new StringBuffer(jsonArray.get(0).toString());
          sensors.set(i, s);
        }
      }
    }

    public void deliveryComplete(IMqttDeliveryToken token) {
    }

    public void connectionLost(Throwable cause) {
    }
  }
  );
  MqttConnectOptions opts = new MqttConnectOptions();
  opts.setUserName(apiKey);
  opts.setPassword(apiKey.toCharArray());
  opts.setConnectionTimeout(5);
  opts.setKeepAliveInterval(60);    
  opts.setCleanSession(true);

  client.connect(opts);

  //client.subscribe("/v1/device/" + deviceId + "/sensor/" + sensorId + "/rawdata");
  ArrayList<String> topic_array=new ArrayList();
  for (String sid : sensorId) {
    topic_array.add("/v1/device/" +deviceId + "/sensor/"+ sid + "/rawdata");
  }
  String[] topic_str_array=topic_array.toArray(new String[0]);
  println(topic_str_array);
  client.subscribe(topic_str_array);  
  //client.subscribe(topicString);
}

class SensorData implements Comparable<SensorData> {
  StringBuffer sensorId;
  StringBuffer deviceId;
  StringBuffer time;
  StringBuffer value;
  public int compareTo(SensorData otherSd) {
    //write code here for compare value
    float result=timeToNumeric(this.value.toString())-timeToNumeric(otherSd.value.toString());
    if (result>0)
      return 1;
    else if (result<0)
      return -1;
    else
      return 0;
  }
  SensorData(String sid) {
    sensorId=new StringBuffer(sid);
    deviceId=new StringBuffer("--");
    time=new StringBuffer("--");
    value=new StringBuffer("--");
  }
  SensorData setSensorId(String sid) {
    sensorId.replace(0, sensorId.length()-1, sid);
    return this;
  }
  SensorData setdeviceId(String did) {
    sensorId.replace(0, deviceId.length()-1, did);
    return this;
  }
  SensorData setTime(String t) {
    sensorId.replace(0, time.length()-1, t);
    return this;
  }
  SensorData setValue(String v) {
    sensorId.replace(0, value.length()-1, v);
    return this;
  }

  void render(int sizeX, int sizeY, int posX, int posY, PImage img) {
    image(img, posX, posY, sizeX, sizeY);
    text("DEVICE ID:"+deviceId, posX, posY+sizeY/2+sizeY/5);
    text("SENSOR ID:"+sensorId, posX, posY+sizeY/2+sizeY*2/5);
    text("VALUE:"+value, posX, posY+sizeY/2+sizeY*3/5);
  }

  void render(int sizeX, int sizeY, int posX, int posY) {
    //text("DEVICE ID:"+deviceId,posX,posY+sizeY/4+sizeY/5);
    text(sensorMap.get(sensorId.toString())+":"+value, posX, posY);
    //text("VALUE:"+value,posX,posY+sizeY/2+sizeY*3/5);
  }
}
