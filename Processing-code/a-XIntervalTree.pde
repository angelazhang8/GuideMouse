
// Interval tree of rectangles. The interval refers to x-range of the rectangle. 
class XIntervalTree {
  private XIntervalTreeNode root; // the tree root
  private int numNodes, numRectangles; // for debugging
  
  XIntervalTree(ArrayList<PShape> facets) {
    ArrayList<ShapeWithEnclosingRectangle> swer = new ArrayList<ShapeWithEnclosingRectangle>();
    for (PShape facet : facets) {
      swer.add(new ShapeWithEnclosingRectangle(facet));
    }
    // sort by the rectangle's x1
    Collections.sort(swer);
    this.numRectangles = swer.size();
    this.numNodes = 0;
    this.root = buildTree(swer, 0, swer.size());
  }
  
  // Build interval tree using elements of swer in range [begin, end). Return the tree root.
  // swer has been sorted by x1.
  XIntervalTreeNode buildTree(ArrayList<ShapeWithEnclosingRectangle> swer, int begin, int end) {
    if (begin == end)
      return null;
    // Use the middle rectangle to create a tree node.
    int mid = (begin + end) / 2;
    XIntervalTreeNode root = new XIntervalTreeNode(swer.get(mid));
    this.numNodes++;
    // Go right and left to add rectangles with same x1 to this node
    int i, j;
    for (i = mid+1; i < end && root.x1 == swer.get(i).x1; i++ ) {
      root.add(swer.get(i));
    }
    for (j = mid; j > begin && root.x1 == swer.get(j-1).x1; j-- ) {
      root.add(swer.get(j-1));
    }
    // Recursively build left and right subtree, then update this node's maxSubtreeX
    root.left = buildTree(swer, begin, j);
    root.right = buildTree(swer, i, end);
    if (root.left != null && root.left.maxSubtreeX > root.maxSubtreeX)
      root.maxSubtreeX = root.left.maxSubtreeX;
    if (root.right != null && root.right.maxSubtreeX > root.maxSubtreeX)
      root.maxSubtreeX = root.right.maxSubtreeX;
    return root;
  }
  
  // Return all rectangles that overlaps with the provided x and y-value.
  ArrayList<ShapeWithEnclosingRectangle> getAllRectanglesOverlapXY(float x, float y) {
    ArrayList<ShapeWithEnclosingRectangle> swer = new ArrayList<ShapeWithEnclosingRectangle>();
    getAllRectanglesOverlapXY(this.root, x, y, swer); 
    return swer;
  }
  
  // Add rectangles that overlaps with the provided x and y-value to result. The rectangles are on the tree specified the root node.
  void getAllRectanglesOverlapXY(XIntervalTreeNode node, float x, float y, ArrayList<ShapeWithEnclosingRectangle> result) {
    if (node == null || node.maxSubtreeX < x)
      return;
    // Add overlapping rectangles of this node to result
    for (ShapeWithEnclosingRectangle r : node.swer) {
      if (r.overlapX(x) && r.overlapY(y))
        result.add(r);
    }
    // Always need to step down the left subtree
    getAllRectanglesOverlapXY(node.left, x, y, result);
    // All nodes on the right subtree have x1 greater than current node's x1,
    // so need to step down the right subtree only when x > node.x1
    if (node.x1 < x)
      getAllRectanglesOverlapXY(node.right, x, y, result);
  }

  // Print the interval tree. For testing purposes.
  public void printTree(boolean verbose) {
    println("Facet interval tree: numNodes", this.numNodes, "numRectangles", numRectangles);
    printTree("", root, verbose);
  }
  // Traverse in-order, prefix indent string to make it easier to read
  private void printTree(String indent, XIntervalTreeNode root, boolean verbose) {
    if (null != root.left)
      printTree(indent + "|-", root.left, verbose);
    print(indent);
    root.printStates(verbose);
    if (null != root.right)
      printTree(indent + "|+", root.right, verbose);
  }
}

// A shape together with the smallest enclosing retangle for its XY-plane projection.
class ShapeWithEnclosingRectangle implements Comparable<ShapeWithEnclosingRectangle> {
  PShape shape; // the polygon
  float x1, x2, y1, y2; // the smallest enclosing rectangle
  
  ShapeWithEnclosingRectangle(PShape shape) {
    this.shape = shape;
    this.x1 = Float.MAX_VALUE;
    this.x2 = -Float.MAX_VALUE;
    this.y1 = Float.MAX_VALUE;
    this.y2 = -Float.MAX_VALUE;
    for (int i = 0; i < shape.getVertexCount(); i++) {
      if (this.x1 > shape.getVertex(i).x)
        this.x1 = shape.getVertex(i).x;
      if (this.x2 < shape.getVertex(i).x)
        this.x2 = shape.getVertex(i).x;
      if (this.y1 > shape.getVertex(i).y)
        this.y1 = shape.getVertex(i).y;
      if (this.y2 < shape.getVertex(i).y)
        this.y2 = shape.getVertex(i).y;
    }
  }

  // Whether the given x-value is in the x-range of this rectangle
  boolean overlapX(float x) {
    return (this.x1 <= x && x <= this.x2);
  }

  // Whether the given y-value is in the y-range of this rectangle
  boolean overlapY(float y) {
    return (this.y1 <= y && y <= this.y2);
  }

  // Used by Collections.sort to sort objects of this class by x1
  public int compareTo(ShapeWithEnclosingRectangle other) {
    return (this.x1 == other.x1 ? 0 : (this.x1 > other.x1 ? 1 : -1));
  }

  public void printStates(boolean verbose) {
    println("x [", this.x1, this.x2, "], y [", this.y1, this.y2, "]");
    if (verbose)
      printShape(this.shape);
  }
}

// A node on the interval tree. The key is x1 of the rectangles. The interval refers to [x1,x2].
// A node may contain multiple shapes with the same x1; these shapes are stored in the list swer.
class XIntervalTreeNode {
  XIntervalTreeNode left, right; // left and right child
  ArrayList<ShapeWithEnclosingRectangle> swer; // the list of shapes with same x1
  float maxSubtreeX; // Max x of subtree rooted at this node
  float x1; // x1 of all shapes at this node

  XIntervalTreeNode(ShapeWithEnclosingRectangle r) {
    this.left = this.right = null;
    this.swer = new ArrayList<ShapeWithEnclosingRectangle>();
    this.swer.add(r);
    this.x1 = r.x1;
    this.maxSubtreeX = r.x2;
  }

  // Add a rectangle to this node. The rectangle must have the same x1.
  void add(ShapeWithEnclosingRectangle r) {
    this.swer.add(r);
    if (r.x2 > this.maxSubtreeX)
      this.maxSubtreeX = r.x2;
  }

  public void printStates(boolean verbose) {
    println("x1", this.x1, "maxSubtreeX", this.maxSubtreeX, "numRectangles", this.swer.size());
    if (verbose) {
      for (ShapeWithEnclosingRectangle e : swer) {
        e.printStates(true);
      }
    }
  }
}
