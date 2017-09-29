import java.util.*;

public class DoublyEdgeList {
    List<DVertex> vertices;
    List<DHalfEdge> edges;
    List<DFace> faces;
    List<DFace> holes;
    DFace outerFace;


    public DoublyEdgeList() {
        vertices = new ArrayList<DVertex>();
        edges = new ArrayList<DHalfEdge>();
        faces = new ArrayList<DFace>();
        holes = new ArrayList<DFace>();
    }

    public void initialize(List<List<PVector>> init) {
        println("Create component");
        // create main component
        DFace mainInnerFace = new DFace();
        DFace mainOuterFace = new DFace();
        outerFace = mainOuterFace;
        // Assumes index 0 is part of the outer polygon
        createComponent(init.get(0), mainInnerFace, mainOuterFace);
        
        // create holes
        for (int i = 1; i < init.size(); ++i) {
            createComponent(init.get(i), null, mainInnerFace);
        }

        println("   HOLES: ", holes);
    }

    public DFace createComponent(List<PVector> verts, DFace inner, DFace outer) {
        DFace innerFace = inner;
        DFace outerFace = outer;
        if (innerFace == null) innerFace = new DFace();
        if (outerFace == null) outerFace = new DFace();
        if (!faces.contains(innerFace)) faces.add(innerFace);
        if (!faces.contains(outerFace)) faces.add(outerFace);
        DHalfEdge prevIncEdge = null;
        DHalfEdge prevTwinEdge = null;

        int firstIndex = vertices.size();   // Keep location of first vertex for late

        for (int i = 0; i < verts.size(); ++i) {
            // Create vertex with edges
            DVertex v = new DVertex();
            DHalfEdge incEdge = new DHalfEdge();
            DHalfEdge twinEdge = new DHalfEdge();

            vertices.add(v);
            edges.add(incEdge);
            edges.add(twinEdge);

            // initialize vertex;
            v.coord = verts.get(i);
            v.incidentEdge = incEdge;

            // initialize incident Edge
            incEdge.origin = v;
            incEdge.twin = twinEdge;
            incEdge.incidentFace = innerFace;
            incEdge.next = null;
            incEdge.prev = prevIncEdge;

            // initialize twin edge
            twinEdge.origin = null;
            twinEdge.twin = incEdge;
            twinEdge.incidentFace = outerFace;
            twinEdge.next = prevTwinEdge;
            twinEdge.prev = null;

            // set the previous incEdge's next
            if (prevIncEdge != null) {
                prevIncEdge.next = incEdge;
            }

            // set the previous twinEdge's origin and prev
            if (prevTwinEdge != null) {
                prevTwinEdge.origin = v;
                prevTwinEdge.prev = twinEdge;
            }
            
            prevIncEdge = incEdge;
            prevTwinEdge = twinEdge;
        }

        DVertex firstVertex = vertices.get(firstIndex);
        DHalfEdge firstIEdge = firstVertex.incidentEdge;
        DHalfEdge firstTEdge = firstVertex.incidentEdge.twin;

        firstIEdge.prev = prevIncEdge;
        firstTEdge.next = prevTwinEdge;

        prevIncEdge.next = firstIEdge;
        prevTwinEdge.origin = firstVertex;
        prevTwinEdge.prev = firstTEdge;

        innerFace.outerEdge = firstIEdge;

        // if inner is null, then this is a hole.
        // we want to set all the vertices incident edges to the outer edges.
        if (inner == null) {
            println("THIS IS A HOLE");
            DHalfEdge curr = innerFace.outerEdge;
            Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
            while(!visited.contains(curr)) {
                curr.origin.incidentEdge = curr.prev.twin;

                visited.add(curr);
                curr = curr.next;
            }
            innerFace.isHole = true;
            holes.add(innerFace);
        }
        return innerFace;
    }

    public void addEdge(int s, int t) {
        addEdge(vertices.get(s), vertices.get(t));
    }


