class ShapeGeometry {
  // Outer array elements ordered by x-values, 
  // inner array elements have same x and are ordered by y-values
  private ArrayList<ArrayList<PVector>> vertices;
  // Convex hull of above vertices
  private PShape convexHull;
  // Max and min values for x and y for above vertices
  private float minX, minY, maxX, maxY, maxZ, minZ;
  // Facets of the shape. Key is vertex, value is the facets this vertex is on.
  private HashMap<PVector, ArrayList<PShape>> facets;

  ShapeGeometry() {
  }

  // Initialize with the provided shape.
  ShapeGeometry(PShape shape) {
    HashSet <PVector> v = new HashSet<PVector>();
    getVerticesFromShape(shape, v);
    makeVertices(v);
    initializeMinMaxXYZ(v);
    ConvexHull ch = new ConvexHull();
    HashSet<PVector> vNoZ = new HashSet<PVector>();
    for (PVector e : v ) {
      vNoZ.add(new PVector(e.x, e.y, 0));
    }
    ArrayList<PVector> chvertices = ch.getConvexHull(vNoZ);
    this.convexHull = createShape(PShape.GEOMETRY);
    this.convexHull.beginShape();
    for (PVector e : chvertices) {
      this.convexHull.vertex(e.x, e.y);
    }
    this.convexHull.endShape(CLOSE);
    // Initialize the facet map
    ArrayList<PShape> f = new ArrayList<PShape>();
    getAllFacetsFromShape(shape, f);
    //removeBottomFacets(f, v);
    makeFacetMap(f);
  }

  // Remove the facets that is not on top.
  private void removeBottomFacets(ArrayList<PShape> facets, HashSet<PVector> vertices) {
    for (int i = 0; i < facets.size(); ) {
      PShape facet = facets.get(i);
      boolean onTop = true;
      for (PVector v : vertices) {
        // If v is one of facet's vertices, continue to check
        // the next vertices
        int j = 0;
        for (; j < facet.getVertexCount(); ++j) {
          if (v == facet.getVertex(j))
            break;
        }
        if (j != facet.getVertexCount())
          continue;
        // Now v is not one of facet's vertices. If v is inside
        // the facet and its z value is greater than one of the 
        // facet's vertex's z value, then the facet is not on top
        // and is removed. Otherwise, it is on top and kept.
        if (isInFacet(facet, v)) {
          if (facet.getVertex(0).z < v.z) {
            onTop = false;
            break;
          }
        }
      }
      if (!onTop) {
        facets.remove(i);
      } else {
        i++;
      }
    }
  }

  private void getAllFacetsFromShape(PShape shape, ArrayList<PShape> allFacets) {
    if (PShape.GEOMETRY == shape.getFamily()) {
      allFacets.add(shape);
    } else {
      for (int i = 0; i < shape.getChildCount(); i++) {
        getAllFacetsFromShape(shape.getChild(i), allFacets);
      }
    }
  }

  private void makeFacetMap(ArrayList<PShape> topFacets) {
    this.facets = new HashMap<PVector, ArrayList<PShape>>();
    for (PShape f : topFacets) {
      for (int i = 0; i < f.getVertexCount(); i++) {
        PVector pv = f.getVertex(i);
        ArrayList<PShape> a = this.facets.get(pv);
        if (a == null) {
          a = new ArrayList<PShape>();
          this.facets.put(pv, a);
        } 
        a.add(f);
      }
    }
  }

  // Initialize the facet with the provided shape. 
  // The key is the vertex.
  // The mapped value is facets that the vertex is part of.
  //private void makeFacetMap(PShape shape, HashMap<PVector, ArrayList<PShape>> facets) {
  //  if (PShape.GEOMETRY == shape.getFamily()) {
  //    for (int i = 0; i < shape.getVertexCount(); i++) {
  //      PVector pv = shape.getVertex(i);
  //      ArrayList<PShape> a = facets.get(pv);
  //      if (a == null) {
  //        a = new ArrayList<PShape>();
  //        facets.put(pv, a);
  //      } 
  //      a.add(shape);
  //    }
  //  } else {
  //    for (int i = 0; i < shape.getChildCount(); i++) {
  //      makeFacetMap(shape.getChild(i), facets);
  //    }
  //  }
  //}

