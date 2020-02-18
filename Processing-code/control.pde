// Orchestrate the whole program.
// Convert between the object coordinate and screen coordinate and draw shapes.
class DirtyWork {
  PShape shape;
  ShapeGeometry2 sg;
  float scaleFactor;
  MotorController motorController;
  PVector mouseXY;
  float motorHeightFactor, normalVectorMagnitudeFactor;
  float translateX, translateY;

  void initialize(PShape shape) {
    this.mouseXY = new PVector();
    this.shape = shape;
    this.sg = new ShapeGeometry2(this.shape);
    float deltaX = this.sg.getMaxX() - this.sg.getMinX();
    float deltaY = this.sg.getMaxY() - this.sg.getMinY();
    float deltaZ = this.sg.getMaxZ() - this.sg.getMinZ();
    // Scale according to the smaller of deltaX and deltaY; 
    // reduce scaleFactor if depth exceeds deltaX/deltaY
    float ratioX = (width - 40)/ deltaX;
    float ratioY = (height - 40)/ deltaY;
    if (ratioX > ratioY) {
      this.scaleFactor = ratioY;
      if (deltaZ > deltaY)
        this.scaleFactor /= (deltaZ / deltaY) * 1.1;
    } else {
      this.scaleFactor = ratioX;
      if (deltaZ > deltaX)
        this.scaleFactor /= (deltaZ / deltaX) * 1.1;
    }
    // Screen center co-locate with object center
    this.translateX = width/2 - (this.sg.getMaxX() + this.sg.getMinX()) * this.scaleFactor/2;
    this.translateY = height/2 - (this.sg.getMaxY() + this.sg.getMinY()) * this.scaleFactor/2;
    // Normalize z-value at mouseXY between 0 and 1 to control motor.
    this.motorController = new MotorController();
    // Draw the normal vector in proportion to z-value.
    this.motorHeightFactor = 1 / (this.sg.getMaxZ() - this.sg.getMinZ());
    if (ratioX > ratioY) {
      this.normalVectorMagnitudeFactor = this.motorHeightFactor * deltaY;
    } else {
      this.normalVectorMagnitudeFactor = this.motorHeightFactor * deltaX;
    }
    this.normalVectorMagnitudeFactor /= 2;
  }

  // If mouse moves, highlight the visible facet, draw its normal vector, and
  // move the motor
  void mouseMoves() {
    this.mouseXY.x = mouseX;
    this.mouseXY.y = mouseY;
    screenToObjectCoordinate(mouseXY);
    // DEBUG check mouse XY is correct
    if (DEBUG_PRINT_MOUSE_XY)
      println("Coordinate screen", mouseX, mouseY, "object", this.mouseXY.x, this.mouseXY.y);

    PShape polygon = this.sg.getVisibleFacet(mouseXY);
    PVector normal;
    float mouseHeight;
    if (polygon == null) {
      normal = new PVector();
      normal.x = 0;
      normal.y = 0;
      normal.z = 1;
      mouseHeight = 0;
      this.motorController.moveMotor(mouseHeight, normal);
      return;
    }
    
    // highlight the visible facet 
    highlightFacet(polygon);
    
    // Get normal vector of visible polygon and set z-value at mouse XY
    // Make normal vector points toward user
    // Adjust magnitude of normal vector proportional to z-value and draw
    normal = this.sg.getNormalVectorAndSetHeight(polygon, this.mouseXY);
    if (normal.z < 0)
      normal.z *= -1;
    normal.normalize();
    PVector nvdraw = new PVector();
    nvdraw = normal.copy();
    nvdraw.mult((this.mouseXY.z - this.sg.getMinZ()) * this.normalVectorMagnitudeFactor);
    drawNormalVector(nvdraw, mouseXY);

    // Move motors. 
    // DEBUG verbose=true/false check wether motor heights are correct
    // DEBUG comment our driveArduino in moveMotor when running without Arduino
    mouseHeight = (mouseXY.z - this.sg.getMinZ()) * this.motorHeightFactor;
    this.motorController.moveMotor(mouseHeight, normal);
    drawSideView();
  }

  // Convert the provided XY screen coordinate to object coordinate in place.
  void screenToObjectCoordinate(PVector xy) {
    float oX = (xy.x - width/2) / this.scaleFactor + (this.sg.getMaxX() + this.sg.getMinX())/2;
    float oY = (xy.y - height/2) / this.scaleFactor + (this.sg.getMaxY() + this.sg.getMinY())/2;
    xy.x = oX;
    xy.y = oY;
  }

  // Draw the relief. Set all attributes here.
  void drawRelief() {
    this.shape.setFill(color(red, green, blue));
    drawWithObjectCoordinate(this.shape);
  }

