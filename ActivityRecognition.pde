/* With R, you have to do:
 install.packages(c("Rserve","data.table"))
 library(Rserve); Rserve(args="--no-save")
 and then you can see the R console logs there!
 */
import org.rosuda.REngine.Rserve.*;
import org.rosuda.REngine.*;
import hypermedia.net.*;

double[] data;

String[] acts = {
  //"0:None", "1:Byuun", "2:Bokaan", "3:Tekuteku"
  "0:None", "1:Put", "2:Take", "3:Stay", "4:Stand up", "5:Walk", "6:Peace", 
  "7:Hello", "8:Phone", "9:Sit down", 
  //"z:Help stand", "x:Cleaning", "c:Clothing", "v:Jump", "b:", "n:", "m:"
};



String datafile;//r data file

float scale=1.5;

RConnection r;

void settings() {
  size((int)(640*scale), (int)(400*scale));
}

void setup() {
  datafile = dataPath("data.rdata");

  //textFont(loadFont("MS-Gothic-32.vlw"), 32);




  ///// UDP 
  udp = new UDP( this, 6667);
  //udp.log( true ); // printout the connection activity
  udp.listen( true );


  try {
    r = new RConnection();
    println(r.eval("getwd()").asString());
    r.eval("library(data.table)");
    r.eval("library(randomForest)");

    def_functions();
    r.eval("cat(123);");
  
    //r.eval("df=data.frame()");
  } 
  catch ( Exception e ) {
    println("Could not connect to Rserve()!");
    exit();
    e.printStackTrace();
  }
  smooth();
}

