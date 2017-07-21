import java.util.*;

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
        PVector top = new PVector((u.coord.x + v.coord.x) / 2.0, (u.coord.y + v.coord.y) / 2.0);
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