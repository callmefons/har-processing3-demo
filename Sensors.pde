class Sensors {
  ArrayList<Sensor> buffer = new ArrayList<Sensor>();
  int size = 640;

  Sensors(int nsamples) {
    this.nsamples = nsamples;
  }

  int numVar = 3;

  synchronized void push(Sensor s) {
    buffer.add(s);
    if (size() > size) buffer.remove(0);
  }

  synchronized void push(float ax, float ay, float az) {
    push(new Sensor(ax, ay, az));
  }

  synchronized void push(float ax, float ay) {
    push(new Sensor(ax, ay));
  }  

  synchronized void push(float ax) {
    push(new Sensor(ax));
  }  


  int size() {
    return buffer.size();
  }

  int nVal() { // number of sensor variables 
    return last(1).size();
  }

  synchronized Sensor last() {
    return last(1);
  }


  synchronized Sensor last(int i) {
    int s = size();
    if (s>=i) {
      return buffer.get(s-i);
    } else {
      return null;
    }
  }


  int nsamples=1;
  int nskip=0;
  synchronized String toCSV() {
    int s = size();
    int n = nsamples;
    int skip = nskip;
    

    if (s>=n*(skip+1)) {
      String ret = last(1).toCSV();
      for (int i=1; i<n; i++) {
        ret += "," + last(i*(skip+1)+1).toCSV();
      }
      return ret;
    } else { 
      String ret=last(1).naCSV();
      for (int i=1; i<n; i++) {
        ret += ","+ last(1).naCSV();
      }
      return ret;
    }
  }


  synchronized void drawGrid() {
    //grid
    strokeWeight(0.5);
    stroke(50);
    for (int i = 0; i < 10; i++) line(0, i*20, 640, i*20);
    for (int i=0; i<32; i++) line(i*20, 0, i*20, 200);
    stroke(100);
    line(0, 200, 640, 200);
  }


  synchronized void draw(int x, int y, float rate, String name) {
    draw(x, y, rate, name, #FF0000, #00FF00, #00B4FF);
  }


  synchronized void draw(int x, int y, float rate, String name, int color1, int color2, int color3) {

    textSize(6);
    fill(color1);
    int i2 = size()-1;
    Sensor v = buffer.get(i2);
    text(name, x+i2-40, y+v.ax*rate+100-2);
    if (v.numVar > 1) {
      fill(color2);
      text(name, x+i2-40, y+v.ay*rate+100-2);
    } 
    if (v.numVar > 2) {
      fill(color3); 
      text(name, x+i2-40, y+v.az*rate+100-2);
    }

    

    for (int i=0; i<size (); i++) {
      v = buffer.get(i);
      
      
      strokeWeight(1);
      if (i >= size()-nsamples){
        strokeWeight(2);
      }
      

      stroke(color1);

      point(x + i, y + v.ax * rate+ 100 );
      stroke(color2); 
      if (v.numVar > 1) {
        point(x + i, y + v.ay * rate+ 100 );
      } 
      stroke(color3);
      if (v.numVar > 2) { 
        point(x + i, y + v.az * rate+ 100 );
      }
    }
  }

  synchronized String names() {
    int n = nsamples;
    String ret= last(1).names(0);
    for (int i=1; i<n; i++) {
      ret += "," + last(1).names(i);
    }
    return ret;
  }
}
