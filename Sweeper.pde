

public class Sweeper {
    DoublyEdgeList deList;
    List<SweepVertex> verts;
    List<SweepEdge> bst;

    public Sweeper(List<List<PVector>> init) {
        println("Sweeper initialized");
        deList = new DoublyEdgeList();
        verts = new ArrayList<SweepVertex>();
        bst = new ArrayList<SweepEdge>();
        deList.initialize(init);
    }

    PriorityQueue<SweepVertex> pq;
    public void makeMonotone() {
        println("MAKE MONOTONE");
        List<DFace> oldFaces = new ArrayList<DFace>(deList.faces);
        List<SweepVertex> sVerts = new ArrayList<SweepVertex>();

        // Add most outer polygon face
        DFace currFace = oldFaces.get(0);
        sVerts.addAll(setupVertices(currFace, false));

        print(oldFaces);
        // Adding holes faces
        for (int i = 1; i < oldFaces.size(); ++i) {
            if (oldFaces.get(i).outerEdge == null) continue; // Outside Face
            currFace = oldFaces.get(i);
            sVerts.addAll(setupVertices(currFace, true));
        }
        verts = sVerts;

        pq = new PriorityQueue<SweepVertex>(sVerts);
        if (!DEBUG) {
            while (!pq.isEmpty()) {
                SweepVertex curr = pq.poll();
                handleSweepVertex(curr);
            }
        }
    }

    public List<MonotonePolygon> getMonotonePolygons() {
        return deList.getMonotonePolygons();
    }

    // Step by step process
    SweepVertex currSweepVertex = null;
    public void loopMonotone() {
        if (!pq.isEmpty()) {
            currSweepVertex = pq.poll();
            println(currSweepVertex.coord);
            handleSweepVertex(currSweepVertex);
        } else {
            currSweepVertex = null;
            println("loopMonotone end");
        }
    }

    //
    public List<SweepVertex> setupVertices(DFace face, boolean isHole) {
        List<SweepVertex> list = new ArrayList<SweepVertex>();
        DHalfEdge currEdge = face.outerEdge;
        if (isHole) currEdge = currEdge.twin;

        Set<DHalfEdge> visited = new HashSet<DHalfEdge>();

        SweepVertex oldVertex = null;
        SweepEdge   oldEdge = null;
        while (!visited.contains(currEdge)) {
            SweepVertex v = new SweepVertex();
            v.coord = currEdge.origin.coord;
            v.nextVertex = null;
            v.prevVertex = oldVertex;
            v.prevEdge = oldEdge;
            v.id = deList.vertices.indexOf(currEdge.origin);

            SweepEdge e = new SweepEdge();
            e.prevVertex = v;
            e.nextVertex = null;
            e.helper     = null;

            v.nextEdge = e;

            if (oldVertex != null) {
                oldVertex.nextVertex = v;
            }

            if (oldEdge != null) {
                oldEdge.nextVertex = v;
            }

            list.add(v);
            visited.add(currEdge);
            oldVertex = v;
            oldEdge = e;
            currEdge = currEdge.next;
        }

        SweepVertex firstVertex = list.get(0);
        SweepEdge firstEdge = firstVertex.nextEdge;

        firstVertex.prevVertex = oldVertex;
        firstVertex.prevEdge = oldEdge;

        oldVertex.nextVertex = firstVertex;
        oldEdge.nextVertex = firstVertex;


        for (SweepVertex v : list) {
            v.type = findSweepVertexType(v);
        }

        return list;
    }

