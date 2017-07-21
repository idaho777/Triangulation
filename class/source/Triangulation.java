import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 
import java.util.*; 
import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Triangulation extends PApplet {


DoublyEdgeList dEList;

DisplayController displayController;
EditController    editController;
FileController    fileController;
PolyController    polyController;
Triangulator      triangulator;

public void settings() {
    size(1024,768,P2D);
}

public void setup() {
    initControllers();

    ID_COUNT = 0;
    DID_COUNT = 0;
    DFACEID_COUNT = 0;
    DEDGEID_COUNT = 0;
}

public void initControllers() {
    displayController = new DisplayController();
    editController = new EditController();
    fileController = new FileController();
    polyController = new PolyController();
    triangulator = new Triangulator();
}


public void draw() {
    background(WHITE);
    noStroke();
    noFill();

    displayController.displayText();

    scale(1, -1);
    translate(0, -height);
    
    displayController.display();
}
/**
 * Handles all rendering content
 * This class should reflect the geometric positioning of the polygon
 *
 */
int DRAW_STATES = 3;
public class DisplayController {

    int drawState = 0;

    public void nextDrawState() {
        drawState = (drawState + 1) % DRAW_STATES;
    }

    public void prevDrawState() {
        drawState = (drawState + DRAW_STATES - 1) % DRAW_STATES;
    }

    public void handleKey() {
        if (key == ']') nextDrawState();
        if (key == '[') prevDrawState();
    }

    /**
     * Main rendering function
     */
    public void display() {
        polyController.display();
        triangulator.display();
    }

    public void displayText() {
        displaySettings();
        fileController.displayText();
    }

    public void displaySettings() {
        String settings = String.format("Current Draw State: %d", drawState);
        textSize(14);
        textAlign(RIGHT, TOP);
        fill(BLACK);
        text(settings, width - 10, 10);
    }

}


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

public class EditController {
  
    public void display() {
        
    }
}




char currentKey;
public void keyPressed() {
    currentKey = key;
    if (currentKey == '-') setup();
    displayController.handleKey();
    fileController.handleKey();
    polyController.handleKey();
    triangulator.handleKey();
}

public void mouseWheel(MouseEvent event) {

}

public void mousePressed() {
    polyController.handleMousePressed();
}

public void mouseDragged() {
    polyController.handleMouseDragged();
}

public void mouseReleased() {
    polyController.handleMouseReleased();
}


public int mouseX() { return mouseX; }
public int mouseY() { return height - mouseY; }

public class FileController {

    public FileController() {
    }

    public void read() {
        selectInput("Select an edit file to read from:", "readEditSelected");
    }

    public void write() {
        selectOutput("Select an edit file to write to:", "writeEditSelected");
    }

    public void handleKey() {
        if (key == '<') read();
        if (key == '>') write();
        if (key == '-') currFile = null;
        readDefaults();
    }

    public void readDefaults() {
        if (key == '1') readEdit(new File( sketchPath() + "/examples/" + "1.joonho" ));
        if (key == '2') readEdit(new File( sketchPath() + "/examples/" + "2.joonho" ));
        if (key == '3') readEdit(new File( sketchPath() + "/examples/" + "3.joonho" ));
        if (key == '4') readEdit(new File( sketchPath() + "/examples/" + "4.joonho" ));
        if (key == '5') readEdit(new File( sketchPath() + "/examples/" + "5.joonho" ));
        if (key == '6') readEdit(new File( sketchPath() + "/examples/" + "6.joonho" ));
        if (key == '7') readEdit(new File( sketchPath() + "/examples/" + "7.joonho" ));
        if (key == '8') readEdit(new File( sketchPath() + "/examples/" + "8.joonho" ));
        if (key == '9') readEdit(new File( sketchPath() + "/examples/" + "9.joonho" ));
        if (key == '0') readEdit(new File( sketchPath() + "/examples/" + "0.joonho" ));
    }


    public void displayText() {
        displaySettings();
    }

    public void displaySettings() {
        String settings = String.format("Current File: %s", currFile);
        textSize(14);
        textAlign(LEFT, TOP);
        fill(BLACK);
        text(settings, 10, 10);
    }

}


String currFile = null;
public void readEditSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        return;
    }

    readEdit(selection);
}

public void writeEditSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        return;
    }
    writeEdit(selection);
}


// READ JOONHO FILE
public void readEdit(File selection) {
    println("Writing joonho");
    BufferedReader reader = createReader(selection);
    try {
        String open = reader.readLine();
        List<Vertex> v = readVertex(reader);
        List<Edge>   e = readEdge(reader, v);

        setup();
        polyController.vertices = v;
        polyController.edges    = e;
    } catch (IOException ee) {
        ee.printStackTrace();
    }

    currFile = selection.getName();
}

