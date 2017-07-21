

public class Sweeper {
    DoublyEdgeList deList;
    List<SweepVertex> verts;

    List<SweepEdge> bst;

    public Sweeper(List<List<PVector>> init) {
        println("Sweeper initialized");
        deList = new DoublyEdgeList(init);
        verts = new ArrayList<SweepVertex>();
        bst = new ArrayList<SweepEdge>();
    }

    PriorityQueue<SweepVertex> pq;
    public void makeMonotone() {
        println("MAKE MONOTONE");
        List<DFace> oldFaces = new ArrayList<DFace>(deList.faces);

        for (int i = 0; i < oldFaces.size(); ++i) {
            if (oldFaces.get(i).outerEdge == null) continue;
            DFace currFace = oldFaces.get(i);
            List<SweepVertex> sVerts = setupVertices(currFace);
            verts = sVerts;

            pq = new PriorityQueue<SweepVertex>(sVerts);
            while (!pq.isEmpty()) {
                SweepVertex curr = pq.poll();
                handleSweepVertex(curr);
            }
        }
        println("End MONOTONE");
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
        }
        println("loopMonotone end");
    }

    public List<SweepVertex> setupVertices(DFace face) {
        List<SweepVertex> list = new ArrayList<SweepVertex>();
        DHalfEdge currEdge = face.outerEdge;

        SweepVertex oldVertex = null;
        SweepEdge   oldEdge = null;
        do {
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
            oldVertex = v;
            oldEdge = e;
            currEdge = currEdge.next;
        } while (!currEdge.equals(face.outerEdge));

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
            } else {
                return SweepVertexType.SPLIT;
            }
        } else if (isBelowNext && isBelowPrev) {
            if (cross.z > 0) {
                return SweepVertexType.END;
            } else {
                return SweepVertexType.MERGE;
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
            deList.addEdge(eim1.helper.id, vi.id);
            // connect (vi, eim1.helper);
        }
        bst.remove(eim1);
        SweepEdge ej = findLeftSweepEdge(vi);
        if (ej.helper.type == SweepVertexType.MERGE) {
            deList.addEdge(ej.helper.id, vi.id);
            // connect (vi, ej.helper)
        }
        ej.helper = vi;
    }

    public void handleRegular(SweepVertex vi) {
        if (vi.interiorToRight()) {
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
        SweepEdge left = null;
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
        if (displayController.drawState  == 1) {
            drawDEList();
        } else if (displayController.drawState  == 2) {
            drawSweep();
        }

        // if (currSweepVertex != null) {
        //     stroke(GREEN);
        //     strokeWeight(3);
        //     line(-100, currSweepVertex.coord.y, 2000, currSweepVertex.coord.y);
        //     ellipse(currSweepVertex.coord.x, currSweepVertex.coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);
        // }
    }

    public void drawDEList() {
        deList.draw();
    }

    public void drawSweep() {
        deList.drawEdges();
        for (SweepVertex v : verts) v.draw();
    }

    public void handleKey() {
        if (key == 'n') loopMonotone();
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
        float dy = o.coord.y - this.coord.y;

        if (dy == 0) {
            return (int) (this.coord.x - o.coord.x);
        } else {
            return (int) dy;
        }
    }

    public boolean isBelow(SweepVertex o) {
        double diff = this.coord.y - o.coord.y;
        if (diff == 0.0) {
            return this.coord.x > o.coord.x;
        } else {
            return diff < 0;
        }
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
                noFill();
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
                fill(BLACK);
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
        return "[" + coord.x + " " + coord.y + "]";
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
        float dy = prevVertex.coord.y - nextVertex.coord.y;

        if (dy == 0) {
            return nextVertex.coord.x - prevVertex.coord.x < 0;
        } else {
            return dy > 0;
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