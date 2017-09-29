import java.util.*;

public class Triangulator {
    Sweeper sweeper;
    List<MonotonePolygon> monotonePolygons;

    public void triangulate(List<Vertex> vertices, List<Edge> edges) {
        println("Triangulator.triangulate");
        // v is the outer shape, so get all the edges

        List<List<PVector>> initList = new ArrayList<List<PVector>>(); //<>//
        List<PVector> outer = getPolygon(vertices.get(0), vertices, edges);

        if (outer == null) {
            println("   Loop is not complete");
            return;
        }

        initList.add(outer);
        
        // Find Holes        
        Set<PVector> visited = new HashSet<PVector>();
        visited.addAll(outer);
        for (int i = 0; i < vertices.size(); ++i) {
            Vertex curr = vertices.get(i);
            if (!visited.contains(curr.coord)) {
                List<PVector> l = getPolygon(curr, vertices, edges);
                visited.addAll(l);
                initList.add(l);
            }
        }
        println(initList);

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

    // Assume clockwise orientation of vertices
    public List<PVector> getPolygon(Vertex start, List<Vertex> vertices, List<Edge> edges) {
        List<PVector> list = new ArrayList<PVector>();
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
        return list;
    }

    // public List<PVector> getCounterClockwise(Vertex start) {
    //     List<PVector> list = new ArrayList<PVector>();
    //     List<Edge> edges = polyController.edges;

    //     Vertex currVertex = start;
    //     Edge currEdge = null;
    //     for (int i = 0 ; i < edges.size(); ++i) {
    //         if (edges.get(i).contains(currVertex)) {
    //             currEdge = edges.get(i);
    //             break;
    //         }
    //     }
    //     if (currEdge == null) {
    //         return null;
    //     }        


    //     int signedArea = 0;
    //     do {
    //         list.add(currVertex.coord);

    //         // find next edge
    //         Vertex otherVertex = currEdge.otherVertex(currVertex);
    //         Edge nextEdge = currEdge;
    //         for (int i = 0 ; i < edges.size(); ++i) {
    //             if (edges.get(i).contains(otherVertex) && !edges.get(i).contains(currVertex)) {
    //                 nextEdge = edges.get(i);
    //                 break;
    //             }
    //         }
    //         if (nextEdge.equals(currEdge)) { //Loop is incomplete
    //             return null;
    //         }

    //         signedArea += currVertex.coord.x * otherVertex.coord.y - currVertex.coord.y * otherVertex.coord.x;

    //         currEdge = nextEdge;
    //         currVertex = otherVertex;
    //     } while (!currVertex.equals(start));

    //     if (signedArea < 0) Collections.reverse(list);

    //     return list;
    // }

    public void display() {
        if (sweeper != null) sweeper.draw();   // drawState: 1, 2, 3
        if (displayController.drawState == 4) {
            if (monotonePolygons != null) {
                monotonePolygons = sweeper.getMonotonePolygons();
                drawMonotonePolygons();
            }
        }
    }

    public void handleKey() {
        if (sweeper != null) sweeper.handleKey();
    }
}