public List<Vertex> readVertex(BufferedReader reader) throws IOException {
    String line = reader.readLine();
    List<Vertex> list = new ArrayList<Vertex>();

    line = reader.readLine();
    while (!line.equals("close vertex list")) {
        line = line.replaceAll("\\s","");
        float[] c = PApplet.parseFloat(split(line, ','));
        PVector v = new PVector(c[0], c[1]);
        list.add(new Vertex(v.x, v.y));
        line = reader.readLine();
    }

    return list;
}

public List<Edge> readEdge(BufferedReader reader, List<Vertex> vertices) throws IOException {
    String line = reader.readLine();
    List<Edge> list = new ArrayList<Edge>();

    line = reader.readLine();
    while (!line.equals("close edge list")) {
        line = line.replaceAll("\\s","");
        int[] c = PApplet.parseInt(split(line, ','));
        list.add(new Edge(
                vertices.get(c[0]),
                vertices.get(c[1])));
        line = reader.readLine();
    }

    return list;
}


// WRITE JOONHO FILE
public void writeEdit(File selection) {
    println("Exporting joonho");
    PrintWriter output = createWriter(selection + ".joonho");
    List<Vertex> v = polyController.vertices;
    List<Edge> e  = polyController.edges;
    output.write(writeEditText(selection, v, e));
    output.flush();
    output.close();

    currFile = selection.getName();
}

public String writeEditText(File selection, List<Vertex> vertices, List<Edge> edges) {
    StringBuilder builder = new StringBuilder();
    
    builder.append("open joonho\n");
    builder.append("open vertex list\n");
        HashMap<Vertex, Integer> idIndexMap = new HashMap<Vertex, Integer>();
        int count = 0;
        for (Vertex v : vertices) {
            builder.append(v.coord.x + ", " + v.coord.y + "\n");
            idIndexMap.put(v, count++);
        }

    builder.append("close vertex list\n");
    builder.append("open edge list\n");
        for (Edge e : edges) {
            builder.append(idIndexMap.get(e.u) + ", " +
                           idIndexMap.get(e.v) + "\n");
        }
    builder.append("close edge list\n");
    builder.append("close joonho\n");

    return builder.toString();
}
public class MonotonePolygon {

    List<MonotoneVertex> vertices;
    
    public MonotonePolygon(List<MonotoneVertex> vertices) {
        this.vertices = vertices;
    }

    public void draw() {
        for (MonotoneVertex v : vertices) {
            v.drawEdge();
            v.draw();
        }
    }

    @Override
    public String toString() {
        return vertices.toString() + "\n";
    }
}

public class MonotoneVertex {
    DVertex data;
    MonotoneVertex next;
    MonotoneVertex prev;
    MonotoneChainType chainType;

    public boolean isAdjacent(MonotoneVertex vertex) {
        return vertex == this.prev || vertex == this.next;
    }

    public void draw() {
        stroke(BLACK);
        if (chainType == MonotoneChainType.LEFT) {
            fill(YELLOW);
        } else if (chainType == MonotoneChainType.RIGHT) {
            fill(GREEN);
        } else {
            fill(RED);
        }
        ellipse(data.coord.x, data.coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);
    }

    public void drawEdge() {
        DVertex nextVertex = next.data;
        stroke(GREEN);
        strokeWeight(4);
        line(data.coord.x, data.coord.y, nextVertex.coord.x, nextVertex.coord.y);
    }

    @Override
    public String toString() {
        return "[" + data.toString() + ": " + chainType + "]";
    }
}

public enum MonotoneChainType {
    LEFT, RIGHT,
}


public class PolyController {
    public List<Vertex> vertices;
    public List<Edge> edges;


    public PolyController() {
        vertices = new ArrayList<Vertex>();
        edges = new ArrayList<Edge>();
    }

    Vertex lastVertex = null;
    public void addVertex(float x, float y) {
        int clickedVertexIndex = selectVertexIndex();
        if (clickedVertexIndex == -1 && lastVertex == null) {           // adding first vertex
            lastVertex = new Vertex(x, y);
            vertices.add(lastVertex);
        } else if (clickedVertexIndex != -1 && lastVertex == null) {    // Starting from existing vertex
            lastVertex = vertices.get(clickedVertexIndex);
        } else if (clickedVertexIndex == -1 && lastVertex != null) {    // adding new connected vertex
            Vertex newVertex = new Vertex(x, y);
            vertices.add(newVertex);
            addEdge(vertices.indexOf(lastVertex), vertices.size() - 1);
            lastVertex = newVertex;
        } else {                                                        // Closing a loop
            addEdge(vertices.indexOf(lastVertex), clickedVertexIndex);
            lastVertex = null;
        }
    }