  // Initialize the max/min x and y values
  void initializeMinMaxXYZ(HashSet<PVector> vertices) {
    this.minX = Float.MAX_VALUE;
    this.minY = Float.MAX_VALUE;
    this.minZ = Float.MAX_VALUE;
    this.maxX = -Float.MAX_VALUE;
    this.maxY = -Float.MAX_VALUE;
    this.maxZ = -Float.MAX_VALUE;

    for (PVector v : vertices) {
      if (this.minX > v.x)
        this.minX = v.x;
      if (this.maxX < v.x)
        this.maxX = v.x;
      if (this.minY > v.y)
        this.minY = v.y;
      if (this.maxY < v.y)
        this.maxY = v.y;
      if (this.minZ > v.z)
        this.minZ = v.z;
      if (this.maxZ < v.z)
        this.maxZ = v.z;
    }
  }


  // Adds all vertices of the shape to the set.
  private void getVerticesFromShape(PShape a, HashSet<PVector> v) {
    int c = a.getVertexCount();
    for (int i = 0; i < c; i++) {
      v.add(a.getVertex(i));
    }
    for (int i = 0; i < a.getChildCount(); i++) {
      getVerticesFromShape(a.getChild(i), v);
    }
  }

  // Initialize the field vertices using provided set of vertices
  private void makeVertices(HashSet<PVector> v) {
    this.vertices = new ArrayList<ArrayList<PVector>>();
    for (PVector vv : v) {
      int lb = lowerBoundInOrderOfX(vv.x);
      if (lb == -1) {
        ArrayList<PVector> a = new ArrayList<PVector>();
        a.add(vv);
        this.vertices.add(0, a);
      } else {
        if (vv.x == vertices.get(lb).get(0).x)
          insertInOrderOfY(vertices.get(lb), vv);
        else {
          ArrayList<PVector> a = new ArrayList<PVector>();
          a.add(vv);
          this.vertices.add(lb+1, a);
        }
      }
    }
  }

  // Insert vertex v into array a based on y value.
  // Array a is ordered by y intially and after.
  private void insertInOrderOfY(ArrayList<PVector> a, PVector v) {
    int lb = lowerBoundInOrderOfY(a, v.y);
    if (lb < 0)
      a.add(0, v);
    else
      a.add(lb+1, v);
  }

  // Return the index of the vertex in array a that is less than 
  // or equal to y and is the largest of all such vertices.
  // Vertices in array a is ordered by y values
  int lowerBoundInOrderOfY(ArrayList<PVector> a, float y) {
    if (a.size() == 0)
      return -1;
    if (y < a.get(0).y)
      return -1;
    return lowerBoundInOrderOfYInternal(a, y, 0, a.size());
  }
  private int lowerBoundInOrderOfYInternal(ArrayList<PVector> a, float y, int start, int end) {//end is exclusive
    if (start + 1 == end)
      return start;
    int mid = start + (end-start)/2;
    if (y < a.get(mid).y)
      return lowerBoundInOrderOfYInternal(a, y, start, mid);
    else
      return lowerBoundInOrderOfYInternal(a, y, mid, end);
  }

  // Return the index of the array lists in the field vertices that is 
  // less than or equal to x and is the largest of all such array lists.
  int lowerBoundInOrderOfX(float x) {
    if (this.vertices.size() == 0)
      return -1;
    if ( x < this.vertices.get(0).get(0).x)
      return -1;
    return lowerBoundInOrderOfXInternal(x, 0, this.vertices.size());
  }
  private int lowerBoundInOrderOfXInternal(float x, int start, int end) {//end is exclusive
    if (start + 1 == end)
      return start;
    int mid = start + (end-start)/2;
    if (x < this.vertices.get(mid).get(0).x)
      return lowerBoundInOrderOfXInternal(x, start, mid);
    else
      return lowerBoundInOrderOfXInternal(x, mid, end);
  }

  float getMinX() { 
    return this.minX;
  } 
  float getMaxX() { 
    return this.maxX;
  } 
  float getMinY() { 
    return this.minY;
  } 
  float getMaxY() { 
    return this.maxY;
  } 
  float getMaxZ() { 
    return this.maxZ;
  } 
  float getMinZ() { 
    return this.minZ;
  } 
  
