// COLORS
final color BLACK    = color(0,0,0);
final color WHITE    = color(255,255,255);
final color RED      = color(255,0,0);
final color ORANGE      = color(255,0,0);
final color LIME     = color(0,255,0);
final color BLUE     = color(0,0,255);
final color YELLOW   = color(255,255,0);
final color YELLOWGREEN   = color(223, 255, 0);
final color CYAN     = color(0,255,255);
final color MAGENTA  = color(255,0,255);
final color SILVER   = color(192,192,192);
final color GRAY     = color(128,128,128);
final color MAROON   = color(128,0,0);
final color OLIVE    = color(128,128,0);
final color GREEN    = color(0,128,0);
final color PURPLE   = color(128,0,128);
final color TEAL     = color(0,128,128);
final color NAVY     = color(0,0,128);
final color BROWN    = color(139,69,19);

final color SKYBLUE  = color(0, 204, 255);
final color GROUNDGREEN  = color(166,225,86);
final color WALLGRAY = color(134,125,140);

float det(PVector u, PVector v) {
  PVector uR = new PVector(-u.y, u.x);
  return uR.dot(v);
}
    
boolean vecIntersects(PVector v, PVector vec, PVector a, PVector b) {
    PVector v1 = vec.copy();
    PVector v2 = PVector.sub(b, a);
    PVector v3 = PVector.sub(a, v);

    float s = v3.cross(v2).dot(v1.cross(v2)) / v1.cross(v2).magSq();

    if (s >= 0 && s <= 1) {
        PVector i = PVector.add(v, PVector.mult(v1, s));
        if (sq(dist(i.x, i.y, a.x, a.y)) + sq(dist(i.x, i.y, b.x, b.y)) <= v2.magSq() + 0.005)
            return true;
    }
    return false;
}

float clockwiseAngle(PVector b, PVector a) {
    float dot = PVector.dot(a, b);
    float det = a.x*b.y - a.y*b.x;
    float angle = atan2(det, dot);
    if (angle < 0) return angle + TAU;
    return angle;
}