    /*
        How we handle holes:
        Even when a hole is attached to the outer face, we still keep the hole for record and use it
        for triangulate monotone pieces by skipping hole monotone pieces.
        When we create a new face and have to update the holes outer edges with the new face, if the
        hole is already connected to the face, it is no longer inside the hole.
    */
    public void addEdge(DVertex l, DVertex r) {
        println("addEdge: " + l + " --- " + r);
        DHalfEdge goLeft = new DHalfEdge();
        DHalfEdge goRight = new DHalfEdge();

        DFace commonFace = findFace(l, r); 
        DHalfEdge lEdge = findEdges(l, commonFace, r);
        DHalfEdge rEdge = findEdges(r, commonFace, l);
        println("   ", commonFace);
        println("   ", lEdge, rEdge);
        
        DFace newFace = null;
        // We are connecting to a hole island.  We do not create a new face
        // DFace lHoleFace = null;
        // DFace rHoleFace = null;
        if (!findVertexFromEdge(lEdge, r)) {
            println("CANNOT FIND VERTEX FROM EDGE");
            newFace = commonFace;
            // // Find the hole
            // Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
            // DHalfEdge lCurrEdge = l.incidentEdge;
            // DHalfEdge rCurrEdge = r.incidentEdge;
            // while (!visited.contains(lCurrEdge) || !visited.contains(rCurrEdge)) {
            //     DFace lCurrFace = lCurrEdge.incidentFace;
            //     DFace rCurrFace = rCurrEdge.incidentFace;
                
            //     if (holes.contains(lCurrFace)) lHoleFace = lCurrFace;
            //     if (holes.contains(rCurrFace)) rHoleFace = rCurrFace;
            //     visited.add(lCurrEdge);
            //     visited.add(rCurrEdge);
            //     lCurrEdge = lCurrEdge.twin.next;
            //     rCurrEdge = rCurrEdge.twin.next;
            // }
        } else {
            newFace = new DFace();
        }

        goLeft.origin  = r;
        goLeft.twin = goRight;
        goLeft.next = lEdge;
        goLeft.prev = rEdge.prev;
        goLeft.incidentFace = newFace;

        goRight.origin = l;
        goRight.twin = goLeft;
        goRight.next = rEdge;
        goRight.prev = lEdge.prev;
        goRight.incidentFace = commonFace;

        lEdge.prev.next = goRight;
        rEdge.prev.next = goLeft;
        lEdge.prev = goLeft;
        rEdge.prev = goRight;

        // change faces.  goLeft keeps new face, goRight gets old face
        
        commonFace.outerEdge = goRight;
        newFace.outerEdge = goLeft;
        
        println(newFace, commonFace);
        // This is when splitting a closed loop of points.  We divide the shape
        // we have a new face, we want to set all edges.incidentFace = newFace
        if (newFace != commonFace) {
            println("    new face doesn't equal common face");
            Set<DHalfEdge> newFaceVisited = new HashSet<DHalfEdge>();
            newFace.outerEdge = goLeft;
            DHalfEdge curr = goLeft;
            while (!newFaceVisited.contains(curr)) {
                println("     ", curr.origin);
                curr.incidentFace = newFace;
                newFaceVisited.add(curr);
                curr = curr.next;
            }
            
            // Go through all the holes and see which ones are inside this new face.
            println("      Checking holes", holes);
            for (DFace hole : holes) {
                println("       ", hole);
                if (hole.isHole && isHoleInFace(hole, newFace)) {
                    println("         INSIDE HOLE", hole, newFace);
                    Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
                    DHalfEdge currEdge = hole.outerEdge.twin;
                    while (!visited.contains(currEdge)) {
                        currEdge.incidentFace = newFace;
                        currEdge.twin.incidentFace = outerFace;
                        
                        visited.add(currEdge);
                        currEdge = currEdge.next;
                    }
                }
            }
            
            
            faces.add(newFace);
        }
        
        // if (lHoleFace != null && rHoleFace != null) {
        //     println("BOTH ARE HOLES");
        // } else if (lHoleFace != null) {
        //     println("LEFT HOLE REMOVED", l);
        //     lHoleFace.isHole = false;
        // } else if (rHoleFace != null) {
        //     println("RIGHT HOLE REMOVED", r);
        //     rHoleFace.isHole = false;
        // }
        // When one of the 
        
        edges.add(goLeft);
        edges.add(goRight);
    }