    // Sweeping algorithm ======================================================
    public SweepVertexType findSweepVertexType(SweepVertex v) {
        SweepVertex next = v.nextVertex;
        SweepVertex prev = v.prevVertex;

        PVector nextVector = PVector.sub(next.coord, v.coord);
        PVector prevVector = PVector.sub(v.coord, prev.coord);
        PVector cross = prevVector.cross(nextVector);

        boolean isBelowNext = v.isBelow(next);
        boolean isBelowPrev = v.isBelow(prev);

        if (!isBelowNext && !isBelowPrev) {
            if (cross.z > 0) {
                return SweepVertexType.START;
            } else if (cross.z < 0){
                return SweepVertexType.SPLIT;
            } else {
                return SweepVertexType.REGULAR;
            }
        } else if (isBelowNext && isBelowPrev) {
            if (cross.z > 0) {
                return SweepVertexType.END;
            } else if (cross.z < 0) {
                return SweepVertexType.MERGE;
            } else {
                return SweepVertexType.REGULAR;
            }
        } else {
            return SweepVertexType.REGULAR;
        }
    }

    public void handleSweepVertex(SweepVertex v) {
        switch (v.type) {
            case START:
                handleStart(v);
                break;
            case END:
                handleEnd(v);;
                break;
            case SPLIT:
                handleSplit(v);
                break;
            case MERGE:
                handleMerge(v);
                break;
            case REGULAR:
                handleRegular(v);
                break;
        }
    }

    public void handleStart(SweepVertex vi) {
        SweepEdge ei = vi.nextEdge;
        bst.add(ei);
        ei.helper = vi;
    }

    public void handleEnd(SweepVertex vi) {
        SweepEdge eim1 = vi.prevEdge;
        if (eim1.helper.type == SweepVertexType.MERGE) {
            println("       ", "Add Edge");
            deList.addEdge(eim1.helper.id, vi.id);
        }
        bst.remove(eim1);
    }

    public void handleSplit(SweepVertex vi) {
        SweepEdge ej = findLeftSweepEdge(vi);
        deList.addEdge(ej.helper.id, vi.id);
        ej.helper = vi;
        SweepEdge ei = vi.nextEdge;
        bst.add(ei);
        ei.helper = vi;
    }

    public void handleMerge(SweepVertex vi) {
        SweepEdge eim1 = vi.prevEdge;
        if (eim1.helper.type == SweepVertexType.MERGE) {
            println("       ", "Add Edge");
            deList.addEdge(eim1.helper.id, vi.id);
            // connect (vi, eim1.helper);
        }
        bst.remove(eim1);
        SweepEdge ej = findLeftSweepEdge(vi);
        if (ej.helper.type == SweepVertexType.MERGE) {
            println("       ", "Add Edge");
            deList.addEdge(ej.helper.id, vi.id);
            // connect (vi, ej.helper)
        }
        ej.helper = vi;
    }

    public void handleRegular(SweepVertex vi) {
        if (vi.interiorToRight()) {
            println("       ", "interiorToRight");
            SweepEdge eim1 = vi.prevEdge;
            if (eim1.helper.type == SweepVertexType.MERGE) {
                deList.addEdge(eim1.helper.id, vi.id);
                // connect (vi, eim1.helper)
            }
            bst.remove(eim1);
            SweepEdge ei = vi.nextEdge;
            bst.add(ei);
            ei.helper = vi;
        } else {
            println("       ", "interior not to Right");
            SweepEdge ej = findLeftSweepEdge(vi);
            if (ej.helper.type == SweepVertexType.MERGE) {
                deList.addEdge(ej.helper.id, vi.id);
                // connect (vi, ej.helper)
            }
            ej.helper = vi;
        }
    }

    public SweepEdge findLeftSweepEdge(SweepVertex v) {
        PVector c = v.coord;

        float minX = 100;
        SweepEdge left = bst.get(0);
        for (SweepEdge e : bst) {
            float dx = e.getXInterect(c.y) - c.x;
            if (dx < 0) {
                if (minX == 100 || dx > minX) {
                    left = e;
                    minX = dx;
                }
            }
        }

        return left;
    }