void draw() {
  scale(scale);
  background(0);



  stroke(255);



  text("Key: L:Load  0-9,Z-B:Label  T:Train  S:Save", 380, 380);  


  //sensor data
  sensors.push(accX, accY, accZ);
  //gyros.push(gyroX, gyroY, gyroZ);
  mags.push(magX, magY, magZ);
  oris.push(oriX, oriY, oriZ);
  lights.push(light);
  bleAccs.push(bleAccX, bleAccY, bleAccZ);
  bleIrts.push(bleIrtAmb, bleIrtTarget);
  bleHums.push(bleHum);
  bleOpts.push(bleOpt);
  bleMags.push(bleMagX, bleMagY, bleMagZ);
  bleBars.push(bleBar);


  //println(bleMagZ);


  sensors.drawGrid();
  sensors.draw(0, -70, 20, "Accel");
  mags.draw(0, -30, 0.1, "Magnetism");
  oris.draw(0, -10, 0.1, "Orientation");
  lights.draw(0, 0, 0.1, "Light");
  //gyros.draw(0, 50, 1.0, "Gyro");


  /*bleAccs.draw(0, 20, 20, "BLE_Accel");//height is offset
  bleIrts.draw(0, 50, 0.1, "BLE_IRTemperature", #E80CB5, #5BE80C, #5BE80C);//height is offset
  bleHums.draw(0, 60, 0.1, "BLE_Humidity", #FFB700, #FFB700, #FFB700);//height is offset
  bleOpts.draw(0, 70, 0.01, "BLE_Optical", #FEFF00, #FEFF00, #FEFF00);//height is offset
  bleMags.draw(0, 80, 0.1, "BLE_Magnetism", #E86B0C, #800CE8, #0C2EE8);//height is offset
  bleBars.draw(0, 90, 0.1, "BLE_Barometer", #0CE8D4, #0CE8D4, #0CE8D4);//height is offset
*/
  try {

    // Add data frame


    //int nskip = 9; //9 skip +1 sample -> 10Hz (originally 100Hz) 
    // 10 Hz x 20 samples = 2 sec.

    //String csv = sensors.toCSV(nsample, nskip); //ios
    String csv = sensors.toCSV(); //android 
    String csv2 = bleAccs.toCSV(); //android
    //String csvGyro = gyros.toCSV(); //android
    String csvMag = mags.toCSV(); //android
    String csvOri = oris.toCSV(); //android
    String csvLight = lights.toCSV(); //android
    String csvBleIrt = bleIrts.toCSV(); //android
    String csvBleHum = bleHums.toCSV(); //android
    String csvBleOpt = bleOpts.toCSV(); //android
    String csvBleMag = bleMags.toCSV(); //android
    String csvBleBar = bleBars.toCSV(); //android


    //println(csv+csv2);

    //if (csv!=null) { // works even csv2 is null.

    r.eval("tmp=data.frame(act="+act+","+ csv+","+csv2+","+
      //csvGyro + "," + 
      csvMag +"," + csvOri + "," + csvLight +"," + 
      csvBleIrt + "," + csvBleHum +","+csvBleOpt+","+csvBleMag+","+csvBleBar+")");  //gives NAs if no data.




    //println("csv: tmp=data.frame(act="+act+","+ csv+","+csv2+")");
    //println(sensors.names(nsample));

    r.eval("colnames(tmp)=c('act'"+
      ",paste('ACC',    c("+sensors.names()+"),sep='_')"+
      ",paste('BLEACC', c("+bleAccs.names()+"),sep='_')"+
      //",paste('GYRO', c("+gyros.names()+"),sep='_')"+
      ",paste('MAG', c("+mags.names()+"),sep='_')"+
      ",paste('ORI', c("+oris.names()+"),sep='_')"+
      ",paste('LIGHT', c("+lights.names()+"),sep='_')"+
      ",paste('BLEIRT', c("+bleIrts.names()+"),sep='_')"+
      ",paste('BLEHUM', c("+bleHums.names()+"),sep='_')"+
      ",paste('BLEOPT', c("+bleOpts.names()+"),sep='_')"+
      ",paste('BLEMAG', c("+bleMags.names()+"),sep='_')"+
      ",paste('BLEBAR', c("+bleBars.names()+"),sep='_')"+
      ")");


    r.eval("df = rbind(df, tmp)");


    // display if training
    if (act>=0) {
      fill(255, 0, 0);
      textSize(32);
      text(acts[act]+" ", 350, 50); //current activity
    }

    setStatus(status);

    drawAccuracy();

    //predict
    if (trained) {

      r.eval("test = tail(df,1); test[is.na(test)]=0"); //fill with 0 for the na values

      r.eval("test = calc_features(test)");
      r.eval("test[is.na(test)]=0"); //set 0 for NA values?


      int pre = r.eval("as.integer(as.character(predict(model,test)))").asInteger();


      double prob = r.eval("sqrt(max(predict(model, test,type='prob')))").asDouble();


      r.eval("pre = predict(model, test,type='prob')");
      double[] probs = r.eval("pre").asDoubles();
      int[] keys = r.eval("as.integer(colnames(pre))").asIntegers();


      fill((int)(((prob*255))));
      textSize((int)(prob*100));
      text(acts[pre]+" ", 120, 320);

      stroke(0);
      for (int i=0; i<probs.length; i++) {
        //println(keys[i]);
        if (i > keys.length) continue;
        //fill((int)(((probs[i]*255))));
        fill(200);
        rect(70, 204+keys[i]*8, (int)(probs[i]*100/2), 8);// graph
      }
    } 
    // acts list
    fill(200);
    textSize(8);
    for (int i=0; i<acts.length; i++) text(acts[i], 5, 210+i*8);
  } 
  catch ( Exception e ) {
    e.printStackTrace();
  }


  //println(" Freq:" + 1000/(millis()-prevms)+" Hz"); //frequency
}
boolean trained = false;


int act=-1; //current action
void keyPressed() {
  switch (key) {
  case '0':
    act=0;
    break;
  case '1':
    act=1;
    break;
  case '2':
    act=2;
    break;
  case '3':
    act=3;
    break;
  case '4':
    act=4;
    break;
  case '5':
    act=5;
    break;
  case '6':
    act=6;
    break;
  case '7':
    act=7;
    break;
  case '8':
    act=8;
    break;
  case '9':
    act=9;
    break;
  case 'z':
    act=10;
    break;
  case 'x':
    act=11;
    break;
  case 'c':
    act=12;
    break;
  case 'v':
    act=13;
    break;
  case 'b':
    act=14;
    break;
  case ' ': //no action
    act=0;
    break;
  case 't': //learn
    act=0;
    setStatus("Training.");
    if (train()) 
      setStatus("Training. Done.");
    else setStatus("Training. Failed.");
    break;
  case 's': //save
    setStatus("Saving.");
    save();
    setStatus("Saving. Done.");
    break;
  case 'l': //load
    setStatus("Loading.");
    load();
    setStatus("Loading. Done.");
    break;
  default:
    break;
  }
}

