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