  // Highlight the visibal facet. Set all attributes here.
  void highlightFacet(PShape facet) {
    //spotLight(0, 0, 0, width/2, height/2, 400, 0, 0, -1, PI/4, 2);
    facet.setFill(color(red*0.4, green*0.4, blue*0.4));
    //textureShape(facet);
    drawWithObjectCoordinate(facet);
  }

  // Draw the normal vector. Set all attributes here.
  void drawNormalVector(PVector normal, PVector pos) {
    PShape nv = createShape(LINE, pos.x, pos.y, pos.z, pos.x + normal.x, pos.y + normal.y, pos.z + normal.z);
    nv.setFill(color(255, 0, 0));
    nv.setStrokeWeight(2, 1.2);
    drawWithObjectCoordinate(nv);
  }

  // draw motor positions in screen coordinate
  void drawSideView() {
    float initialPegHeight = heightMultiplier * 5;
    float scaleFactor = heightMultiplier * 50;
    float distBetweenPegs = 15;
    float padding = 50;
    float rectWidth = 10;
    float m1 = initialPegHeight + this.motorController.getMotorVirtualHeight(1)*scaleFactor;
    float m2 = initialPegHeight + this.motorController.getMotorVirtualHeight(2)*scaleFactor;
    float m3 = initialPegHeight + this.motorController.getMotorVirtualHeight(3)*scaleFactor;
    rect(width/9, padding, rectWidth, m1);
    rect(width/9 + distBetweenPegs, padding, rectWidth, m2);
    rect(width/9 + distBetweenPegs*2, padding, rectWidth, m3);

    //float sf = 20;
    //float minZ = 1;
    //float maxZ = 2;
    //PVector p1 = this.motorController.getMotorVirtualCoordinate(1);
    //PVector p2 = this.motorController.getMotorVirtualCoordinate(2);
    //PVector p3 = this.motorController.getMotorVirtualCoordinate(3);
    //line(sf * (p1.x + 1), sf * (p1.y + 1), sf * (p2.x + 1), sf * (p2.y + 1));
    //line(sf * (p2.x + 1), sf * (p2.y + 1), sf * (p3.x + 1), sf * (p3.y + 1));
    //line(sf * (p3.x + 1), sf * (p3.y + 1), sf * (p1.x + 1), sf * (p1.y + 1));
    //float z1, z2, z3;
    //z1 = p1.z > maxZ ? maxZ : (p1.z < minZ ? minZ : p1.z);
    //z2 = p2.z > maxZ ? maxZ : (p2.z < minZ ? minZ : p2.z);
    //z3 = p3.z > maxZ ? maxZ : (p3.z < minZ ? minZ : p3.z);
    //line(sf * (p1.x + 1), sf * (p1.y + 1), sf * (p1.x + 1), sf * (p1.y + 1 + z1));
    //line(sf * (p2.x + 1), sf * (p2.y + 1), sf * (p2.x + 1), sf * (p2.y + 1 + z2));
    //line(sf * (p3.x + 1), sf * (p3.y + 1), sf * (p3.x + 1), sf * (p3.y + 1 + z3));

    //line(sf * (p1.x + 1), sf * (p1.y + 1 + z1), sf * (p2.x + 1), sf * (p2.y + 1 + z2));
    //line(sf * (p2.x + 1), sf * (p2.y + 1 + z2), sf * (p3.x + 1), sf * (p3.y + 1 + z3));
    //line(sf * (p3.x + 1), sf * (p3.y + 1 + z3), sf * (p1.x + 1), sf * (p1.y + 1 + z1));
  }

  // Draw shape whose geometry uses its own coordinates.
  void drawWithObjectCoordinate(PShape shape) {
    pushMatrix();
    translate(this.translateX, this.translateY);
    scale(scaleFactor);
    shape(shape);
    //textureShape(sg.getAllFacets());
    //shape.setFill(color(random(255), random(255), random(255) ));
    popMatrix();
  }

  void textureShape(ArrayList<PShape> allFacets) {
    PImage img = loadImage("t-marble.jpg");
    noStroke();
    for (PShape facet : allFacets) {
      beginShape();
      texture(img);
      for (int i = 0; i < facet.getVertexCount(); i++) {
        vertex(facet.getVertex(i).x, facet.getVertex(i).y, facet.getVertex(i).z);
      }
      endShape();
    }
  }

  void printStates() {
    println("scaleFactor", this.scaleFactor, "translateX", this.translateX, "translateY", this.translateY);
    this.sg.printStates(); 
    this.motorController.printStates();

    // DEBUG check whether interval tree is correct
    //this.sg.printIntervalTree(false);    

    // DEBUG check whether convex hull is correct
    //this.sg.printConvexHull(); 
    //PShape ch = this.sg.getConvexHull();
    //ch.setStrokeWeight(5);
    //drawWithObjectCoordinate(ch);
    //drawRelief();
  }
}
