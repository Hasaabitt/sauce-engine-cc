# Sauce functions  
Core functions  
**sauce.createCanvas([number x, number y, number length, number width])**
Creates canvas at coordinates with dimensions. No arguments sets it to the terminal size

**sauce.demo(table canvas)**  
Runs demo  
Demo controls  
w - move forward  
a - move left  
s - move backwards  
d - move right  
space - move up  
shift - move down  
p - screenshot  
del - exit

**sauce.color2blit(number color)**  
Takes color and converts it to its appropriate blit value. Exposed for utility

**sauce.objlib**  
Exposes the OBJ api as an alternative to directly requiring it yourself

# Canvas functions
**canvas.createLine(number x1, number y1, number x2, number y2[, number color])**  
Creates a line with given points and color (default white) to be rendered

**canvas.createBox(number x, number y, number z, number, l, number w, number h[, number color)**  
Creates a box at the given point in 3D space with given length, width, and height

**canvas.createTriangle(number x1, number y1, number z1, number x2, number y2, number z2, number x3, number y3, number z3[, number color])**  
Creates a triangle connecting three given points in 3D space

**canvas.createPoly([number color,] table{number x, number y, number z}, ...)**  
Creates a polygon with given points in 3D space. Closes off points fully

**canvas.createOpenPoly([number color,] table{number x, number y, number z}, ...)**  
Creates a polygon with given points in 3D space. Leaves gap between first and last points open

**canvas.screenshot(boolean clear)**  
Takes a screenshot. If clear is set to true, make pixels matching the background color clear

**canvas.moveCamera(number dx, number dy, number dz)**  
Moves camera by relative distance

**canvas.bdraw(boolean screenclear)**  
Draws objects to the buffer. If true, clear the buffer before drawing

**canvas.bclear()**  
Clear the buffer

**canvas.bflush()**  
Display the contents of the buffer

**canvas.oget(string type)**  
Get objects with type

**canvas.oclear(string type)**  
Clear objects of type, if no arguments are provided then clear everything

**canvas.UIBasic(...)**  
Shows a basic UI and displays provided information. Useful for debugging

# --- Objlib ---  
Handles .obj files  
Available through Sauce via sauce.objlib

**obj.parse(string path)**  
Parses obj file to useable lua table

**obj.build(table file)**  
Takes object file and returns a table containing the verticies of each face

**obj.getV(table objects, number vertex_number)**  
Get the vertex with the associated number

**obj.getVN(table objects, number vertex_normal_number)**  
Get the vertex normal with the associated number

**obj.getVT(table objects, number texture_coordinate_number)**  
Get the texture coordinate associated with the number)  
Note that some verticies may not have this depending on how the file was set up