    public void removeVertex() {
        int toRemoveIndex = selectVertexIndex();
        if (toRemoveIndex >= 0) {
            // Remove edges
            Vertex toRemoveVertex = vertices.get(toRemoveIndex);
            for (int i = edges.size() - 1; i >= 0; --i) {
                if (edges.get(i).contains(toRemoveVertex)) {
                    edges.remove(i);
                }
            }
            
            // Remove Vertex
            vertices.remove(toRemoveIndex);
        }

        lastVertex = null;
    }

    Vertex toTranslate;
    public void translateVertex() {
        if (toTranslate == null) {
            toTranslate = selectVertex();
        }
        if (toTranslate != null) {
            toTranslate.coord.x = mouseX();
            toTranslate.coord.y = mouseY();
        }
    }

    public int selectVertexIndex() {
        int vertexIndex = -1;
        float minDist = VERTEX_RADIUS + 5;

        for (int i = 0; i < vertices.size(); ++i) {
            Vertex v = vertices.get(i);
            float d = dist(mouseX(), mouseY(), v.coord.x, v.coord.y);
            if (d < minDist) {
                vertexIndex = i;
                minDist = d;
            }
        }

        return vertexIndex;
    }

    public Vertex selectVertex() {
        int index = selectVertexIndex();
        if (index == -1) {
            return null;
        } else {
            return vertices.get(index);
        }
    }

    public void addEdge(int u, int v) {
        Vertex ue = vertices.get(u);
        Vertex ve = vertices.get(v);
        edges.add(new Edge(ue, ve));
    }

    public void triangulate() {
        if (vertices != null && vertices.size() > 0)
            triangulator.triangulate(vertices.get(0));
    }

    public void handleMousePressed() {
        println("PolyController handleMousePressed: " + currentKey);

        // key > press action
        if (mouseButton == LEFT) {
            if (currentKey == 'a') addVertex(mouseX(), mouseY());
            if (currentKey == 'r') removeVertex();
        }

        // press > key action
    }

    public void handleMouseDragged() {
        println("PolyController handleMouseDragged: " + currentKey);

        // key > press action
        if (mouseButton == LEFT) {
            if (currentKey == 'm') translateVertex();
        }
    }

    public void handleMouseReleased() {
        if (currentKey == 'm') toTranslate = null;
    }

    public void handleKey() {
        lastVertex = null;
        if (currentKey == 't') triangulate();
    }

    public void display() {
        if (displayController.drawState == 0) {
            for (Edge e : edges)        e.draw();
            for (Vertex v : vertices)   v.draw();
            if (lastVertex != null) {
                stroke(TEAL);
                strokeWeight(2);
                line(mouseX(), mouseY(), lastVertex.coord.x, lastVertex.coord.y);
            }
        }
    }

}


final float VERTEX_RADIUS = 7;
int ID_COUNT = 0;
public class Vertex {
    PVector coord;
    int id;

    public Vertex(float x, float y) {
        coord = new PVector(x, y);
        id = ID_COUNT++;
    }

    public void draw() {
        stroke(BLACK);
        fill(RED);
        ellipse(coord.x, coord.y, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);

        // textSize(20);
        // textAlign(RIGHT, TOP);
        // fill(BLACK);
        // text(id, coord.x, coord.y);
    }

    @Override
    public boolean equals(Object o) {
        if (o == null) return false;
        if (!(o instanceof Vertex)) return false;
        Vertex v = (Vertex) o;
        return coord.equals(v.coord);
    }

    @Override
    public String toString() {
        return "[" + coord.x + " " + coord.y + "] : " + id;
    }
}

public class Edge {
    Vertex u, v;

    public Edge(Vertex u, Vertex v) {
        this.u = u;
        this.v = v;
    }

    public boolean contains(Vertex x) {
        return u.equals(x) || v.equals(x);
    }

    public Vertex otherVertex(Vertex v) {
        if (this.v.equals(v))
            return u;
        else
            return this.v;
    }

    public void draw() {
        stroke(BLACK);
        strokeWeight(1);
        line(u.coord.x, u.coord.y, v.coord.x, v.coord.y);

        fill(YELLOW);
        PVector top = new PVector((u.coord.x + v.coord.x) / 2.0f, (u.coord.y + v.coord.y) / 2.0f);
        PVector unitUV = PVector.sub(v.coord, u.coord).setMag(20);
        PVector sideLeft  = PVector.add(top, unitUV.copy().rotate(PI*5/6));
        PVector sideRight = PVector.add(top, unitUV.copy().rotate(-PI*5/6));

        triangle(top.x, top.y, sideLeft.x, sideLeft.y, sideRight.x, sideRight.y);
    }

    @Override
    public boolean equals(Object o) {
        if (o == null) return false;
        if (!(o instanceof Edge)) return false;
        Edge e = (Edge) o;
        return contains(e.u) && contains(e.v);
    }

