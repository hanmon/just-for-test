ArrayList<SensorData> singleSensorArray=new ArrayList();
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
  println("res:"+res);

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
          println("JSON MESSAGE:"+jsonArray.toString());
          singleSensorArray.clear();
          for (int i=0; i<jsonArray.size(); i++) {
            JSONObject jsonObject=jsonArray.getJSONObject(i);
            println("JSONObject "+i+jsonObject.toString());
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
  float xValue=0,xMinValue=0, xMaxValue=0, yMinValue=0, yMaxValue=0;
  int basePosX=width/8, basePosY=height*2/5;
  int xAxisLength=width*3/4, yAxisLength=width*1/3;

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
  if (sdList.size()!=0) {
    //SensorData sd1=Collections.max(singleSensorArray);
    //SensorData sd2=Collections.min(singleSensorArray);
    //yMinValue=parseFloat(sd1.value.toString());
    //yMaxValue=parseFloat(sd2.value.toString());
    println("sdList.size()="+sdList.size());
    noFill();
    stroke(204, 51, 0);
    beginShape();
    println("yMinValue,yMaxValue:"+yMinValue+","+yMaxValue);
    for (int i=0; i<sdList.size(); i++) {

      SensorData sd=(SensorData)sdList.get(i);
      
      try{
        Date dPresent=sdfPresent.parse(sd.time.toString());
        //println("sd.time.toString()"+sd.time.toString());
        xValue=dPresent.getTime();
        //println("xValue:"+xValue);
        //println("diff:"+(xValue-xMinValue));
      }
      catch(Exception e){
        e.toString();
      }
      
      float x=basePosX+map(xValue, xMinValue, xMaxValue, 0, xAxisLength);
      float y=basePosY+yAxisLength-map(parseFloat(sd.value.toString()), -1000, 1000, 0, yAxisLength);
      vertex(x, y);
    }
    endShape();
  }
}

float timeToNumeric(String timeStr){
  SimpleDateFormat sdf=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  Date d=null;
  try{
    d=sdf.parse(timeStr);
  }
  catch (Exception e){
    e.toString();
  }
  if (d!=null){
   return d.getTime(); 
  }
  else
    return 0;
}