  PShape getConvexHull() { 
    return this.convexHull;
  }

  // Return the smallest triangle that encloses the provided vertex on the xy plane. 
  PShape findSmallestEnclosingPolygon(PVector xy) {
    // Increase performance
    if (xy.x > this.maxX || xy.x < this.minX || xy.y > this.maxY || xy.y < this.minY)
      return null;  
    if (!isInFacet(this.convexHull, xy))
      return null;

    int indexLeft = lowerBoundInOrderOfX(xy.x);
    int indexRight = indexLeft + 1;
    while (indexLeft >= 0 || indexRight < this.vertices.size()) {
      ArrayList<PVector> xColumn;
      int indexDown, indexUp;
      if (indexLeft >= 0) {
        xColumn = this.vertices.get(indexLeft);
        indexDown = lowerBoundInOrderOfY(xColumn, xy.y);
        indexUp = indexDown + 1;
        while (indexUp < xColumn.size() || indexDown >= 0) {
          if (indexDown >= 0) {
            PVector point = xColumn.get(indexDown);
            PShape s = findFacet(point, xy);
            if (s != null)
              return s;
            indexDown--;
          } // end of indexDown
          if (indexUp < xColumn.size()) {
            PVector point = xColumn.get(indexUp);
            PShape s = findFacet(point, xy);
            if (s != null)
              return s;
            indexUp++;
          } // end of indexUp
        } // end of indexLeft
        indexLeft--;
      }
      if (indexRight < this.vertices.size()) {
        xColumn = this.vertices.get(indexRight);
        indexDown = lowerBoundInOrderOfY(xColumn, xy.y);
        indexUp = indexDown + 1;
        while (indexUp < xColumn.size() || indexDown >= 0) {
          if (indexDown >= 0) {
            PVector point = xColumn.get(indexDown);
            PShape s = findFacet(point, xy);
            if (s != null)
              return s;
            indexDown--;
          } // end of indexDown
          if (indexUp < xColumn.size()) {
            PVector point = xColumn.get(indexUp);
            PShape s = findFacet(point, xy);
            if (s != null)
              return s;
            indexUp++;
          } // end of indexUp
        } // end of indexRight
        indexRight++;
      }
    } // end of outmost loop
    return null;
  }

  // Return the facets where point is one the facet's points and xy is within the facet
  private PShape findFacet(PVector point, PVector xy) {
    ArrayList<PShape> shapes = this.facets.get(point);
    if (shapes == null)
      return null;
    for (PShape s : shapes) {
      if (isInFacet(s, xy)) {
        return s;
      }
    }
    return null;
  }

  // Return true if point xy is within the facet
  boolean isInFacet(PShape shape, PVector xy) {
    int n = shape.getVertexCount();
    if (n < 3)
      return false;
    int count = 0;    
    for (int i = 0; i < n; i++) {
      PVector p1 = shape.getVertex(i);
      PVector p2 = shape.getVertex((i+1)%n);
      if ((xy.y <= p1.y && xy.y >= p2.y) || (xy.y >= p1.y && xy.y <= p2.y)) {
        if (p2.y==p1.y) {
          if ((xy.x <= p1.x && xy.x >= p2.x) || (xy.x >= p1.x && xy.x <= p2.x))
            return true;
        }          
        float cx = ((xy.y - p1.y)*(p2.x-p1.x)) / (p2.y-p1.y) + p1.x;
        if (xy.x == cx)
          return true;
        else if (xy.x < cx)
          ++count;
      }
    } 
    return (count % 2 != 0);
  }