    public boolean isHoleInFace(DFace hole, DFace face) {
        Set<DVertex> holeVerts = new HashSet<DVertex>();
        Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
        DHalfEdge currEdge = hole.outerEdge;
        while (!visited.contains(currEdge)) {
            holeVerts.add(currEdge.origin);
            visited.add(currEdge);
            currEdge = currEdge.next;
        }

        visited = new HashSet<DHalfEdge>();
        currEdge = face.outerEdge;

        // Check to see if hole is already attached to face, then it is not.
        while (!visited.contains(currEdge)) {
            if (holeVerts.contains(currEdge.origin)) return false;
            visited.add(currEdge);
            currEdge = currEdge.next;
        }

        DVertex p = hole.outerEdge.origin;
        return isPointInFace(p.coord, face);
    }
    

    public boolean isPointInFace(PVector p, DFace face) {
        return numIntersections(p, face) % 2 == 1;
    }

    
    public int numIntersections(PVector P, DFace face) {
        // println("CALLING numIntersections ON", P, face);
        Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
        DHalfEdge curr = face.outerEdge;
        
        PVector V = new PVector(10000,1);

        int intersections = 0;
        while (!visited.contains(curr)) {
            // println(curr);
            PVector currPV = curr.origin.coord;
            PVector nextPV = curr.next.origin.coord;
            
            if (vecIntersects(P, V, currPV, nextPV)) {
                intersections++; 
            }
            
            visited.add(curr);
            curr = curr.next;
        }
        // println("   ", intersections);
        return intersections;
    }


    // You can find multiple edges with the same face for a vertex
    // We're adding an edge VOTHER, so find where other cuts v.
    public DHalfEdge findEdges(DVertex v, DFace f, DVertex other) {
        println("FIND EDGES", v, f, other);
        List<DHalfEdge> candidates = new ArrayList<DHalfEdge>();
        Set<DHalfEdge> visited = new HashSet<DHalfEdge>();

        DHalfEdge curr = v.incidentEdge;
        while (!visited.contains(curr)) {
            if (curr.incidentFace == f) {
                println("   FOUND A EDGE", curr);
                candidates.add(curr);
            }
            visited.add(curr);
            curr = curr.twin.next;
        }
        
        println("   Found candidates", candidates);
        if (candidates.size() == 1) {
            return candidates.get(0);
        } else {
            PVector vOTHER = PVector.sub(other.coord, v.coord);
            DHalfEdge ret = candidates.get(0);
            PVector currEdge = PVector.sub(ret.next.origin.coord, ret.origin.coord);
            float angle = clockwiseAngle(vOTHER, currEdge);
            for (DHalfEdge ce : candidates) {
                currEdge = PVector.sub(ce.next.origin.coord, ce.origin.coord);
                float tempAngle = clockwiseAngle(vOTHER, currEdge);
                println("   ", ce, tempAngle);
                if (tempAngle < angle) {
                    ret = ce;
                    angle = tempAngle;
                }
            }

            return ret;
        }
    }

    public DFace findFace(DVertex s, DVertex t) {
        PVector mid = PVector.add(s.coord, t.coord).div(2);
        for (DFace face : faces) {
            if (face.outerEdge == null) continue;
            if (isPointInFace(mid, face)) return face;
        }

        println("NOT FOUND");
        return null;
    }

    // public DFace findFace(DVertex s, DVertex t) {
    //     println("      FIND FACE");
    //     // if (s.incidentEdge.incidentFace == t.incidentEdge.incidentFace) return s.incidentEdge.incidentFace;

    //     DHalfEdge currSEdge = s.incidentEdge;
    //     Set<DHalfEdge> sEdges = new HashSet<DHalfEdge>();
    //     Set<DFace> sFaces = new HashSet<DFace>();
    //     while (!sEdges.contains(currSEdge)) {
    //         sEdges.add(currSEdge);
    //         sFaces.add(currSEdge.incidentFace);
    //         currSEdge = currSEdge.twin.next;
    //     }
    //     println("       ", sEdges);
    //     println("       ", sFaces);