    public void draw() {
        if (displayController.drawState == 1 ||
            displayController.drawState == 4) drawDEList();
        if (displayController.drawState == 2) drawDEListArrows();
        if (displayController.drawState == 3) drawSweep();

        if (DEBUG && currSweepVertex != null) {
            stroke(GREEN);
            strokeWeight(3);
            line(-100, currSweepVertex.coord.y, 2000, currSweepVertex.coord.y);
        }
    }

    public void drawDEList() {
        deList.draw();
    }

    public void drawDEListArrows() {
        deList.draw();
        deList.drawArrows();
    }

    public void drawSweep() {
        deList.drawEdges();
        for (SweepVertex v : verts) v.draw();
    }

    public void handleKey() {
        if (DEBUG && key == 'n') {
            if (!pq.isEmpty()) {
                loopMonotone();
            } else {
                currSweepVertex = null;
            }
            
            deList.triangulateMonotonePolygon();
        }
        if (key == 'u') deList.triangulateMonotonePolygons();
    }
}


public enum SweepVertexType {
    START, END, REGULAR, SPLIT, MERGE,
}

public class SweepVertex implements Comparable<SweepVertex>{
    public SweepVertexType type;
    public PVector coord;
    public SweepVertex nextVertex, prevVertex;
    public SweepEdge nextEdge, prevEdge;
    public int id;

    @Override
    public int compareTo(SweepVertex o) {
        if (this.coord.y == o.coord.y && this.coord.x == o.coord.x)
            return 0;
        else if (isBelow(o))
            return 1;
        else
            return -1;
    }

    public boolean isBelow(SweepVertex o) {
        return this.coord.y < o.coord.y || 
              (this.coord.y == o.coord.y && this.coord.x > o.coord.x);
    }

    /**
    *   USE FOR ONLY REGULAR VERTEX
    */
    public boolean interiorToRight() {
        return nextEdge.interiorToRight();
    }

    public void draw() {
        stroke(BLACK);
        strokeWeight(1);
        switch (type) {
            case START:
                fill(WHITE);
                rect(coord.x-8, coord.y-8, 16, 16);
                break;
            case END:
                fill(BLACK);
                rect(coord.x-8, coord.y-8, 16, 16);
                break;
            case REGULAR:
                fill(BLACK);
                ellipse(coord.x, coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);
                break;
            case SPLIT:
                fill(WHITE);
                triangle(coord.x-8, coord.y-4, coord.x+8, coord.y-4, coord.x, coord.y+8);
                break;
            case MERGE:
                fill(BLACK);
                triangle(coord.x-8, coord.y+4, coord.x+8, coord.y+4, coord.x, coord.y-8);
                break;
        }
    }


    @Override
    public String toString() {
        return "[" + coord.x + " " + coord.y + ", " + type + "]";
    }
} 

public class SweepEdge {
    public SweepVertex prevVertex, nextVertex;
    public SweepVertex helper;

    public boolean intersectsY(float y) {
        PVector p = prevVertex.coord;
        PVector n = nextVertex.coord;

        return (n.y <= y && p.y >= y) || (n.y >= y && p.y <= y);
    }

    public float getXInterect(float y) {
        PVector base = prevVertex.coord;
        float dy = nextVertex.coord.y - prevVertex.coord.y;
        float dx = nextVertex.coord.x - prevVertex.coord.x;

        if (dy == 0) {
            return base.x;
        }
        return base.x + (y - base.y) * (dx/dy);
    }

    public boolean interiorToRight() {
        if (prevVertex.coord.y == nextVertex.coord.y) {
            return nextVertex.coord.x > prevVertex.coord.x;
        } else {
            return prevVertex.coord.y > nextVertex.coord.y;
        }
    }

    public void draw() {
        draw(CYAN);
    }

    public void draw(color c) {
        PVector u = prevVertex.coord;
        PVector v = nextVertex.coord;

        stroke(c);
        strokeWeight(2);
        line(u.x, u.y, v.x, v.y);
    }

    @Override
    public String toString() {
        return "[" + prevVertex + ", " + nextVertex + "]";
    }
}