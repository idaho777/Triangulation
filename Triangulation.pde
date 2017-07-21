
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
    background(WHITE);
    noStroke();
    noFill();

    displayController.displayText();

    scale(1, -1);
    translate(0, -height);
    
    displayController.display();
}