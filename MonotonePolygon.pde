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
        return "[" + data.toString() + " -- " + chainType + "]";
    }
}

public enum MonotoneChainType {
    LEFT, RIGHT,
}
