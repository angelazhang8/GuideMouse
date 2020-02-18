class MotorController {
  PVector mouseXY; // x,y at (0,0). z is physical height in millimeter
  PVector vp1, vp2, vp3;  // x,y on unit circle in virtual coordinate system
  PVector p1, p2, p3; // x,y in physical coordinate system
  int mstep1, mstep2, mstep3;  // motor step to move to
  int cstep1, cstep2, cstep3;  // current motor step, from last reponse from arduino


  // The min angle between normal and z-axis, i.e., the max slope of the plane
  float MIN_ANGLE_TO_Z_AXIS = PI / 6;
  // The physical distance in unit of millimeter for 1 unit on the XY plane.
  // p1, p2, p3 are on the unit circle in the virtual coordinate system.
  float XY_SCALE_FACTOR = 12;
  // The physical distance in unit of millimeters for 1 unit on the Z-axis.
  // The input height at mouseXY ranges in [0,1] in the virtual coordinate system.
  float Z_SCALE_FACTOR = 40;
  // The max z value at p1, p2, p3 in unit of millimeters
  float MAX_HEIGHT = 40;
  // The distance in unit of millimeter per motor step
  float DISTANCE_PER_MOTOR_STEP = 40.0/4096;

  // The mouseXY is at x=0, y=0
  // The three points' X and Y are relative to mouseXY and are on the unit circle.
  MotorController() {
    this.mouseXY = new PVector(0, 0);
    this.vp1 = new PVector(0, 1);
    this.vp2 = new PVector(-0.866, -0.5);
    this.vp3 = new PVector(0.866, -0.5);  
    this.p1 = new PVector(0, 1 * XY_SCALE_FACTOR);
    this.p2 = new PVector(-0.866 * XY_SCALE_FACTOR, -0.5 * XY_SCALE_FACTOR);
    this.p3 = new PVector(0.866 * XY_SCALE_FACTOR, -0.5 * XY_SCALE_FACTOR);
    this.cstep1 = 0;
    this.cstep2 = 0;
    this.cstep3 = 0;
  }

  // The input height at mouseXY ranges in [0,1]. 
  // Limit the angle between the normal vector and z-axis to 45 degrees.
  // Calculate the height for the three motors based on the height at mouseXY and normal vector. 
  // Drive motors via Arduino.
  void moveMotor(float h, PVector normal) {
    PVector ln = limitSlope(normal);
    this.mouseXY.z = h * Z_SCALE_FACTOR;
    setZForXYonPlane(ln, this.p1);
    setZForXYonPlane(ln, this.p2);
    setZForXYonPlane(ln, this.p3);
    
    limitHeights();
    
    this.vp1.z = this.p1.z / Z_SCALE_FACTOR;
    this.vp2.z = this.p2.z / Z_SCALE_FACTOR;
    this.vp3.z = this.p3.z / Z_SCALE_FACTOR;
    this.mstep1 = heightToMotorSteps(this.p1.z);
    this.mstep2 = heightToMotorSteps(this.p2.z);
    this.mstep3 = heightToMotorSteps(this.p3.z);
    if (DEBUG_HAS_ARDUINO)
      driveArduino();
    if (DEBUG_PRINT_MOTOR_HEIGHTS)
      println("Motors mouseZ", this.mouseXY.z, "normal (", normal.x, normal.y, normal.z,
        ") virtual (", vp1.z, vp2.z, vp3.z, 
        ") physical (", p1.z, p2.z, p3.z, 
        ") moveTo (", mstep1, mstep2, mstep3, 
        ") curPos (", cstep1, cstep2, cstep3, ")");
  }

  // If the normal vector is >45 degrees from the z-axis (i.e., the slope >45 degree), 
  // limit it to 45 degrees. Otherwise returns the input normal vector.
  PVector limitSlope(final PVector normal) {
    PVector v = new PVector(0, 0, 1);
    float a = PVector.angleBetween(v, normal);
    if (a <= MIN_ANGLE_TO_Z_AXIS)
      return normal;
    float k = sin(MIN_ANGLE_TO_Z_AXIS) / sin(a);
    v.x = normal.x * k;
    v.y = normal.y * k;
    v.z = normal.z * cos(MIN_ANGLE_TO_Z_AXIS) / cos(a);
    return v;
  }

  // Calculate the z value for xy on the plane defined by mouseXY and normal.
  void setZForXYonPlane(final PVector normal, PVector xy) {
    PVector directionVector = PVector.sub(xy, this.mouseXY); 
    float sum = directionVector.x * normal.x + directionVector.y * normal.y;
    directionVector.z = -(sum)/normal.z;
    xy.z = directionVector.z + this.mouseXY.z;
  }

  // Limit z-values of p1, p2, p3 to be between 0 and MAX_HEIGHT
  void limitHeights() {
    // Limit upper bound of z-value by MAX_HEIGHT
    float maxZ = (this.p1.z > this.p2.z ? this.p1.z : this.p2.z);
    maxZ = (maxZ > this.p3.z ? maxZ : this.p3.z);
    float delta = maxZ - MAX_HEIGHT; 
    if (delta > 0) {
      this.p1.z -= delta;
      this.p2.z -= delta;
      this.p3.z -= delta;
      return;
    }
    // Limit lower bound of z-value by 0.
    // The XY and Z scale factor guarantees that if a motor height >MAX_HEIGHT,
    // there cannot be another motor height <0.
    float minZ = (this.p1.z < this.p2.z ? this.p1.z : this.p2.z);
    minZ = (minZ < this.p3.z ? minZ : this.p3.z);
    if (minZ < 0) {
      this.p1.z -= minZ;
      this.p2.z -= minZ;
      this.p3.z -= minZ;
    }
  }

  // Convert the height at p1, p2, p3 in unit of millimeters to motor steps
  int heightToMotorSteps(float h) {
    return int(h / DISTANCE_PER_MOTOR_STEP);
  }

  // Send signal to arduino to drive motors. Arduino should respond with the motor steps after moving.
  void driveArduino() {
    sendCommand(this.mstep1, this.mstep2, this.mstep3);
  }

  // Command and response are printable ASCII bytes ended with LF.
  void sendCommand(int m1, int m2, int m3) {
    int LF= 10;
    int N = 64;
    byte[] response = new byte[N];
    int i = 0;

    // It is possible that the Serial buffer has part of response from the previous command.
    // Clear out the buffer.
    while (arduinoPort.available() > 0) {
      int b = arduinoPort.read();
      response[i % N] = (byte)b;
      ++i;
    }
    if (i > 0) {
      String respStr = new String(response, 0, i % N);
      println("WARN: Serial buffer has", i, "bytes from previous command", respStr);
    }

    // Send command  
    byte[] cmd = new byte[13];
    cmd[0] = 'm';
    cmd[1] = byte(((m1 >> 12) & 0xf) + 48);
    cmd[2] = byte(((m1 >> 8) & 0xf) + 48);
    cmd[3] = byte(((m1 >> 4) & 0xf) + 48);
    cmd[4] = byte((m1 & 0xf) + 48); 
    cmd[5] = byte(((m2 >> 12) & 0xf) + 48);
    cmd[6] = byte(((m2 >> 8) & 0xf) + 48);
    cmd[7] = byte(((m2 >> 4) & 0xf) + 48);
    cmd[8] = byte((m2 & 0xf) + 48); 
    cmd[9] = byte(((m3 >> 12) & 0xf) + 48);
    cmd[10] = byte(((m3 >> 8) & 0xf) + 48);
    cmd[11] = byte(((m3 >> 4) & 0xf) + 48);
    cmd[12] = byte((m3 & 0xf) + 48); 
    arduinoPort.write(cmd);
    arduinoPort.write(LF);
    String cmdStr = new String(cmd);

    // Wait for Arduino to respond, expires in 5 seconds
    i = 0;
    while (arduinoPort.available() == 0) {
      ++i;
      if (i == 10000) {
        println("ERROR no repsonse from Arduino for 10 seconds");
        return;
      }
      delay(1);
    }

    // Receive response
    i = 0;
    int b = 0;
    while (true) {
      while (arduinoPort.available() == 0) {
        delay(1);
      }
      b = arduinoPort.read();
      if (b == LF)
        break;
      response[i % N] = (byte)b;
      ++i;
    }
    String respStr = new String(response, 0, i % N);

    if (response[0] != 'c') {
      println("ERROR", respStr);
    }

    // get current position c1, c2, c3
    int c1, c2, c3;
    c1 = response[1] - 48;
    c1 <<= 4;
    c1 += response[2] - 48;
    c1 <<= 4; 
    c1 += response[3] - 48;
    c1 <<= 4; 
    c1 += response[4] - 48;

    c2 = response[5] - 48;
    c2 <<= 4;
    c2 += response[6] - 48;
    c2 <<= 4; 
    c2 += response[7] - 48;
    c2 <<= 4; 
    c2 += response[8] - 48;  

    c3 = response[9] - 48;
    c3 <<= 4;
    c3 += response[10] - 48;
    c3 <<= 4; 
    c3 += response[11] - 48;
    c3 <<= 4; 
    c3 += response[12] - 48;

    cstep1 = c1;
    cstep2 = c2;
    cstep3 = c3;
    if (DEBUG_PRINT_ARDUINO_CMD_RESP)
      println("Arduino cmd", m1, m2, m3, "resp", c1, c2, c3, cmdStr, respStr, i);
  }


  // Get motor location in the virtual coordinate. For displaying on screen.
  // x,y is on the unit circle.
  // z is between 0 and 1.
  PVector getMotorVirtualCoordinate(int motor) {
    if (motor == 1)
      return vp1;
    if (motor == 2)
      return vp2;
    return vp3;
  }

  // Get motor's z value in the virtual coordinate, between 0 and 1. For displaying on screen.
  float getMotorVirtualHeight(int motor) {
    if (motor == 1)
      return vp1.z;
    if (motor == 2)
      return vp2.z;
    return vp3.z;
  }

  void printStates() {
    println("Motors vp1 (", vp1.x, vp1.y, ") vp2 (", vp2.x, vp2.y, ") vp3 (", vp3.x, vp3.y, 
      ") p1 (", p1.x, p1.y, ") p2 (", p2.x, p2.y, ") p3 (", p3.x, p3.y, ")");
  }
}