    //     DHalfEdge currTEdge = t.incidentEdge;
    //     Set<DHalfEdge> tEdges = new HashSet<DHalfEdge>();
    //     while (!tEdges.contains(currTEdge)) {
    //         println("           ",  currTEdge.incidentFace);
    //         if (currTEdge.incidentFace.outerEdge != null && sFaces.contains(currTEdge.incidentFace)) {
    //             println("           FACE MATCH");
    //             PVector midPoint = PVector.add(s.coord, t.coord).div(2);
    //             if (isPointInFace(midPoint, currTEdge.incidentFace)) {
    //                 return currTEdge.incidentFace;
    //             }
    //         } 
    //         tEdges.add(currTEdge);
    //         currTEdge = currTEdge.twin.next;
    //     }

    //     println("NO FACE FOUND");
    //     return s.incidentEdge.incidentFace;
    // }

    public boolean findVertexFromEdge(DHalfEdge e, DVertex t) {
        println("FIND VERTEX FROM EDGE");
        List<DHalfEdge> list = new ArrayList<DHalfEdge>();
        DHalfEdge curr = e;

        while (!list.contains(curr)) {
            println("    ", curr.origin);
            if (curr.origin == t) return true;

            list.add(curr);
            curr = curr.next;
        }
        return false;
    }


// MONOTONE TRIANGULATION ==========================================================================================
    List<MonotonePolygon> polygons;
    public void triangulateMonotonePolygons() {
        println("BEGIN TRIANGULATEMONOTONEPOLYGONS");
        println("   Faces:", faces);
        polygons = getMonotonePolygons() ;
        if (!DEBUG) {
            for (MonotonePolygon p : polygons) {
                triangulateMonotonePolygon(p);
            }
        }
    }

    MonotonePolygon currMPolygon = null;
    public void triangulateMonotonePolygon() {
        if (polygons != null && !polygons.isEmpty()) {
            if (currMPolygon == null) {
                currMPolygon = polygons.remove(0);
                triangulateMonotonePolygon(currMPolygon);
            } else {
                triangulateDebug();
            }
        }
    }

    // public void triangulateMonotonePolygon(MonotonePolygon p) {
    //     println("TRIAGULATING: " + p);
    //     List<MonotoneVertex> stack = new ArrayList<MonotoneVertex>();
    //     List<MonotoneVertex> vertices = p.vertices;

    //     stack.add(vertices.get(0));
    //     stack.add(vertices.get(1));
        
    //     if (!DEBUG) {
    //         for (int j = 2; j < vertices.size() - 1; ++j) {
    //             println("   Triangulating", j + " " + stack);
    //             MonotoneVertex uj = vertices.get(j);
    //             MonotoneVertex stackTop = stack.get(stack.size() - 1);
    //             if (uj.chainType != stackTop.chainType) {
    //                 println("    Chains don't match");
    //                 for (int k = stack.size() - 1; k > 0; --k) {
    //                     addEdge(uj.data, stack.get(k).data);
    //                 }
    //                 stack.clear();
    //                 stack.add(vertices.get(j-1));
    //                 stack.add(uj);
    //             } else {
    //                 println("    Chains ARE GOOD");
    //                 MonotoneVertex lastPop = stack.remove(stack.size() - 1);
    //                 boolean keepPopping = true;
    //                 while (keepPopping && !stack.isEmpty()) {
    //                     MonotoneVertex currPop = stack.remove(stack.size() - 1);
    //                     PVector ujLast   = PVector.sub(lastPop.data.coord, uj.data.coord);
    //                     PVector lastCurr = PVector.sub(currPop.data.coord, lastPop.data.coord);
    //                     if (uj.chainType == MonotoneChainType.RIGHT && ujLast.cross(lastCurr).z > 0 ||
    //                         uj.chainType == MonotoneChainType.LEFT  && ujLast.cross(lastCurr).z < 0) {
    //                         addEdge(uj.data, currPop.data);
    //                         lastPop = currPop;
    //                     } else {
    //                         stack.add(currPop);     // don't actually pop off
    //                         keepPopping = false;
    //                     }
    //                 }
    //                 stack.add(lastPop);
    //                 stack.add(uj);
    //             }
    //         }