  // Print internal states for debugging.
  void printStates(boolean verbose) {
    if (null != this.vertices) {
      println("Vertices", this.vertices.size());
      if (verbose) {
        for (ArrayList<PVector> vv : this.vertices) {
          println("x =", vv.get(0).x);
          for (PVector v : vv) {
            println(v.x, v.y, v.z);
          }
        }
      }
    }
    if (null != this.facets) {
      println("Facets", this.facets.size());
      if (verbose) {
        for (Map.Entry<PVector, ArrayList<PShape>> entry : this.facets.entrySet()) {
          PVector key = entry.getKey();
          ArrayList<PShape> value = entry.getValue();
          println("key =", key);
          for (PShape s : value) {
            for (int i = 0; i < s.getVertexCount(); ++i) {
              println(s.getVertex(i));
            }
            // TODO
            //HashSet<PVector> vset = new HashSet<PVector>();
            //for (int i = 0; i < s.getVertexCount(); ++i) {
            //  vset.add(s.getVertex(i));
            //}
            //if (vset.size() != s.getVertexCount()) 
            //  println("Duplicate vertices in shape");
            //ConvexHull ch = new ConvexHull();
            //ch.findAndSetConvexHull(vset);
            //if (ch.getVertices().size() != vset.size()) 
            //  println("Facet is not convex");
            println();
          }
        }
      }
    }

    if (this.convexHull != null) {
      println("Convex Hull");
      for (int i = 0; i < this.convexHull.getVertexCount(); i++) {
        println(this.convexHull.getVertex(i));
      }
      println();
    }

    println("minX =", this.minX, "minY =", this.minY, "maxX =", this.maxX, "maxY =", this.maxY);
  }
} 

class TestShapeGeometry {
  TestShapeGeometry () {
  }

  public void testLowerBoundInOrderOfY() {
    ShapeGeometry s = new ShapeGeometry();
    ArrayList<PVector> a = new ArrayList<PVector>();
    for (int i = 0; i < 7; i++) {
      a.add(new PVector(0, i, 0));
    }
    int rc;
    if (4 != (rc = s.lowerBoundInOrderOfY(a, 4.5)))
      println("4.5 error " + rc);
    if (6 != (rc = s.lowerBoundInOrderOfY(a, 6.0)))
      println("6.0 error " + rc);
    if (6 != (rc = s.lowerBoundInOrderOfY(a, 7.0)))
      println("7.0 error " + rc);
    if (0 <= (rc = s.lowerBoundInOrderOfY(a, -2)))
      println("-2 error " + rc);
  }

  void testConstructor() {
    PShape shape = loadShape("s-tree.obj");
    ShapeGeometry sg = new ShapeGeometry(shape);
    sg.printStates(true);
  }

  void testIsInFacet() {
    ShapeGeometry sg = new ShapeGeometry();
    PShape s = createShape();
    s.beginShape();
    s.vertex(0, 0);
    s.vertex(0, 50);
    s.vertex(25, 75);
    s.vertex(50, 50);
    s.vertex(50, 0);
    s.endShape(CLOSE);
    PVector xy = new PVector();
    float [] xyInFacet = {1, 1, 25, 70, // inside
      0, 0, 25, 0, 50, 0, // on bottom edge
      50, 25, 50, 50, 25, 75, 0, 50, 0, 25
    };
    for (int i = 0; i < xyInFacet.length; i += 2) {
      xy.x = xyInFacet[i];
      xy.y = xyInFacet[i+1];
      if (!sg.isInFacet(s, xy)) 
        println(xy.x, xy.y, "testIsInFacet in facet failed");
    }
    float [] xyOutOfFacet = {-10, 20, 0, 75, 10, 70, 25, 80, 60, 50, 25, -10};
    for (int i = 0; i < xyOutOfFacet.length; i += 2) {
      xy.x = xyOutOfFacet[i];
      xy.y = xyOutOfFacet[i+1];
      if (sg.isInFacet(s, xy)) 
        println(xy.x, xy.y, "testIsInFacet out of facet failed");
    }
  }
  //void testLowerBoundInOrderOfX() {
  //  HashSet<PVector> a = new HashSet<PVector>();
  //  for (int i = 0; i < 7; i++) {
  //    a.add(new PVector(i, 0, 0));
  //  }
  //  ShapeGeometry s = new ShapeGeometry();
  //  s.initializeVertices(a);
  //  // s.print(true);
  //  int rc;
  //  if (4 != (rc = s.lowerBoundInOrderOfX(4.5)))
  //    println("4.5 error " + rc);
  //  if (6 != (rc = s.lowerBoundInOrderOfX(6.0)))
  //    println("6.0 error " + rc);
  //  if (6 != (rc = s.lowerBoundInOrderOfX(7.0)))
  //    println("7.0 error " + rc);
  //  if (0 <= (rc = s.lowerBoundInOrderOfX(-2)))
  //    println("-2 error " + rc);
  //}
}
