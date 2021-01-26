class Sensor {

  float ax, ay, az;

  Sensor(float ax, float ay, float az) {
    this.ax=ax;
    this.ay=ay;
    this.az=az;
    numVar=3;
  }

  Sensor(float ax, float ay) {
    this.ax=ax;
    this.ay=ay;
    numVar=2;
  }

  Sensor(float ax) {
    this.ax=ax;
    numVar=1;
  }


  Sensor() { // for NA
    numVar=0;
  }

  int numVar;


  String toCSV() {
    if (numVar == 1) return ""+ax;
    else if (numVar == 2) return ""+ax + ","+ay;
    else return ""+ax+","+ay+","+az;
  }

  String naCSV() {
    //return "NA,NA,NA";
    if (numVar == 1) return "0";
    else if (numVar == 2) return "0,0";
    else return "0,0,0"; //zero for missing sensors
  }

  int size() {
    return numVar;
  } 

  String names(int n) { // adding number n
    if (numVar==1) return "'X"+n+"'";
    else if (numVar == 2) return "'X"+n + "','Y"+n+"'"; 
    else return "'X" + n + "','Y"+ n + "','Z" + n + "'";
  }
}
