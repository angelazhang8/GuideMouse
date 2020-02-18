// Keep the shape's genometry information.
class ShapeGeometry2 {
  // Convex hull of all vertices on XY plane projection
  private PShape convexHull;
  // Max and min values for x, y, z for all vertices
  private float minX, minY, minZ, maxX, maxY, maxZ;
  // Interval tree for all facets.
  private XIntervalTree facetIntervalTree;

  ShapeGeometry2() {
  }

  // Initialize with the provided shape.
  ShapeGeometry2(PShape shape) {
    HashSet <PVector> allVertices = new HashSet<PVector>();
    ArrayList<PShape> allFacets = new ArrayList<PShape>();
    getAllVerticesFromShape(shape, allVertices);
    getAllFacetsFromShape(shape, allFacets);
    println("Total number of vertices", allVertices.size());
    println("Total number of facets", allFacets.size());
    initializeMinMaxXYZ(allVertices);
    initializeConvexHull(allVertices);
    this.facetIntervalTree = new XIntervalTree(allFacets);
  }

  // Add all vertices of the shape to the set.
  private void getAllVerticesFromShape(PShape shape, HashSet<PVector> allVertices) {
    for (int i = 0; i < shape.getVertexCount(); i++) {
      allVertices.add(shape.getVertex(i));
    }
    for (int i = 0; i < shape.getChildCount(); i++) {
      getAllVerticesFromShape(shape.getChild(i), allVertices);
    }
  }

  // Add all facets of the shape to the list.
  private void getAllFacetsFromShape(PShape shape, ArrayList<PShape> allFacets) {
    if (PShape.GEOMETRY == shape.getFamily()) {
      allFacets.add(shape);
    } else {
      for (int i = 0; i < shape.getChildCount(); i++) {
        getAllFacetsFromShape(shape.getChild(i), allFacets);
      }
    }
  }

  // Initialize the max/min x, y, z values
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