String status="";


void setStatus(String s) {
  status = s; 

  fill(200, 200, 200);
  textSize(12);
  text(status, 500, 395); //current activity
}


void drawAccuracy() {
  fill(#90E8FF);
  textSize(32);
  //text("Gamification Score:"+ (int)(accuracy*accuracy)/100, 5, 395); //current activity
}

double accuracy=0;

boolean train() {
  try {

    r.eval("df = df[df$act!=0,]"); //omit null act samples.
    r.eval("df = df[!apply(is.na(df[-1]), 1, all),]"); //omit all null samples
    r.eval("df[is.na(df)]=0"); //set 0 for NA values?
    //r.eval("df = na.omit(df)");

    r.eval("df$act=factor(df$act)");




    //r.eval("train.mx = sparse.model.matrix(act~., df)");
    //r.eval("dtrain = xgb.DMatrix(train.mx, label=df$act)");

    //r.eval("model = xgb.train(params=list(objective='multi:softmax', num_class=10,eval_metric='mlogloss', eta=0.2, max_depth=5, subsample=1, colsample_bytree=0.5), data=dtrain, nrounds=150)");

    r.eval("tmp = calc_features(df)");
    r.eval("tmp[is.na(tmp)]=0"); //set 0 for NA values?
    r.eval("print(summary(tmp))");

    r.eval("model = randomForest(act~., tmp)");
    r.eval("print(model$importance)");
    r.eval("print(model)");

    r.eval("df$act=as.integer(as.character(df$act))");

    accuracy = r.eval("round((1 - mean(model$err.rate))*100, digit=2)").asDouble();
    println("Trained.");
    trained=true;
  } 
  catch ( Exception e ) {
    e.printStackTrace();
    trained=false;
  }
  return trained;
}


void def_functions() {

  String commands = "calc_features=function(df){"+ 
    "df2 = data.frame(lapply(0:9, function(i)df[,sprintf('ACC_X%d',i)]^2 + df[,sprintf('ACC_Y%d',i)]^2+df[,sprintf('ACC_Z%d',i)]^2 ))\n"+
    "colnames(df2)=paste('ACC_intense', 0:9, sep='_')\n"+
    "df3 = data.frame(lapply(0:9, function(i)df[, sprintf('BLEACC_X%d', i)]^2 + df[, sprintf('BLEACC_Y%d', i)]^2+df[, sprintf('BLEACC_Z%d', i)]^2 ))\n"+
    "colnames(df3)=paste('BLEACC_intense', 0:9, sep='_')\n"+

    "x = df[, 'ACC_X0'];y = df[, 'ACC_Y0'];z = df[, 'ACC_Z0']\n"+

    "mx = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('ACC_X%d', i)]))))\n"+
    "my = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('ACC_Y%d', i)]))))\n"+
    "mz = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('ACC_Z%d', i)]))))\n"+

    "ACC_tx = atan(y/z) - atan(my/mz)\n"+
    "ACC_ty = atan(z/x) - atan(mz/mx)\n"+
    "ACC_tz = atan(x/y) - atan(mx/my )\n"+

    "df4 = data.frame(ACC_tx, ACC_ty, ACC_tz)\n"+  


    "x = df[, 'BLEACC_X0']\n"+
    "y = df[, 'BLEACC_Y0']\n"+
    "z = df[, 'BLEACC_Z0']\n"+
    "mx = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('BLEACC_X%d', i)]))))\n"+
    "my = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('BLEACC_Y%d', i)]))))\n"+
    "mz = rowMeans(data.frame(lapply(0:9, function(i)(df[, sprintf('BLEACC_Z%d', i)]))))\n"+

    "BLEACC_tx = atan(y/z) - atan(my/mz)\n"+
    "BLEACC_ty = atan(z/x) - atan(mz/mx)\n"+
    "BLEACC_tz = atan(x/y) - atan(mx/my)\n"+
    "df5 = data.frame(BLEACC_tx, BLEACC_ty, BLEACC_tz)\n"+
    "return(cbind(df,df2,df3,df4,df5))}\n";
  //1:31はtmp
  //"//  model2 = randomForest(act~., cbind(df, df2,df3,df4,df5))\n";

  //println(commands);

  try {
    r.eval(commands);
  } 
  catch (Exception e) {
    e.printStackTrace();
  }
}


void save() {
  try {
    r.eval("save(df,model,file='"+datafile+"')");  
    println("Saved.");
  }
  catch ( Exception e ) {
    e.printStackTrace();
  }
}


void load() {
  try {
    println(datafile);
    r.eval("load('"+datafile+"')");
    //r.eval("str(model)");  
    println("Loaded.");
    //r.eval("str(df)");
    r.eval("df[is.na(df)]=0"); // set 0 for na values.
    r.eval("print(model)");
    trained=true;
  }
  catch ( Exception e ) {
    e.printStackTrace();
  }
}


float accX, accY, accZ, bleAccX, bleAccY, bleAccZ;
float gyroX, gyroY, gyroZ;
float magX, magY, magZ, oriX, oriY, oriZ, light;
float bleIrtAmb, bleIrtTarget, bleIrt3, bleHum, bleOpt, bleTemp, bleBar;
float bleMagX, bleMagY, bleMagZ;


Sensors sensors = new Sensors(10);
Sensors gyros = new Sensors(10);
Sensors mags = new Sensors(1);
Sensors oris = new Sensors(1);
Sensors lights = new Sensors(1);
Sensors bleAccs = new Sensors(10);  //Accelerometer of BLEACC
Sensors bleIrts = new Sensors(1);  
Sensors bleHums = new Sensors(1);  
Sensors bleOpts = new Sensors(1); 
Sensors bleMags = new Sensors(1);
Sensors bleBars = new Sensors(1);

int prevms=0;
UDP udp;
///// UDP data
//// When Receive UDP data
void receive( byte[] data)
{
  String message = new String(data);
  //println(message);

  String mes[] = split(message, ',');
  println(message);

  if (mes[0].matches(".*acc")) {
    accX = Float.valueOf(mes[1]);
    accY = Float.valueOf(mes[2]);
    accZ = Float.valueOf(mes[3]);
    //sensors.push(accX, accY, accZ);
  /*} else if (mes[0].matches(".*gyro.*")) {
    gyroX = Float.valueOf(mes[1]);
    gyroY = Float.valueOf(mes[2]);
    gyroZ = Float.valueOf(mes[3]);*/
  } else if (mes[0].matches(".*mag.*")) {
    magX = Float.valueOf(mes[1]);
    magY = Float.valueOf(mes[2]);
    magZ = Float.valueOf(mes[3]);
  } else if (mes[0].matches(".*ori.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency

    oriX = Float.valueOf(mes[1]);
    oriY = Float.valueOf(mes[2]);
    oriZ = Float.valueOf(mes[3]);
  } else if (mes[0].matches(".*light.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency

    light = Float.valueOf(mes[1]);
  } else if (mes[0].matches(".*BLEACC.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    prevms = millis();

    bleAccX = Float.valueOf(mes[2]);
    bleAccY = Float.valueOf(mes[3]);
    bleAccZ = Float.valueOf(mes[4]);
    //bleAccs.push(accX, accY, accZ);
  } else if (mes[0].matches(".*BLEIRT.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    bleIrtAmb = Float.valueOf(mes[2]);
    bleIrtTarget = Float.valueOf(mes[4]);
  } else if (mes[0].matches(".*BLEHUM.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    bleHum = Float.valueOf(mes[2]);
  } else if (mes[0].matches(".*BLEOPT.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    bleOpt = Float.valueOf(mes[2]);
  } else if (mes[0].matches(".*BLEMAG.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    bleMagX = Float.valueOf(mes[2]);
    bleMagY = Float.valueOf(mes[2]);
    bleMagZ = Float.valueOf(mes[2]);
  } else if (mes[0].matches(".*BLEBAR.*")) {
    //println(message+ " Interval:" + (millis()-prevms)+" msec"); //frequency
    bleTemp = Float.valueOf(mes[2]);
    bleBar = Float.valueOf(mes[3]);
  }
} 