    @Override
    public String toString() {
        return "[" + u + ", " + v + "]";
    }
}


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
        if (diff == 0.0f) {
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

    public void draw(int c) {
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


public class Triangulator {

    Sweeper sweeper;
    List<MonotonePolygon> monotonePolygons;

    public void triangulate(Vertex start) {
        println("Triangulator.triangulate");
        // v is the outer shape, so get all the edges
        List<List<PVector>> initList = new ArrayList<List<PVector>>();
        // List<PVector> outer = getCounterClockwise(start);
        List<PVector> outer = getPolygon(start);

        if (outer == null) {
            println("Loop is not complete");
            return;
        }

        initList.add(outer);
        // TODO: find holes.

        sweeper = new Sweeper(initList);
        sweeper.makeMonotone();
        monotonePolygons = sweeper.getMonotonePolygons();
        displayController.drawState = 1;
    }

    int currPolygon = 0;
    int mpCount = 0;
    public void drawMonotonePolygons() {
        if (mpCount > 100) {
            mpCount = 0;
            currPolygon = (currPolygon + 1) % monotonePolygons.size();
        } mpCount++;
        monotonePolygons.get(currPolygon).draw();
    }

    public List<PVector> getPolygon(Vertex start) {
        List<PVector> list = new ArrayList<PVector>();
        List<Edge> edges = polyController.edges;  

        Vertex currU = start;
        while (!list.contains(currU.coord)) {
            list.add(currU.coord);
            for (Edge e : edges) {
                if (e.u == currU) {
                    currU = e.v;
                    break;
                }
            }
        }

        println("Get Polygon " + list);
        return list;
    }

    public List<PVector> getCounterClockwise(Vertex start) {
        List<PVector> list = new ArrayList<PVector>();
        List<Edge> edges = polyController.edges;

        Vertex currVertex = start;
        Edge currEdge = null;
        for (int i = 0 ; i < edges.size(); ++i) {
            if (edges.get(i).contains(currVertex)) {
                currEdge = edges.get(i);
                break;
            }
        }
        if (currEdge == null) {
            return null;
        }        


        int signedArea = 0;
        do {
            list.add(currVertex.coord);

            // find next edge
            Vertex otherVertex = currEdge.otherVertex(currVertex);
            Edge nextEdge = currEdge;
            for (int i = 0 ; i < edges.size(); ++i) {
                if (edges.get(i).contains(otherVertex) && !edges.get(i).contains(currVertex)) {
                    nextEdge = edges.get(i);
                    break;
                }
            }
            if (nextEdge.equals(currEdge)) { //Loop is incomplete
                return null;
            }

            signedArea += currVertex.coord.x * otherVertex.coord.y - currVertex.coord.y * otherVertex.coord.x;

            currEdge = nextEdge;
            currVertex = otherVertex;
        } while (!currVertex.equals(start));

        if (signedArea < 0) Collections.reverse(list);

        return list;
    }

    public void display() {
        if (sweeper != null) sweeper.draw();
        if (displayController.drawState == 2) {
            if (monotonePolygons != null) {
                drawMonotonePolygons();
            }
        }
    }

    public void handleKey() {
        if (sweeper != null) sweeper.handleKey();
    }
}
// COLORS
final int BLACK    = color(0,0,0);
final int WHITE    = color(255,255,255);
final int RED      = color(255,0,0);
final int ORANGE      = color(255,0,0);
final int LIME     = color(0,255,0);
final int BLUE     = color(0,0,255);
final int YELLOW   = color(255,255,0);
final int YELLOWGREEN   = color(223, 255, 0);
final int CYAN     = color(0,255,255);
final int MAGENTA  = color(255,0,255);
final int SILVER   = color(192,192,192);
final int GRAY     = color(128,128,128);
final int MAROON   = color(128,0,0);
final int OLIVE    = color(128,128,0);
final int GREEN    = color(0,128,0);
final int PURPLE   = color(128,0,128);
final int TEAL     = color(0,128,128);
final int NAVY     = color(0,0,128);
final int BROWN    = color(139,69,19);

final int SKYBLUE  = color(0, 204, 255);
final int GROUNDGREEN  = color(166,225,86);
final int WALLGRAY = color(134,125,140);

// rotate v around axis by ang radians.
public PVector rotate(PVector v, PVector _axis, float angle)
{
    //use normalised values
    PVector axis = _axis.copy().normalize();
    PVector vNorm = v.copy().normalize();
    float pMag = axis.dot(v);
    PVector parallel = PVector.mult(axis, pMag); //multiply all elements by a value
    PVector perp = PVector.sub(v, parallel);    //subtract one PVector from another
    PVector cross = v.cross(axis); //cross product
    return PVector.add(parallel,PVector.add(PVector.mult(cross,sin(-angle)), PVector.mult(perp,cos(-angle))));
} 
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Triangulation" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
