class TestShapeGeometry2 {
  TestShapeGeometry2 () {
  }
  void testIsInFacet() {
    ShapeGeometry2 sg = new ShapeGeometry2();
    PShape s = createShape();
    s.beginShape();
    s.vertex(0, 0);
    s.vertex(20, 0);
    s.vertex(20, 10);
    s.vertex(10, 10);
    s.vertex(10, 20);
    s.vertex(5, 30);
    s.vertex(0, 20);
    s.endShape(CLOSE);
    PVector xy = new PVector();
    float [] xyInFacet = {5, 5, 5, 10, 5, 20, // inside
      5, 0, 20, 5, 15, 10, // on bottom edge
      0, 0, 20, 0, 20, 10, 10, 10, 10, 20, 5, 30, 0, 20 // vertices
    };
    for (int i = 0; i < xyInFacet.length; i += 2) {
      xy.x = xyInFacet[i];
      xy.y = xyInFacet[i+1];
      if (!sg.isInFacet(s, xy)) 
        println(xy.x, xy.y, "testIsXYInPolygon in facet failed");
    }
    float [] xyOutOfFacet = {-5, 0, -5, 5, -5, 10, 0, 30};
    for (int i = 0; i < xyOutOfFacet.length; i += 2) {
      xy.x = xyOutOfFacet[i];
      xy.y = xyOutOfFacet[i+1];
      if (sg.isInFacet(s, xy)) 
        println(xy.x, xy.y, "testIsXYInPolygon out of facet failed");
    }
  }
}



class TestConvexHull {
  void testSortByPolarAngle() {
    ConvexHull ch = new ConvexHull();
    PVector p[] = {new PVector(50, 50), new PVector(100, 50), new PVector(150, 120), new PVector(200, 190)};
    ArrayList<PVector> expected = new ArrayList<PVector>(Arrays.asList(p));
    ArrayList<PVector> points = (ArrayList)expected.clone();
    PVector temp = points.get(0);
    points.remove(0);
    Collections.shuffle(points);
    points.add(0, temp);
    ArrayList<PVector> actual = ch.sortByPolarAngle(points);
    boolean ok = true;
    for (int i = 0; i < expected.size(); i++) {
      if ((expected.get(i).x != actual.get(i).x) || (expected.get(i).y != actual.get(i).y)) {
        ok = false;
        break;
      }
    }
    if (!ok) {
      println("testSortByPolarAngle failed");
      print("Shuffled");
      printPoints(points);
      println();
      print("Expected");
      printPoints(expected);
      println();
      print("Actual");
      printPoints(points);
      println();
    }
  }

  void testGrahamScan() {
    HashSet<PVector> randomPoints = makeRandomPoints(20);
    ConvexHull ch = new ConvexHull();
    ArrayList<PVector> chPoints = ch.getConvexHull(randomPoints);
    stroke(255, 0, 0);
    for (PVector pt : randomPoints) {
      ellipse(pt.x, pt.y, 5, 5);
    }
    for (int i = 1; i < chPoints.size(); i++) {
      line(chPoints.get(i).x, chPoints.get(i).y, chPoints.get(i-1).x, chPoints.get(i-1).y);
    }
    line(chPoints.get(chPoints.size()-1).x, chPoints.get(chPoints.size()-1).y, chPoints.get(0).x, chPoints.get(0).y);
  }

  // Make n distinct random points
  // To ensure that there are no duplicate points, first make the array with numbers
  // Then shuffle their order to achieve "randomness"
  HashSet<PVector> makeRandomPoints(int n) {
    ArrayList<Integer> x = new ArrayList <Integer>();
    ArrayList<Integer> y = new ArrayList <Integer>();
    int padding = 150;
    for (int i = padding; i < width-padding; i++) { 
      x.add(i);
    }
    for (int i = padding; i < height-padding; i++) {
      y.add(i);
    }
    Collections.shuffle(x);
    Collections.shuffle(y);

    HashSet<PVector> points = new HashSet<PVector>();
    // the number of y values belonging to an x value is the total 
    // number of points divided by the number of 'x' values
    int numYperX = n/x.size(); 
    if (n%x.size() != 0) // if division has a remainder, then round up everytime
      numYperX++;
    for (int i = 0, j = 0; i < x.size(); i++, j++) {
      for (int k = 0; k < numYperX; k++) {
        points.add(new PVector(x.get(i), y.get( (j+k)%y.size() ))); // reuse the y-values, x-values are always unique
        n--;
        if (n==0)
          return points;
      }
    }
    return points;
  }
}
void test() {
  TestShapeGeometry2 t = new TestShapeGeometry2();
  t.testIsInFacet();
  //t.testLowerBoundInOrderOfX();
  println("TestShapeGeometry done");
  TestConvexHull testConvexHull = new TestConvexHull();
  testConvexHull.testSortByPolarAngle();
  //testConvexHull.testGrahamScan();
  println("TestConvexHull done");
}
