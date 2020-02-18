
import processing.serial.*; 

Serial arduinoPort;
int m1 = 0, m2 = 0, m3 = 0;
int c1 = 0, c2 = 0, c3 = 0;

void initArduinoPort() {
  // Print all available serial ports. 
  // Find the port with a name like 'tty.usbmodem*'.
  // Open the port at the baudrate.
  // parent is of type PApplet: typically use "this"
  // No parity bit, 8 data bit, 1 stop bit
  printArray(Serial.list());  
  arduinoPort = new Serial(this, Serial.list()[7], 9600);
  // It takes 2 seconds or more for serial port to get ready
  delay(2000);
}

// Command and response are printable ASCII bytes ended with LF.
void sendCommand(int m1, int m2, int m3) {
  int LF= 10;
  int N = 32;
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

  if (i < 13 || response[0] != 'c') {
    println("ERROR", respStr);
  }
  
  // get current position c1, c2, c3
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

  println("Arduino cmd", m1, m2, m3, "resp", c1, c2, c3, cmdStr, respStr, i);
}

void setup ( ) {
  size (500, 500); 
  initArduinoPort();
} 

int delta = 128;
void draw ( ) {
  sendCommand(m1, m2, m3);
  m1 += delta;
  m2 += delta;
  m3 += delta;
  if (m1 == 4096) {
    delta = -delta;
  }
}
