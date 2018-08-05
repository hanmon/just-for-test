ArrayList<SensorData> singleSensorArray=new ArrayList();
ArrayList<SensorData> renderSensorArray=null;
int sensorArraySize=0;
int showSize=50;
float[] xValues=new float[1000];
float[] yValues=new float[1000];
boolean refreshFlag=false;
//Read Sensor Data
String restReadSensorData(URL url) {
  String res=new String();

  try {
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("GET");
    con.setRequestProperty("CK", apiKey);

    con.connect();
    println("con"+con.getHeaderFields());
    InputStream is = con.getInputStream();
    InputStreamReader isr = new InputStreamReader(is);
    BufferedReader br = new BufferedReader(isr);
    res = br.readLine();
  }
  catch(Exception e) {
    e.toString();
  }
  //println("res:"+res);

  return res;
}

public class RestReadTask implements Runnable {
  private URL restURL;
  private String m=new String();

  public RestReadTask(URL url) {
    this.restURL=url;
  };
  public void run() {
    synchronized(host) {
      JSONObject json=new JSONObject();
      m=restReadSensorData(this.restURL);
      println("restURL:"+this.restURL);
      //System.out.println(m);
      try {
        json=parseJSONObject(m);
        if (json!=null) {
          println("JSON MESSAGE:"+json.toString());
          for (int i=0; i<sensors.size(); i++) {
            SensorData s=sensors.get(i);
            //print(json.getString("id"));
            //println(" vs."+ s.sensorId);
            if (json.getString("id").equals(s.sensorId.toString())) {
              //println("matched");
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
      }
      catch(Exception e) {
        println("illigal json format:"+m);
      }
    }
    try {
      Thread.sleep(5000L);
    }
    catch(Exception e) {
      e.toString();
    }
  };
}


public class RestReadIntervalTask implements Runnable {
  private URL restURL;
  private String m=new String();

  public RestReadIntervalTask(URL url, String startTime, String endTime) {
    this.restURL=url;
  };
  public void run() {
    synchronized(host) {
      JSONArray jsonArray=new JSONArray();
      m=restReadSensorData(this.restURL);
      println("restURL:"+this.restURL);
      //System.out.println(m);
      try {
        jsonArray=parseJSONArray(m);
        if (jsonArray!=null) {
          //println("JSON MESSAGE:"+jsonArray.toString());
          singleSensorArray.clear();
          for (int i=0; i<jsonArray.size(); i++) {
            JSONObject jsonObject=jsonArray.getJSONObject(i);
            //   println("JSONObject "+i+jsonObject.toString());
            println(jsonObject.getString("id"));
            println(jsonObject.getString("time"));
            println(jsonObject.getJSONArray("value").get(0).toString());
            SensorData s=new SensorData(jsonObject.getString("id"));
            s.time=new StringBuffer(jsonObject.getString("time"));
            s.value=new StringBuffer(jsonObject.getJSONArray("value").get(0).toString());
            singleSensorArray.add(s);
            Collections.sort(singleSensorArray);
          }
          int i=0;
          for (SensorData sd : singleSensorArray) {
            println("Time of Sensors "+i+"="+sd.time);
            println("Value of Sensors"+i+"="+sd.value);
            i++;
          }
          sensorArraySize=singleSensorArray.size();
          refreshFlag=true;
        }
      }
      catch(Exception e) {
        println(e.toString());
        //println("illigal json format:"+m);
      }
    }
    try {
      Thread.sleep(5000L);
    }
    catch(Exception e) {
      e.toString();
    }
  };
}


void renderLineChart(ArrayList<SensorData> sdList, String startTime, String endTime) {
  long xValue=0, xMinValue=0, xMaxValue=0;
  float  yMinValue=0, yMaxValue=0;
  int basePosX=width/8, basePosY=height*2/5;
  int xAxisLength=width*3/4, yAxisLength=width*1/3;
  int sdListSize=sdList.size();


  SimpleDateFormat sdfStart = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  SimpleDateFormat sdfEnd = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  SimpleDateFormat sdfPresent = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  try {
    Date dStart=sdfStart.parse(startTime);
    Date dEnd=sdfEnd.parse(endTime);
    xMinValue=dStart.getTime();
    xMaxValue=dEnd.getTime();

    //println("dStart"+dStart.toGMTString());
    //println("dEnd"+dEnd.toGMTString());
    //println("xMinValue"+xMinValue);
    //println("xMaxValue"+xMaxValue);
    //println("diff:"+(xMaxValue-xMinValue));
  }
  catch(Exception e) {
    println(e.toString());
  }

  stroke(255);
  line(basePosX, basePosY, basePosX, basePosY+yAxisLength);
  line(basePosX, basePosY+yAxisLength, basePosX+xAxisLength, basePosY+yAxisLength);
  if (refreshFlag==true) {
    //if (refreshFlag==true) {
    //SensorData sd1=Collections.max(singleSensorArray);
    //SensorData sd2=Collections.min(singleSensorArray);
    //yMinValue=parseFloat(sd1.value.toString());
    //yMaxValue=parseFloat(sd2.value.toString());
    //println("sdList.size()="+sdList.size());

    //println("xMinValue,xMaxValue:"+xMinValue+","+xMaxValue);


    for (int i=0; i<sdList.size(); i++) {

      SensorData sd=(SensorData)sdList.get(i);

      try {
        Date dPresent=sdfPresent.parse(sd.time.toString());
        //println("sd.time.toString()"+sd.time.toString());
        xValues[i]=dPresent.getTime();
        yValues[i]=parseFloat(sd.value.toString());
        //println("xValue:"+xValue);
        //println("diff:"+(xValue-xMinValue));
      }
      catch(Exception e) {
        e.toString();
      }

      //float x=basePosX+map(xValue, xMinValue, xMaxValue, 0, xAxisLength);
      //println("xValue:"+xValue);
      //println("diff:"+(xValue-xMinValue));
      //println("Timestamp:"+map(xValue/1000, xMinValue/1000, xMaxValue/1000, 0, 1));
      //println("Sensor value:"+sd.value.toString());

      //println("y mapping result:"+map(parseFloat(sd.value.toString()),0, 714, 0, yAxisLength));
    }
    refreshFlag=false;
  }
  noFill();
  stroke(204, 51, 0);
  beginShape();
  if (xValues.length>0) {
    int size=min(showSize, sensorArraySize);
    for (int i=0; i<size; i++) {
      float x=basePosX+map(size-i, 0, size, 0, xAxisLength);
      float y=basePosY+yAxisLength-map(yValues[sensorArraySize-i-1], min(yValues), max(yValues), 0, yAxisLength);
      textAlign(RIGHT);
      textSize(18);
      text(int(max(yValues)), basePosX-xAxisLength/40, basePosY);
      text(int(min(yValues)), basePosX-xAxisLength/40, basePosY+yAxisLength);

      //  rotate(-QUARTER_PI);
      //text(startTime,basePosX-xAxisLength/40,basePosY+yAxisLength);
      //text(endTime,basePosX+xAxisLength,basePosY+yAxisLength);
      //println("xValues[i],yValues[i]:"+xValues[i]+","+yValues[i]);
      //print("sensorArraySize:"+sensorArraySize+",");
      //   rotate(QUARTER_PI);
      vertex(x, y);
      stroke(255, 0, 192);
      ellipse(x, y, 3, 3);
      stroke(204, 51, 0);
    }
    endShape();
  }
  textAlign(RIGHT);
  textSize(12);
  pushMatrix();
  translate(basePosX-xAxisLength/40, basePosY+yAxisLength*1.05);
  rotate(-QUARTER_PI/2);
  text(startTime, 0, 0);
  popMatrix();
  pushMatrix();
  translate(basePosX+xAxisLength, basePosY+yAxisLength*1.05);
  rotate(-QUARTER_PI/2);
  text(endTime, 0, 0);
  //text(startTime,basePosX-xAxisLength/40,basePosY+yAxisLength);
  //translate(basePosX+xAxisLength,basePosY+yAxisLength);
  
  //rotate(QUARTER_PI);
  popMatrix();
  textSize(25);
}

float timeToNumeric(String timeStr) {
  SimpleDateFormat sdf=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  Date d=null;
  try {
    d=sdf.parse(timeStr);
  }
  catch (Exception e) {
    e.toString();
  }
  if (d!=null) {
    return d.getTime();
  } else
    return 0;
}
