
#include <AccelStepper.h>

// https://www.instructables.com/id/BYJ48-Stepper-Motor/
#define  STEPS_PER_REVOLUTION = 4096;

// https://www.airspayce.com/mikem/arduino/AccelStepper/classAccelStepper.html
#define HALF4WIRE 8

// motor pins
#define motorPin1  2      // IN1 on the ULN2003 driver 1
#define motorPin2  3      // IN2 on the ULN2003 driver 1
#define motorPin3  4      // IN3 on the ULN2003 driver 1
#define motorPin4  5      // IN4 on the ULN2003 driver 1

#define motorPin5  6      // IN1 on the ULN2003 driver 2
#define motorPin6  7      // IN2 on the ULN2003 driver 2
#define motorPin7  8      // IN3 on the ULN2003 driver 2
#define motorPin8  9      // IN4 on the ULN2003 driver 2

#define motorPin9  10     // IN1 on the ULN2003 driver 3
#define motorPin10  11    // IN2 on the ULN2003 driver 3
#define motorPin11  12    // IN3 on the ULN2003 driver 3
#define motorPin12  13    // IN4 on the ULN2003 driver 3

AccelStepper stepper1(HALF4WIRE, motorPin1, motorPin3, motorPin2, motorPin4);
AccelStepper stepper2(HALF4WIRE, motorPin5, motorPin7, motorPin6, motorPin8);
AccelStepper stepper3(HALF4WIRE, motorPin9, motorPin11, motorPin10, motorPin12);

long m1, m2, m3; // moveTo target positions of 3 motors
long c1, c2, c3; // current positions of 3 motors
bool motorRunning;

// Character to end command/response
int LF_CHAR = 10;

void setup ( ) {
  // Starting the serial communication at 9600 baud rate
  Serial.begin(9600); 
  m1 = m2 = m3 = 0;
  c1 = c2 = c3 = 0;
  motorRunning = false;
} 

void configMotors() {
  stepper1.moveTo(-m1);
  stepper2.moveTo(-m2); 
  stepper3.moveTo(-m3);  

  // speed is linear when the value is below 1000. 
  int d1 = m1 > c1 ? m1 - c1 : c1 - m1;
  int d2 = m2 > c2 ? m2 - c2 : c2 - m2;
  int d3 = m3 > c3 ? m3 - c3 : c3 - m3;
  int dmax = d1 > d2 ? d1 : d2;
  if (d3 > dmax)
    dmax = d3; 
  float s1 = 9000.0 * d1 / dmax;
  float s2 = 9000.0 * d2 / dmax;
  float s3 = 9000.0 * d3 / dmax;
  stepper1.setMaxSpeed(s1);
  stepper2.setMaxSpeed(s2);
  stepper3.setMaxSpeed(s3);
  
  stepper1.setAcceleration(500.0);
  stepper2.setAcceleration(500.0);
  stepper3.setAcceleration(500.0);
}

// Return true if at least one motor is still running
bool runMotors() {
  bool f1 = stepper1.run();
  bool f2 = stepper2.run();
  bool f3 = stepper3.run();
  c1 = stepper1.currentPosition();
  c2 = stepper2.currentPosition();
  c3 = stepper3.currentPosition();
  if (c1 == m1 && c2 == m2 && c3 == m3)
    return false;
  if (!(f1 || f2 || f3))
    return false;
  return true;
}

void sendResponse() {
  byte resp[13];
  long c;
  resp[0] = 'c';
  c = -c1;
  resp[1] = byte(((c >> 12) & 0xf) + 48);
  resp[2] = byte(((c >> 8) & 0xf) + 48);
  resp[3] = byte(((c >> 4) & 0xf) + 48);
  resp[4] = byte((c & 0xf) + 48); 
  c = -c2;
  resp[5] = byte(((c >> 12) & 0xf) + 48);
  resp[6] = byte(((c >> 8) & 0xf) + 48);
  resp[7] = byte(((c >> 4) & 0xf) + 48);
  resp[8] = byte((c & 0xf) + 48); 
  c = -c3;
  resp[9] = byte(((c >> 12) & 0xf) + 48);
  resp[10] = byte(((c >> 8) & 0xf) + 48);
  resp[11] = byte(((c >> 4) & 0xf) + 48);
  resp[12] = byte((c & 0xf) + 48); 
  Serial.write(resp, 13);

  // debug
  //Serial.write('m');
  //Serial.print(m1, DEC);
  //Serial.print(m2, DEC);
  //Serial.print(m3, DEC);

  // append LF and flush
  Serial.write(LF_CHAR);
  Serial.flush();
}

// Block to receive command. Set m1, m2, m3 and return true if received a valid command.
// Respond error message and return false if received a bad command.
bool receiveCommand() {
  int len = 16;
  byte cmd[len];
  // block waiting to receive command, which ends with LF
  int i = 0;
  int b = 0;
  while (true) {
    while(Serial.available() == 0) {
      delay(1);
    }
    b = Serial.read();
    if (b == LF_CHAR)
      break;
    cmd[i] = b;
    ++i;
    if (i == len)
      i = 0;
  }
  
  // check if the command is valid
  if (i != 13 || cmd[0] != 'm') {
    Serial.write("rBad command ");
    Serial.write(cmd, i);
    Serial.write(LF_CHAR);
    Serial.flush();
    return false;
  }

  // get m1, m2, m3.
  m1 = cmd[1] - 48;
  m1 <<= 4;
  m1 += cmd[2] - 48;
  m1 <<= 4; 
  m1 += cmd[3] - 48;
  m1 <<= 4; 
  m1 += cmd[4] - 48;
  
  m2 = cmd[5] - 48;
  m2 <<= 4;
  m2 += cmd[6] - 48;
  m2 <<= 4; 
  m2 += cmd[7] - 48;
  m2 <<= 4; 
  m2 += cmd[8] - 48;  

  m3 = cmd[9] - 48;
  m3 <<= 4;
  m3 += cmd[10] - 48;
  m3 <<= 4; 
  m3 += cmd[11] - 48;
  m3 <<= 4; 
  m3 += cmd[12] - 48; 
  return true;
}

void loop ( ) { 
  if (!motorRunning) {
    bool validCmd = receiveCommand();
    if (validCmd) {
      configMotors();
      motorRunning = true;
    }  
  } else {
    bool running = runMotors();
    if (!running) {
      sendResponse();
      motorRunning = false;
    }  
  }
}
