
DoublyEdgeList dEList;

DisplayController displayController;
EditController    editController;
FileController    fileController;
PolyController    polyController;
Triangulator      triangulator;

void settings() {
    size(1024,768,P2D);
}

void setup() {
    initControllers();

    ID_COUNT = 0;
    DID_COUNT = 0;
    DFACEID_COUNT = 0;
    DEDGEID_COUNT = 0;
}

void initControllers() {
    displayController = new DisplayController();
    editController = new EditController();
    fileController = new FileController();
    polyController = new PolyController();
    triangulator = new Triangulator();
}

void draw() {
    background(WHITE); noStroke(); noFill();
    
    displayController.displayText();

    scale(1, -1); translate(0, -height);
    
    fill(YELLOW); ellipse(100, 100, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);
    fill(BROWN); ellipse(1000, 700, 2*VERTEX_RADIUS, 2*VERTEX_RADIUS);
    
    displayController.display();
}