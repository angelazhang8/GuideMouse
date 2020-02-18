#include <AccelStepper.h>
#define HALFSTEP 8

// motor pins
#define motorPin1  2     // IN1 on the ULN2003 driver 1
#define motorPin2  3     // IN2 on the ULN2003 driver 1
#define motorPin3  4     // IN3 on the ULN2003 driver 1
#define motorPin4  5     // IN4 on the ULN2003 driver 1

#define motorPin5  6     // IN1 on the ULN2003 driver 2
#define motorPin6  7     // IN2 on the ULN2003 driver 2
#define motorPin7  8    // IN3 on the ULN2003 driver 2
#define motorPin8  9    // IN4 on the ULN2003 driver 2

#define motorPin9  10     // IN1 on the ULN2003 driver 2
#define motorPin10  11     // IN2 on the ULN2003 driver 2
#define motorPin11  12    // IN3 on the ULN2003 driver 2
#define motorPin12  13    // IN4 on the ULN2003 driver 2

AccelStepper stepper1(HALFSTEP, motorPin1, motorPin3, motorPin2, motorPin4);
AccelStepper stepper2(HALFSTEP, motorPin5, motorPin7, motorPin6, motorPin8);
AccelStepper stepper3(HALFSTEP, motorPin9, motorPin11, motorPin10, motorPin12);

const int stepsPerRevolution = 200;

void setup() {
  // put your setup code here, to run once:
    stepper1.setMaxSpeed(200.0);
    stepper1.setAcceleration(100.0);
    stepper1.moveTo(1000000);
    
    stepper2.setMaxSpeed(300.0);
    stepper2.setAcceleration(100.0);
    stepper2.moveTo(1000000);
    
    stepper3.setMaxSpeed(300.0);
    stepper3.setAcceleration(100.0);
    stepper3.moveTo(1000000); 
}

void loop() {
  // put your main code here, to run repeatedly:
  moveMotor();
}

void moveMotor() {
    stepper1.run();
    stepper2.run();
    stepper3.run();
}