    //         MonotoneVertex un = vertices.get(vertices.size() - 1);
    //         if (stack.size() != 0) stack.remove(0);
    //         if (stack.size() != 0) stack.remove(stack.size() - 1);
    //         for (MonotoneVertex mv : stack) {
    //             addEdge(un.data, mv.data);
    //         }
    //     }
        
    // }



    List<MonotoneVertex> stack;
    List<MonotoneVertex> mVertices;
    int j = 0;
    public void triangulateMonotonePolygon(MonotonePolygon p) {
        println("TRIAGULATING: " + p);
        stack = new ArrayList<MonotoneVertex>();
        mVertices = p.vertices;
        j = 2;

        stack.add(mVertices.get(0));
        stack.add(mVertices.get(1));

        if (!DEBUG) {
            for (int j = 2; j < mVertices.size() - 1; ++j) {
                println("   Triangulating", j + " " + stack);
                MonotoneVertex uj = mVertices.get(j);
                MonotoneVertex stackTop = stack.get(stack.size() - 1);
                if (uj.chainType != stackTop.chainType) {
                    println("    Chains don't match");
                    for (int k = stack.size() - 1; k > 0; --k) {
                        addEdge(uj.data, stack.get(k).data);
                    }
                    stack.clear();
                    stack.add(mVertices.get(j-1));
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

            MonotoneVertex un = mVertices.get(mVertices.size() - 1);
            if (stack.size() != 0) stack.remove(0);
            if (stack.size() != 0) stack.remove(stack.size() - 1);
            for (MonotoneVertex mv : stack) {
                addEdge(un.data, mv.data);
            }
        }
    }


    public void triangulateDebug() {
        if (j < mVertices.size() - 1) {
            println("   Triangulating", j + " " + stack);
                MonotoneVertex uj = mVertices.get(j);
                MonotoneVertex stackTop = stack.get(stack.size() - 1);
                if (uj.chainType != stackTop.chainType) {
                    println("    Chains don't match");
                    for (int k = stack.size() - 1; k > 0; --k) {
                        addEdge(uj.data, stack.get(k).data);
                    }
                    stack.clear();
                    stack.add(mVertices.get(j-1));
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
            j++;
        } else if (j == mVertices.size() - 1) {
            MonotoneVertex un = mVertices.get(mVertices.size() - 1);
            if (stack.size() != 0) stack.remove(0);
            if (stack.size() != 0) stack.remove(stack.size() - 1);
            for (MonotoneVertex mv : stack) {
                addEdge(un.data, mv.data);
            }
            j++;
            currMPolygon = null;
        }
    }



    public List<MonotonePolygon> getMonotonePolygons() {
        List<MonotonePolygon> listPolygons = new ArrayList<MonotonePolygon>();

        for (int i = 0; i < faces.size(); ++i) {
            DFace currFace = faces.get(i);
            if (currFace.outerEdge == null) continue;
            if (currFace.isHole) continue;
            
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
        for (DFace f : faces)      f.draw();
        for (DFace f : holes)      f.draw(WHITE);
        for (DHalfEdge e : edges)  e.draw();
        for (DVertex v : vertices) v.draw();
    }

    public void drawArrows() {
        // for (DHalfEdge e : edges)  e.drawArrow();
        for (DFace f : faces)      f.drawArrow();
    }

    public void drawEdges() {
        for (DHalfEdge e : edges)  e.draw();
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
        if (coord == null || incidentEdge == null) {
            stroke(RED);
        }
        ellipse(coord.x, coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);

        textSize(20);
        textAlign(RIGHT, TOP);
        fill(BLACK);
        text(id, coord.x, coord.y);
    }
}

int DFACEID_COUNT = 0;
public class DFace {
    public DHalfEdge outerEdge;
    //public List<DHalfEdge> innerEdgeList;
    public int id;
    public boolean isHole;
    public color c;

    public DFace() {
        id = DFACEID_COUNT++;
        c = color(random(255), random(255), random(255));
    }

    public void draw() {
        if (isHole) draw(WHITE);
        else draw(GRAY);
    }

    public void draw(color c) {
        if (outerEdge == null) return;
        Set<DHalfEdge> set = new HashSet<DHalfEdge>();
        DHalfEdge curr = outerEdge;
        PVector com = new PVector();

        beginShape();
        fill(c);
        while (!set.contains(curr)) {
            com.x += curr.origin.coord.x;
            com.y += curr.origin.coord.y;
            vertex(curr.origin.coord.x, curr.origin.coord.y);
            set.add(curr);
            curr = curr.next;
        }
        endShape(CLOSE);

        com = com.div(set.size());
    }
    
    public void drawArrow() {
        if (outerEdge == null) return;
        Set<DHalfEdge> visited = new HashSet<DHalfEdge>();
        DHalfEdge curr = outerEdge;
        while (!visited.contains(curr)) {
          curr.drawArrow(curr.incidentFace.c);
          visited.add(curr);
          curr = curr.next;
        }
        PVector outRot = PVector.sub(outerEdge.next.origin.coord, outerEdge.origin.coord);
        outRot.div(2);
        outRot.rotate(HALF_PI/10);
        stroke(c);
        fill(c);
        strokeWeight(4); 
        line(outerEdge.origin.coord.x, outerEdge.origin.coord.y, outerEdge.origin.coord.x + outRot.x, outerEdge.origin.coord.y + outRot.y);
        text(id, outerEdge.origin.coord.x + outRot.x, outerEdge.origin.coord.y + outRot.y);
        ellipse(outerEdge.origin.coord.x, outerEdge.origin.coord.y, 3, 3); 
    }

    @Override
    public boolean equals(Object o) {
        if (o == null) return false;
        if (!(o instanceof DFace)) return false;
        return this.id == ((DFace) o).id;
    }


    @Override
    public String toString() {
        //return "FACE: " + id + " -- Outer Edge: " + outerEdge + " -- Inner Edges: " + innerEdgeList + "\n";
        return "FACE: " + id + " -- Outer Edge: " + outerEdge + "\n";
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
        if (origin == null || twin == null || incidentFace == null || next == null || prev == null) {
            stroke(RED);
        }
        strokeWeight(2);
        line(origin.coord.x, origin.coord.y, nextVertex.coord.x, nextVertex.coord.y);

        // DVertex u = origin;
        // DVertex v = nextVertex;
        // fill(YELLOW);
        // PVector top = new PVector((u.coord.x + v.coord.x) / 2.0, (u.coord.y + v.coord.y) / 2.0);
        // PVector unitUV = PVector.sub(v.coord, u.coord).setMag(20);
        // PVector sideLeft  = PVector.add(top, unitUV.copy().rotate(PI*5/6));
        // PVector sideRight = PVector.add(top, unitUV.copy().rotate(-PI*5/6));

        //triangle(top.x, top.y, sideLeft.x, sideLeft.y, sideRight.x, sideRight.y);
    }

    public void drawArrow() {
        drawArrow(GREEN);
    }

    public void drawArrow(color c) {
        PVector outRot = PVector.sub(next.origin.coord, origin.coord);
        outRot.div(4);
        outRot.rotate(HALF_PI/9);
        stroke(c);
        fill(c);    
        strokeWeight(3); 
        line(origin.coord.x, origin.coord.y, origin.coord.x + outRot.x, origin.coord.y + outRot.y);
        // text(id, origin.coord.x + outRot.x, origin.coord.y + outRot.y);
        ellipse(origin.coord.x, origin.coord.y, 4, 4); 
    }

    @Override
    public String toString() {
        return "Edge: " + id + " -- " + "[" + origin.id + ", " + next.origin.id + "] -- Face ID: " + next.incidentFace.id;
    }
}