
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


    void displayText() {
        displaySettings();
    }

    void displaySettings() {
        String settings = String.format("Current File: %s", currFile);
        textSize(14);
        textAlign(LEFT, TOP);
        fill(BLACK);
        text(settings, 10, 10);
    }

}


String currFile = null;
void readEditSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        return;
    }

    readEdit(selection);
}

void writeEditSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        return;
    }
    writeEdit(selection);
}


// READ JOONHO FILE
void readEdit(File selection) {
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

List<Vertex> readVertex(BufferedReader reader) throws IOException {
    String line = reader.readLine();
    List<Vertex> list = new ArrayList<Vertex>();

    line = reader.readLine();
    while (!line.equals("close vertex list")) {
        line = line.replaceAll("\\s","");
        float[] c = float(split(line, ','));
        PVector v = new PVector(c[0], c[1]);
        list.add(new Vertex(v.x, v.y));
        line = reader.readLine();
    }

    return list;
}

List<Edge> readEdge(BufferedReader reader, List<Vertex> vertices) throws IOException {
    String line = reader.readLine();
    List<Edge> list = new ArrayList<Edge>();

    line = reader.readLine();
    while (!line.equals("close edge list")) {
        line = line.replaceAll("\\s","");
        int[] c = int(split(line, ','));
        list.add(new Edge(
                vertices.get(c[0]),
                vertices.get(c[1])));
        line = reader.readLine();
    }

    return list;
}


// WRITE JOONHO FILE
void writeEdit(File selection) {
    println("Exporting joonho");
    PrintWriter output = createWriter(selection + ".joonho");
    List<Vertex> v = polyController.vertices;
    List<Edge> e  = polyController.edges;
    output.write(writeEditText(selection, v, e));
    output.flush();
    output.close();

    currFile = selection.getName();
}

String writeEditText(File selection, List<Vertex> vertices, List<Edge> edges) {
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
