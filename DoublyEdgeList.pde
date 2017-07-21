import java.util.*;

public class DoublyEdgeList {
    List<DVertex> vertices;
    List<DHalfEdge> edges;
    List<DFace> faces;

    public DoublyEdgeList(List<List<PVector>> init) {
        vertices = new ArrayList<DVertex>();
        edges = new ArrayList<DHalfEdge>();
        faces = new ArrayList<DFace>();
        initialize(init);
    }

    public void initialize(List<List<PVector>> init) {
        // create main component
        DFace mainInnerFace = new DFace();
        DFace mainOuterFace = new DFace();
        createComponent(init.get(0), mainInnerFace, mainOuterFace);

        // create holes
        for (int i = 1; i < init.size(); ++i) {
            createComponent(init.get(i), null, mainInnerFace);
        }
    }

    public void createComponent(List<PVector> verts, DFace inner, DFace outer) {
        DFace innerFace = outer;
        DFace outerFace = inner;
        if (inner == null) innerFace = new DFace();
        if (outer == null) outerFace = new DFace();

        if (!faces.contains(innerFace)) faces.add(innerFace);
        if (!faces.contains(outerFace)) faces.add(outerFace);
        DHalfEdge prevIEdge = null;
        DHalfEdge prevTEdge = null;

        for (int i = 0; i < verts.size(); ++i) {
            // Create vertex with edges
            DVertex v = new DVertex();
            DHalfEdge iEdge = new DHalfEdge();
            DHalfEdge tEdge = new DHalfEdge();

            vertices.add(v);
            edges.add(iEdge);
            edges.add(tEdge);

            // initialize vertex;
            v.coord = verts.get(i);
            v.incidentEdge = iEdge;

            // initialize incident Edge
            iEdge.origin = v;
            iEdge.twin = tEdge;
            iEdge.incidentFace = innerFace;
            iEdge.next = null;
            iEdge.prev = prevIEdge;

            // initialize twin edge
            tEdge.origin = null;
            tEdge.twin = iEdge;
            tEdge.incidentFace = outerFace;
            tEdge.next = prevTEdge;
            tEdge.prev = null;

            // set the previous iEdge's next
            if (prevIEdge != null) {
                prevIEdge.next = iEdge;
            }

            // set the previous tEdge's origin and prev
            if (prevTEdge != null) {
                prevTEdge.origin = v;
                prevTEdge.prev = tEdge;
            }
            
            prevIEdge = iEdge;
            prevTEdge = tEdge;
        }

        DVertex firstVertex = vertices.get(0);
        DHalfEdge firstIEdge = firstVertex.incidentEdge;
        DHalfEdge firstTEdge = firstVertex.incidentEdge.twin;

        firstIEdge.prev = prevIEdge;
        firstTEdge.next = prevTEdge;

        prevIEdge.next = firstIEdge;
        prevTEdge.origin = firstVertex;
        prevTEdge.prev = firstTEdge;

        innerFace.outerEdge = firstIEdge;
        if (outerFace.innerEdgeList == null)
            outerFace.innerEdgeList = new ArrayList<DHalfEdge>();
        outerFace.innerEdgeList.add(firstTEdge);
    }

    public void addEdge(int s, int t) {
        addEdge(vertices.get(s), vertices.get(t));
    }

    public void addEdge(DVertex l, DVertex r) {
        println("addEdge: " + l + " --- " + r);
        DFace newFace = new DFace();
        DHalfEdge goLeft = new DHalfEdge();
        DHalfEdge goRight = new DHalfEdge();

        DFace commonFace = findFace(l, r);
        DHalfEdge lEdge = findEdge(l, commonFace);
        DHalfEdge rEdge = findEdge(r, commonFace);

        goLeft.origin  = r;
        goLeft.twin = goRight;
        goLeft.next = lEdge;
        goLeft.prev = rEdge.prev;
        goLeft.incidentFace = commonFace;

        goRight.origin = l;
        goRight.twin = goLeft;
        goRight.next = rEdge;
        goRight.prev = lEdge.prev;
        goRight.incidentFace = newFace;

        lEdge.prev.next = goRight;
        rEdge.prev.next = goLeft;
        lEdge.prev = goLeft;
        rEdge.prev = goRight;

        // change faces.  goLeft keeps old face, goRight gets newFace
        commonFace.outerEdge = goLeft;
        newFace.outerEdge = goRight;

        DHalfEdge curr = goRight.next;
        while (curr != goRight) {
            curr.incidentFace = newFace;
            curr = curr.next;
        }

        edges.add(goLeft);
        edges.add(goRight);
        faces.add(newFace);
    }

    public DHalfEdge findEdge(DVertex v, DFace f) {
        DHalfEdge curr = f.outerEdge;
        List<DHalfEdge> list = new ArrayList<DHalfEdge>();
        while (!list.contains(curr)) {
            if (curr.origin == v) {
                return curr;
            }
            list.add(curr);
            curr = curr.next;
        }
        
        println("THIS IS NULL GUYS");
        return null;
    }