  // Initialize the convex hull.
  void initializeConvexHull(HashSet <PVector> allVertices) {
    ConvexHull ch = new ConvexHull();
    HashSet<PVector> vNoZ = new HashSet<PVector>();
    for (PVector e : allVertices ) {
      // You just care about x and y values and not z
      vNoZ.add(new PVector(e.x, e.y, 0));
    }
    ArrayList<PVector> chvertices = ch.getConvexHull(vNoZ);
    this.convexHull = createShape(PShape.GEOMETRY);
    this.convexHull.beginShape();
    for (PVector e : chvertices) {
      this.convexHull.vertex(e.x, e.y);
    }
    this.convexHull.endShape(CLOSE);
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
  float getMinZ() { 
    return this.minZ;
  } 
  float getMaxZ() { 
    return this.maxZ;
  } 
  PShape getConvexHull() { 
    return this.convexHull;
  }

  // Return the visible facet that encloses the provided vertex on the XY plane. 
  PShape getVisibleFacet(PVector xy) {
    // Increase performance
    if (xy.x > this.maxX || xy.x < this.minX || xy.y > this.maxY || xy.y < this.minY)
      return null;  
    if (!isInFacet(this.convexHull, xy))
      return null;

    // Get all shapes where xy is in their enclosing rectangles.
    ArrayList<ShapeWithEnclosingRectangle> swer = this.facetIntervalTree.getAllRectanglesOverlapXY(xy.x, xy.y);
    int rectangleCount = swer.size();
    // Remove the shapes where xy is not in their XY plane projection
    for (int i = 0; i < swer.size(); ) {
      if (!isInFacet(swer.get(i).shape, xy))
        swer.remove(i);
      else
        ++i;
    }

    int facetCount = swer.size(); 
    // If no enclosing facet exists, return null.
    if (swer.size() == 0) {
      if (DEBUG_PRINT_VISIBLE_FACET)
          println("In convex hull, numRect", rectangleCount, "numFacets 0");
      return null;
    }

    // If only one enclosing facet exists, return it.
    if (swer.size() == 1) {
      if (DEBUG_PRINT_VISIBLE_FACET)
          println("In convex hull, numRect", rectangleCount, "numFacets 1");
      return swer.get(0).shape;
    }

    // If there are multiple enclosing facets, find the facet that has the
    // largest z value at xy. 
    // There may exist multiple such facets when xy is at the intersection of
    // thoses facets, return one of them.
    float maxZatXY = -Float.MAX_VALUE;
    int maxZcount = 0;
    int indexOfmaxZatXY = -1;
    PShape shape;
    for (int i = 0; i < swer.size(); ++i) {
      shape = swer.get(i).shape;
      PVector a = getNormalVectorAndSetHeight(shape, xy);
      if (a == null) {
        print("WARNING skip shape with no normal vector");
        printShape(shape);
        continue;
      }
      if (xy.z == -Float.MAX_VALUE) {
        print("WARNING skip shape parallel to Z-axis");
        printShape(shape);
        continue;
      }
      if (xy.z == maxZatXY) {
        maxZcount++;
      } else if (maxZatXY < xy.z) {
        maxZcount = 1;
        maxZatXY = xy.z;
        indexOfmaxZatXY = i;
      }
    }
    if (indexOfmaxZatXY == -1) {
      print("WARNING no intersecting facet. In convex hull, numRect", rectangleCount, "numFacets", facetCount);
      return null;
    }
    shape = swer.get(indexOfmaxZatXY).shape;
    // Print the visible facet
    if (DEBUG_PRINT_VISIBLE_FACET) {
      print("In convex hull, numRect", rectangleCount, "numFacets", facetCount, "numMaxZ", maxZcount, "maxZ", maxZ, "facet ");
      printShape(shape);
    }
    return shape;
  }

  // Return true if point xy is within the polygon of the shape's projection on XY plane.
  // This function uses the ray casting algorithm.
  // https://www.geeksforgeeks.org/how-to-check-if-a-given-point-lies-inside-a-polygon/
  boolean isInFacet(PShape shape, PVector xy) {
    int n = shape.getVertexCount();
    // If the facet is a line or a point
    if (n < 3)
      return false;
    int count = 0;    
    for (int i = 0; i < n; i++) {
      PVector p1 = shape.getVertex(i);
      PVector p2 = shape.getVertex((i+1) % n);
      // If the point is between the y-values of both points
      if ((p1.y >= xy.y && xy.y >= p2.y) || (p1.y <= xy.y && xy.y <= p2.y)) {
        // If the line segment p1 to p2 is parallel to the x-axis
        if (p2.y == p1.y) {
          // return true if the point is between the x-values of the line segment
          // otherwise skip the line segment
          if ((p1.x >= xy.x && xy.x >= p2.x) || (p1.x <= xy.x && xy.x <= p2.x))
            return true;
          continue; // Don't add a counter
        }
        float cx = ((xy.y - p1.y) * (p2.x - p1.x)) / (p2.y - p1.y) + p1.x;
        // Return true if xy is on the segment
        if (xy.x == cx)
          return true;
        // If xy is on the right of the line segment, skip the line segment
        if (xy.x > cx)
          continue;
        // Now xy is on the left of the line segment.
        if ((xy.y < p1.y && xy.y > p2.y) || (xy.y > p1.y && xy.y < p2.y))
          // If xy.y is between p1.y and p2.y, increment count.
          ++count;
        else {
          // To prevent counting the intersection twice, if the intersection is
          // p2, do not increse the count;
          if (xy.y == p2.y)
            continue;
          else {
            // The intersection is p1, need to check this line segment and previous
            // line segment are on different side of the ray. If the previous line
            // segment is parallel to X-axis, go back further.
            int signForward = p1.y < p2.y ? 1 : -1 ; 

            PVector pBackward = shape.getVertex((i+n-1)%n);
            if (pBackward.y == xy.y) {
              pBackward = shape.getVertex((i+n-2)%n);
            }   
            int signBackward = p1.y < pBackward.y ? 1 : -1 ; 
            if (signForward == signBackward)
              continue;
            ++count;
          }
        }
      }
    } 
    return (count % 2 != 0);
  }

  // Set the z value of the xy coordinate on the plane formed by the normal vector and position vector.
  // The plane must not be parallel to the Z axis, i.e., normal.z cannot be zero.
  void setZForXYonPlane(final PVector normal, final PVector position, PVector xy) {
    PVector directionVector = PVector.sub(xy, position); 
    float sum = directionVector.x * normal.x + directionVector.y * normal.y;
    directionVector.z = -(sum)/normal.z;
    xy.z = directionVector.z + position.z;
  }

  // Return the normal vector of the plane formed by the three points.
  // The three points must be distinct.
  PVector getNormalVector(final PVector a, final PVector b, final PVector c) {
    final PVector a2b = PVector.sub(b, a);
    final PVector a2c = PVector.sub(c, a);
    return a2b.cross(a2c);
  }

  // Return the normal vector of the facet and set z value for xy on the facet.
  // If no such place (e.g. only two vertices), return null.
  // If the plane is parallel to the Z axis, set z value to -Float.MAX_VALUE.
  // If the vertices of the facet are not all on the same plane,
  // use the best fit plane.
  PVector getNormalVectorAndSetHeight(PShape facet, PVector xy) {
    int vertexCount = facet.getVertexCount();
    if (vertexCount < 3)
      return null;
    PVector normal = null;
    int index = -1;
    for (int i = 0; i < vertexCount - 2; i++) {
      normal = getNormalVector(facet.getVertex(i), facet.getVertex(i+1), facet.getVertex((i+2)%vertexCount));
      if (normal.mag() != 0) {
        index = i;
        break;
      }
    }
    if (index == -1) 
      return null;
    if (normal.z == 0) {
      xy.z = -Float.MAX_VALUE;
    } else {
      setZForXYonPlane(normal, facet.getVertex(index), xy);
    }
    // DEBUG verify vertices are on the same plane
    //float maxDot = 0;
    //for (int i = 0; i < vertexCount - 3; i++) {
    //  PVector p = PVector.sub(facet.getVertex(index), facet.getVertex((index+i)%vertexCount));
    //  float dot = abs(normal.dot(p));
    //  if (maxDot < dot)
    //    maxDot = dot;
    //}
    //println("getNormalVectorAndSetHeight maxdot is", maxDot);
    return normal;
  }

  void printStates() {
    println("Smallest enclosing box: minX =", this.minX, "minY =", this.minY, "minZ =", this.minZ, "maxX =", this.maxX, "maxY =", this.maxY, "maxZ =", this.maxZ);
  }
  void printConvexHull() {
    if (this.convexHull != null) {
      println("Convex Hull");
      for (int i = 0; i < this.convexHull.getVertexCount(); i++) {
        println(this.convexHull.getVertex(i));
      }
    }
  }
  void printIntervalTree(boolean verbose) {
    if (this.facetIntervalTree != null) {
      this.facetIntervalTree.printTree(verbose);
    }
  }
}
