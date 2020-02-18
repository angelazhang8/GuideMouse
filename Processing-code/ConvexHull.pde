// Implement the Graham algorithm to find the convex hull of a set of vertices.
class ConvexHull {
  ConvexHull() {
  }

  // Return the convex hull of the provided set of vertices, 
  // which must be distinct in terms of x and y.
  // The returned convex hull is in polar angle order.
  // The 0th vertex is the bottomest-leftest point. 
  // From the 0th vertex to each remaining point is a vector that has a polar angle.
  ArrayList<PVector> getConvexHull(HashSet<PVector> v) {
    ArrayList<PVector> pts = new ArrayList<PVector>();
    pts.addAll(v);
    return grahamScan(pts);
  }

  // Determine if the point 'p' is in this convex polygon
  //boolean isInConvexHull(PVector p) {
  //  if(p.x > maxX || p.x < minX || p.y > maxY || p.y < minY)
  //    return false;
  //  for (int i = 0; i < vertices.size(); ++i) {
  //    if (counterClockWise(vertices.get(i), vertices.get((i+1)%vertices.size()), p) < 0)
  //      return false;
  //  }
  //  return true; 
  //}


  // Returns the index of the point with the smallest 'y' value
  // If there is a tie, break tie by smallest 'x' value
  int indexOfBottomestPoint(ArrayList<PVector> points) {
    int pIndex = 0;
    for (int i = 0; i < points.size(); i++) {
      if (points.get(i).y < points.get(pIndex).y) {
        pIndex = i;
      } else if (points.get(i).y == points.get(pIndex).y) {
        if (points.get(i).x < points.get(pIndex).x) {
          pIndex = i;
        }
      }
    }
    return pIndex;
  }

  // Swap the points at the two indexes in the array
  void swap(ArrayList<PVector> points, int i, int j) {
    PVector tempvar = points.get(i);
    points.set(i, points.get(j));
    points.set(j, tempvar);
  }

  // Position vectors 'a' and 'b'
  // Calculate the cross product of vectors 'a' and 'b'
  // If ccw > 0, then counterclockwise, or < 180 degrees
  // If ccw < 0, then clockwise, or > 180 degrees
  // If ccw = 0, then collinear
  float counterClockWise (PVector o, PVector a, PVector b) {
    return (a.x - o.x)*(b.y - o.y) - (a.y - o.y)*(b.x - o.x);
  }

  // Return the distance between the two points.
  float calculateDistance(PVector a, PVector b) {
    float d = sqrt((pow((a.x-b.x), 2) + pow((a.y-b.y), 2)));
    return d;
  }

  // Gramham Scan algorithm: https://en.wikipedia.org/wiki/Graham_scan
  // Take in an array of points sorted by polar angles
  // The point at index 0 is the origin
  // Returns the convex hull, the points are in the same order as in the input array
  ArrayList<PVector> grahamScan(ArrayList<PVector> points) { 
    int i = indexOfBottomestPoint(points);
    swap(points, i, 0);
    points = sortByPolarAngle(points);
    ArrayList<PVector> ch = new ArrayList<PVector>();
    ch.add(points.get(0));
    ch.add(points.get(1)); //first two points in the array are in the convex hull
    for (i = 2; i < points.size(); i++) {
      while (ch.size() >= 2 && counterClockWise(ch.get(ch.size()-2), ch.get(ch.size()-1), points.get(i)) <= 0) { // left turn
        ch.remove(ch.size()-1);
      }
      ch.add(points.get(i));
    }
    return ch;
  }

  // Take the arraylist 'points' and sort them based on:
  //   1. Point at index 0 is the origin
  //   2. Find position vectors for all points using the newly established origin
  //   3. Sort points based on their vectors' polar angles
  ArrayList<PVector> sortByPolarAngle(ArrayList<PVector> points) {
    PVector origin = points.get(0);
    points.remove(0); //remove origin
    ArrayList<PVector> result = mergeSort(origin, points, 0, points.size()-1); //sort
    result.add(0, origin); //add origin back in
    return result;
  }

  // Sorts the vectors in the specified range by polar angle.
  // The vectors are from the point 'o' to the points in the arraylist v.
  // Both start and end are inclusive.
  ArrayList<PVector> mergeSort(PVector o, ArrayList<PVector> v, int start, int end) {
    if ( start == end ) {  
      ArrayList<PVector> arrayWithOneElement = new ArrayList<PVector>();
      arrayWithOneElement.add(v.get(start));
      return arrayWithOneElement;
    } else {
      int middle = (end + start) / 2;  //finds the middle index between start and end
      ArrayList<PVector> sortedLeftHalf  = mergeSort(o, v, start, middle );     // recursive function-call
      ArrayList<PVector> sortedRightHalf = mergeSort(o, v, middle + 1, end );   // recursive function-call
      ArrayList<PVector> sortedAll = merge(o, sortedLeftHalf, sortedRightHalf);
      return sortedAll;
    }
  }

  ArrayList<PVector> merge(PVector o, ArrayList<PVector> a, ArrayList<PVector> b ) {
    ArrayList<PVector> c = new ArrayList<PVector>();
    int i = 0;
    int j = 0;
    int k = 0;
    for (int l = 0; l < (a.size()+b.size()); l++) { // empty arraylist
      c.add(new PVector(0, 0));
    }
    while (i < a.size() && j < b.size()) {  
      // if a.get(i) to b.get(j) is counter-clockwise, put a.get(i) first
      // if a.get(i) and b.get(j) are colinear, put the point with the shortest distance to the origin first
      // if a.get(i) to b.get(j) is clockwise, put b.get(j) first
      float ccw = counterClockWise(o, a.get(i), b.get(j));
      if ( ccw > 0) {
        c.set(k, a.get(i));      
        i++;
      } else if (ccw < 0) {
        c.set(k, b.get(j));
        j++;
      } else { // for collinear cases, the point closest to the origin must be added first in the sorted array
        float d1 = calculateDistance(o, a.get(i));
        float d2 = calculateDistance(o, b.get(j));
        if ( d1 > d2) { 
          c.set(k, b.get(j));
          j++;
        } else {
          c.set(k, a.get(i));
          i++;
        }
      }
      k++;
    } 
    if (i == a.size()) {
      for (int m = j; m < b.size(); m++) {  
        c.set(k, b.get(m));
        k++;
      }
    } else {
      for (int m = i; m < a.size(); m++) {  
        c.set(k, a.get(m));
        k++;
      }
    }
    return c;
  }
}
