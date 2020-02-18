
int LF_CHAR = 10;
int SP_CHAR = 32;

void setup ( ) {
    Serial.begin(9600);       // Starting the serial communication at 9600 baud rate
} 

void moveMotor(byte m1, byte m2, byte m3) {
  delay(50);
}

void loop ( ) { 
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
  if (i != 7 || cmd[0] != 'm') {
    Serial.write("rBad command ");
    Serial.write(cmd, i);
    Serial.write(LF_CHAR);
    Serial.flush();
    return;
  }

  // get m1, m2, m3.
  byte m1 = cmd[1] - 48;
  m1 <<= 4;
  m1 += cmd[2] - 48; 
  byte m2 = cmd[3] - 48;
  m2 <<= 4;
  m2 += cmd[4] - 48;
  byte m3 = cmd[5] - 48;
  m3 <<= 4;
  m3 += cmd[6] - 48;

  // move motor to position
  moveMotor(m1, m2, m3);

  // Send response
  Serial.write('c');
  Serial.print(m1, DEC);
  Serial.print(m2, DEC);
  Serial.print(m3, DEC);
  Serial.write(LF_CHAR);
  Serial.flush();
}