    public DFace findFace(DVertex s, DVertex t) {
        if (s.incidentEdge.incidentFace == t.incidentEdge.incidentFace) return s.incidentEdge.incidentFace;

        DHalfEdge currSEdge = s.incidentEdge;
        Set<DHalfEdge> sEdges = new HashSet<DHalfEdge>();
        Set<DFace> sFaces = new HashSet<DFace>();
        while (!sEdges.contains(currSEdge)) {
            sEdges.add(currSEdge);
            sFaces.add(currSEdge.incidentFace);
            currSEdge = currSEdge.twin.next;
        }

        DHalfEdge currTEdge = t.incidentEdge;
        Set<DHalfEdge> tEdges = new HashSet<DHalfEdge>();
        while (!tEdges.contains(currTEdge)) {
            if (currTEdge.incidentFace.outerEdge != null &&
                sFaces.contains(currTEdge.incidentFace)) return currTEdge.incidentFace;
            tEdges.add(currTEdge);
            currTEdge = currTEdge.twin.next;
        }

        println("NO FACE FOUND");
        return s.incidentEdge.incidentFace;
    }

    // MONOTONE TRIANGULATION ==================================================
    List<MonotonePolygon> polygons;
    public void triangulateMonotonePolygons() {
        println("BEGIN TRIANGULATEMONOTONEPOLYGONS");
        polygons = getMonotonePolygons() ;
        for (MonotonePolygon p : polygons) {
            p.draw();
            triangulateMonotonePolygon(p);
        }
    }

    public void triangulateMonotonePolygon(MonotonePolygon p) {
        println("TRIAGULATING: " + p);
        List<MonotoneVertex> stack = new ArrayList<MonotoneVertex>();
        List<MonotoneVertex> vertices = p.vertices;
        
        stack.add(vertices.get(0));
        stack.add(vertices.get(1));
        
        for (int j = 2; j < vertices.size() - 1; ++j) {
            println(j + " " + stack);
            MonotoneVertex uj = vertices.get(j);
            MonotoneVertex stackTop = stack.get(stack.size() - 1);
            if (uj.chainType != stackTop.chainType) {
                println("    Chains don't match");
                for (int k = stack.size() - 1; k > 0; --k) {
                    addEdge(uj.data, stack.get(k).data);
                }
                stack.clear();
                stack.add(vertices.get(j-1));
                stack.add(uj);
            } else {
                println("    Chains ARE GOOD");
                MonotoneVertex lastPop = stack.remove(stack.size() - 1);
                boolean keepPopping = true;
                while (keepPopping && !stack.isEmpty()) {
                    MonotoneVertex currPop = stack.remove(stack.size() - 1);
                    PVector ujLast   = PVector.sub(lastPop.data.coord, uj.data.coord);
                    PVector lastCurr = PVector.sub(currPop.data.coord, lastPop.data.coord);
                    if (uj.chainType == MonotoneChainType.RIGHT && ujLast.cross(lastCurr).z > 0 ||
                        uj.chainType == MonotoneChainType.LEFT  && ujLast.cross(lastCurr).z < 0) {
                        addEdge(uj.data, currPop.data);
                        lastPop = currPop;
                    } else {
                        stack.add(currPop);     // don't actually pop off
                        keepPopping = false;
                    }
                }
                stack.add(lastPop);
                stack.add(uj);
            }
        }

        MonotoneVertex un = vertices.get(vertices.size() - 1);
        if (stack.size() != 0) stack.remove(0);
        if (stack.size() != 0) stack.remove(stack.size() - 1);
        for (MonotoneVertex mv : stack) {
            addEdge(un.data, mv.data);
        }
    }

    public List<MonotonePolygon> getMonotonePolygons() {
        List<MonotonePolygon> listPolygons = new ArrayList<MonotonePolygon>();

        for (int i = 0; i < faces.size(); ++i) {
            DFace currFace = faces.get(i);
            if (currFace.outerEdge == null) continue;
            
            DHalfEdge currEdge = currFace.outerEdge;
            List<MonotoneVertex> monotoneVerts = new ArrayList<MonotoneVertex>();

            MonotoneVertex oldMV = null;
            MonotoneVertex top = null;
            do {
                MonotoneVertex mv = new MonotoneVertex();
                mv.data = currEdge.origin;
                mv.prev = oldMV;

                if (oldMV != null) {
                    oldMV.next = mv;
                }

                if (top == null) {
                    top = mv;
                } else if (top.data.coord.y == mv.data.coord.y) {
                    if (mv.data.coord.x < top.data.coord.x) {
                        top = mv;
                    }
                } else if (mv.data.coord.y > top.data.coord.y) {
                    top = mv;
                }

                monotoneVerts.add(mv);
                oldMV = mv;
                currEdge = currEdge.next;
            } while (currEdge != currFace.outerEdge);
            MonotoneVertex first = monotoneVerts.get(0);
            first.prev = oldMV;
            oldMV.next = first;


            List<MonotoneVertex> sortedMonotoneVerts = new ArrayList<MonotoneVertex>(monotoneVerts.size());
            
            top.chainType = MonotoneChainType.LEFT;
            sortedMonotoneVerts.add(top);
            
            MonotoneVertex currLeft = top.next;
            MonotoneVertex currRight = top.prev;
            int j = 1;
            while (j++ < monotoneVerts.size()) {
                PVector l = currLeft.data.coord;
                PVector r = currRight.data.coord;
                
                if (l.y >= r.y) {
                    sortedMonotoneVerts.add(currLeft);
                    currLeft.chainType = MonotoneChainType.LEFT;
                    currLeft = currLeft.next;
                } else {
                    sortedMonotoneVerts.add(currRight);
                    currRight.chainType = MonotoneChainType.RIGHT;
                    currRight = currRight.prev;
                }
            }
            sortedMonotoneVerts.get(sortedMonotoneVerts.size() - 1).chainType = MonotoneChainType.RIGHT;
            
            MonotonePolygon polygon = new MonotonePolygon(sortedMonotoneVerts);
            listPolygons.add(polygon);
        }

        return listPolygons;
    }

