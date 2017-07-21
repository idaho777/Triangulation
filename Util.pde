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

// rotate v around axis by ang radians.
PVector rotate(PVector v, PVector _axis, float angle)
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