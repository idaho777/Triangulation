
public class EditController {
  
    public void display() {
        
    }
}




char currentKey;
void keyPressed() {
    currentKey = key;
    if (currentKey == '-') setup();
    if (currentKey == 'D') DEBUG = !DEBUG;
    displayController.handleKey();
    fileController.handleKey();
    polyController.handleKey();
    triangulator.handleKey();
}

void mouseWheel(MouseEvent event) {

}

void mousePressed() {
    polyController.handleMousePressed();
}

void mouseDragged() {
    polyController.handleMouseDragged();
}

void mouseReleased() {
    polyController.handleMouseReleased();
}


int mouseX() { return mouseX; }
int mouseY() { return height - mouseY; }