    public void draw() {
        for (DFace f : faces) {
            f.draw();
        }
        for (DHalfEdge e : edges) {
            e.draw();
        }
        for (DVertex v : vertices) {
            v.draw();
        }
    }

    public void drawEdges() {
        for (DHalfEdge e : edges) {
            e.draw();
        }
    }

}

int DID_COUNT = 0;
public class DVertex {
    public PVector coord;
    public DHalfEdge incidentEdge;
    public int id;

    public DVertex() {
        id = DID_COUNT++;
    }

    @Override
    public String toString() {
        return "[" + coord.x + " " + coord.y + "] : " + id;
    }
    
    public void draw() {
        stroke(BLACK);
        strokeWeight(1);
        fill(YELLOW);
        ellipse(coord.x, coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);

        // textSize(20);
        // textAlign(RIGHT, TOP);
        // fill(BLACK);
        // text(id, coord.x, coord.y);
    }
}

int DFACEID_COUNT = 0;
public class DFace {
    public DHalfEdge outerEdge;
    public List<DHalfEdge> innerEdgeList;
    public int id;

    public DFace() {
        id = DFACEID_COUNT++;
    }

    public void draw() {
        if (outerEdge == null) return;
        Set<DHalfEdge> set = new HashSet<DHalfEdge>();
        DHalfEdge curr = outerEdge;
        PVector com = new PVector();

        beginShape();
        fill(MAGENTA);
        while (!set.contains(curr)) {
            com.x += curr.origin.coord.x;
            com.y += curr.origin.coord.y;
            vertex(curr.origin.coord.x, curr.origin.coord.y);
            set.add(curr);
            curr = curr.next;
        }
        endShape(CLOSE);

        com = com.div(set.size());

        // textSize(20);
        // textAlign(RIGHT, TOP);
        // fill(BLACK);
        // text(id, com.x, com.y);
    }

    @Override
    public String toString() {
        return "FACE: " + id + " -- Outer Edge: " + outerEdge;
    }
}

int DEDGEID_COUNT = 0;
public class DHalfEdge {
    public DVertex origin;
    public DHalfEdge twin;
    public DFace incidentFace;
    public DHalfEdge next;
    public DHalfEdge prev;
    public int id;

    public DHalfEdge() {
        id = DEDGEID_COUNT++;
    }

    public void draw() {
        DVertex nextVertex = next.origin;
        stroke(PURPLE);
        strokeWeight(4);
        line(origin.coord.x, origin.coord.y, nextVertex.coord.x, nextVertex.coord.y);
    }

    @Override
    public String toString() {
        return "Edge: " + id + " -- " + "[" + origin + ", " + next.origin + "]";
    }

    // public void draw() {
    //     origin.draw();
    //     DVertex nextVertex = next.origin;
    //     DVertex prevVertex = prev.origin;

    //     // o -> n
    //     stroke(PURPLE);
    //     strokeWeight(4);
    //     line(origin.coord.x, origin.coord.y, nextVertex.coord.x, nextVertex.coord.y);


    //     stroke(BLACK);
    //     fill(YELLOW);
    //     ellipse(nextVertex.coord.x, nextVertex.coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);

    //     stroke(BLACK);
    //     fill(GREEN);
    //     ellipse(prevVertex.coord.x, prevVertex.coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);

    //     // o -> p
    //     stroke(RED);
    //     strokeWeight(2);
    //     line(origin.coord.x, origin.coord.y, prevVertex.coord.x, prevVertex.coord.y);


    //     DVertex twinOriginVertex = twin.origin;
    //     DVertex twinNextVertex = twin.next.origin;
    //     // twin
    //     stroke(BLUE);
    //     strokeWeight(2);
    //     line(twinOriginVertex.coord.x, twinOriginVertex.coord.y, twinNextVertex.coord.x, twinNextVertex.coord.y);
    // }
}