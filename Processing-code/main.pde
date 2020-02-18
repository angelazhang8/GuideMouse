import g4p_controls.*;
import shapes3d.*;
import peasy.*;
import java.util.HashSet;
import java.util.Collections;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import processing.serial.*; 

// DEBUG settings
boolean DEBUG_HAS_ARDUINO = true;
boolean DEBUG_RUN_UNITTEST = false;
boolean DEBUG_PRINT_MOUSE_XY = false;
boolean DEBUG_PRINT_VISIBLE_FACET = false;
boolean DEBUG_PRINT_MOTOR_HEIGHTS = true;
boolean DEBUG_PRINT_ARDUINO_CMD_RESP = false;

// Serial port to talk to Arduino
Serial arduinoPort;

// Use a lock to protect concurrent access of dirtyWork from gui
DirtyWork dirtyWork ;
Lock dirtyWorkLock = new ReentrantLock(true);

PeasyCam cam;  
PShape pieta;
float red = 255;
float green = 255;
float blue = 255;
float heightMultiplier = 1;
String file;
PImage img = null;

void setup() {
  if (DEBUG_HAS_ARDUINO)
    initArduinoPort();
  
  String[] fileNames = {"s-wolf.obj", "s-angel.obj", "s-baseball.obj", "s-bmw.obj", 
    "s-cat.obj", "s-cow.obj", "s-deer.obj", "s-dog.obj", "s-goat.obj", "s-heart.obj", 
    "s-lion.obj", "s-lionface.obj", "s-pharaoh.obj", "s-pig.obj", "s-polarbear.obj", 
    "s-rat.obj", "s-relief-angel.obj", "s-relief-lionface.obj", "s-tree.obj", "s-wolf.obj"
  };
  size(700, 700, P3D);
  ortho();
  
  if (DEBUG_RUN_UNITTEST)
    test();

  //cam = new PeasyCam(this, 100);
  //cam.setMinimumDistance(400);
  //cam.setMaximumDistance(500);
  createGUI();
  file = "s-lion.obj";
  loadNewShape(file);

  fill(255, 0, 0);
}


void draw() {
  if (img != null)
    image(img, 0, 0, width, height);
  else
    background(255);

  //camera();
  lights();

  dirtyWorkLock.lock();
  try {
    dirtyWork.drawRelief();
    dirtyWork.mouseMoves();
  } 
  catch (Exception e) {
    println(e);
  } 
  finally {
    dirtyWorkLock.unlock();
  }
}

void initArduinoPort() {
  // Print all available serial ports. 
  // Find the port with a name like 'tty.usbmodem*'.
  // Open the port at the baudrate.
  // parent is of type PApplet: typically use "this"
  // No parity bit, 8 data bit, 1 stop bit
  printArray(Serial.list());  
  arduinoPort = new Serial(this, Serial.list()[8], 9600);
  // It takes 2 seconds or more for serial port to get ready
  delay(2000);
}

// maybe here also change how facets are being drawn
void resetCamera(float viewLeft, float viewRight) {
  //float fov = PI/3.0;
  //float cameraX = fov; //* viewLeft;
  //float cameraY = float(width)/float(height); // * viewRight;
  //float cameraZ = (height/2.0) / tan(fov/2.0) * viewLeft;

  //perspective(cameraX, cameraY, cameraZ/2.0, cameraZ*2.0);

  //cam = new PeasyCam(this, 100);
  //cam.setMinimumDistance(400);
  //cam.setMaximumDistance(500);
  println(viewLeft, viewRight);
  rotateX(PI*viewLeft);
  rotateY(PI*viewRight);
}

void loadNewShape(String file) {
  dirtyWorkLock.lock();
  try {
    pieta = loadShape(file);
    dirtyWork = new DirtyWork();
    dirtyWork.initialize(pieta);
    dirtyWork.printStates();
  }  
  catch (Exception e) {
    println(e);
  } 
  finally {
    dirtyWorkLock.unlock();
  }
}


void printShape(PShape shape) {
  for (int i = 0; i < shape.getVertexCount(); i++) {
    PVector v = shape.getVertex(i);
    print("(", v.x, v.y, v.z, ")");
  }
  println();
}

void printPoints(ArrayList<PVector> points) {
  for (PVector v : points) {
    print("(", v.x, v.y, v.z, ")");
  }
  println();
}
