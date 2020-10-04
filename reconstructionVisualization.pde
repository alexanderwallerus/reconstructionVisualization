//code by Alexander Wallerus 
//MIT license

import peasy.PeasyCam;
PeasyCam cam;

ArrayList<Vertex> verts;
PShape neuron;
PShape contours;
PVector minCoord;
PVector maxCoord;
PShape boundBox;
PShape vars;
ArrayList<PVector> vars3D;
ArrayList<PVector> vars2D;
boolean toggleBoundBox = true;
boolean toggleArrowsXYZ = true;
boolean toggleOrtho = false;
boolean toggleVaricosities = true;
boolean toggleCustomDrawing = true;

boolean display3D = true;
//false for lines, true for 3d model of shape
//int[] modelQual = {8, 5};
int[] modelQual = {20, 10};
//resolution of conelinders, first value is number of segment sides, 2nd is 
//resolution of node spheres
boolean showNodes = true;
//showing nodes impacts necessary memory but makes closeups look a bit nicer
PVector arrowPos = new PVector(30, 30, 25);
//the position of the x y z axis indicator
color[] typeCols;

void setup(){
  size(1000, 1000, P3D);
  cam = new PeasyCam(this, 400);
  //load the colors to be used for processes from the .txt file
  String[] colorLines = loadStrings("typeColors.txt");
  typeCols = new color[colorLines.length];
  for(int i=0; i<colorLines.length; i++){
    String[] colStrs = split(colorLines[i], ',');
    colStrs = trim(colStrs);
    int[] cols = int(colStrs);
    typeCols[i] = color(cols[0], cols[1], cols[2]);
    //println(cols[0], cols[1], cols[2]);
  }
  String swcLines[] = loadStrings("reconst.swc");
  //remove the header line
  swcLines = subset(swcLines, 1, swcLines.length-1);
  verts = new ArrayList<Vertex>();
  for(int i=0; i<swcLines.length; i++){
    //trimming is only necessary if i.e. a neuronland conversion added whitespace in
    //front but doesn't hurt anyway
    swcLines[i] = trim(swcLines[i]);
    verts.add(new Vertex(swcLines[i]));
  }
  //swc files are still formally correct, if the order of lines is mixed up.
  //export as swc from the program should reorder the lines correctly, so the
  //indices in the arraylist should line up with line number-1. If this is
  //not the case, then need to sort them by their line here before continuing!
  println("showing first 5 elements for control:");
  for(int i=0; i<5; i++){
    println(verts.get(i).origString);
  }
  println("number of vertices: " + verts.size());
  getVaricosities();
  calcBoundaryBox();
  //precompute the shape for greater efficency
  if(!display3D){
    makeNeuronSkeleton();
  } else {
    makeNeuron3D();
  }
}

void draw(){
  background(0);
  //reduce the near clipping plane to 0.01 and increase the faroff clipping plane to 
  //cameraZ times 40.
  float cameraZ = (height/2.0) / tan(PI/6.0);
  if(toggleOrtho){
    ortho();
  } else {
    perspective(PI/3.0, width/height, 0.01, cameraZ*40.0);
  }

  noLights();                //reset light
  ambientLight(20, 20, 20);  //light everything at least a bit
  directionalLight(255, 255, 255, 1, 0, 0);
  directionalLight(255, 255, 255, 0, 1, 0);
  shape(neuron, 0, 0);
  if(display3D){
    shape(contours, 0, 0);
  }
  stroke(255);    
  noFill();
  if(toggleBoundBox){
    shape(boundBox);
  }
  if(toggleArrowsXYZ){
    drawAxis(arrowPos);
  }
  if(toggleVaricosities){
    recalculateVaricosities();
  }
  if(toggleCustomDrawing){
    addCustomDrawing();
  }
}

class Vertex {
  String origString;
  int line;
  //structure Identifier: 0=undefined, 1=soma, 2=axon, 3=(basal) dendrite,
  //4=apical dendrite, 5+ = custom, use 11 for varicosities/synapses
  //use type >=20 for contours which are to be shown as lines
  int structureIdent;  
  float x;
  float y;
  float z;
  float r;
  int parentLine;

  Vertex(String parameters) {
    origString = parameters;
    String[] params = split(parameters, " ");
    line = int(params[0]);
    structureIdent = int(params[1]);
    x = float(params[2]);
    y = float(params[3]);
    z = float(params[4]);
    r = float(params[5]);
    parentLine = int(params[6]);
  }
}

void makeNeuronSkeleton(){
  neuron = createShape();
  neuron.beginShape(LINES);
  neuron.noFill();
  neuron.stroke(255);
  for (int i=0; i<verts.size(); i++){
    Vertex now = verts.get(i);
    if(now.parentLine != -1){
      //this vertex is not a tree root
      Vertex parent = verts.get(now.parentLine-1);
      //arrayList starts with 0, swc lines at 1
      if(parent.line != now.parentLine){
        println("there is a mistake");
      }
      //add a line from parent to current vertex
      neuron.vertex(parent.x, parent.y, parent.z);
      neuron.vertex(now.x, now.y, now.z);
      //line(parent.x, parent.y, parent.z, now.x, now.y, now.z);
    }else{
      //println("line " + i + " is a root");
    }
  }
  neuron.endShape();
}

void makeNeuron3D(){
  neuron = createShape(GROUP);
  contours = createShape(GROUP);
  for(int i=0; i<verts.size(); i++){
    Vertex now = verts.get(i);
    if(now.structureIdent < 20){
      //draw the tree
      if(now.parentLine != -1){
        //this vertex is not a tree root
        Vertex parent = verts.get(now.parentLine-1);
        //arrayList starts with 0, swc lines at 1
        if(parent.line != now.parentLine){
          println("MISTAKE");
        }
        //add a conelinder from parent to current vertex
        pushMatrix();
          translate(now.x, now.y, now.z);
          addConeLinder(neuron, parent, now, modelQual);
        popMatrix();
      }else{
        sphereDetail(9);  noStroke();
        ambient(typeCols[now.structureIdent]);
        fill(typeCols[now.structureIdent]);
        PShape root = createShape(SPHERE, now.r);
        root.translate(now.x, now.y, now.z);
        neuron.addChild(root);
      }
    } else {
      if(now.parentLine != -1){
        Vertex parent = verts.get(now.parentLine-1);
        if(parent.line != now.parentLine){
          println("MISTAKE");
        }
        PShape contour = createShape();
        contour.beginShape(LINES);
        contour.noFill();
        contour.stroke(typeCols[now.structureIdent]);
        contour.vertex(parent.x, parent.y, parent.z);
        contour.vertex(now.x, now.y, now.z);
        contour.endShape();
        contours.addChild(contour);
      }
    }
  }
}

void addConeLinder(PShape tree, Vertex parent, Vertex now, int[] modelQual){
  float len = dist(parent.x, parent.y, parent.z, now.x, now.y, now.z);
  float r0 = parent.r;
  float r1 = now.r;
  int sides = modelQual[0];
  float angle = TWO_PI/sides;
  
  ambient(typeCols[now.structureIdent]);
  fill(typeCols[now.structureIdent]);
  PShape coneLinder = createShape(GROUP);
  PShape tube = createShape();
  tube.beginShape(TRIANGLE_STRIP);      // draw sides
  //tube.stroke(50, 50, 50);  
  //tube.noStroke();
  //tube.fill(typeCols[now.structureIdent]);
  for(int i=0; i<sides+1; i++) {
    float x0 = cos(i * angle) * r0;
    float y0 = sin(i * angle) * r0;
    float x1 = cos(i * angle) * r1;
    float y1 = sin(i * angle) * r1;
    tube.vertex(x0, y0, 0);
    tube.vertex(x1, y1, len);
  }
  tube.endShape(CLOSE);
  coneLinder.addChild(tube);
  
  //add spheres to round of the intersegment node areas
  if(showNodes){
    pushMatrix();
      sphereDetail(modelQual[1]);
      //stroke(255, 0, 0);  fill(0, 255, 0);
      noStroke();  //fill(typeCols[now.structureIdent]);
      PShape sphere = createShape(SPHERE, now.r);
      sphere.translate(0, 0, len);
      coneLinder.addChild(sphere);
    popMatrix();
  }
  PVector heading = new PVector(now.x-parent.x, now.y-parent.y, now.z-parent.z);
  PVector rtp = cartesianToSpherical(heading);
  //spherical coordinates use radius, theta and phi
  coneLinder.rotateY(rtp.z);
  coneLinder.rotate(rtp.y, 0, 0, 1);  //rotateZ() fix for processing 3.5
  
  coneLinder.translate(parent.x, parent.y, parent.z);
  tree.addChild(coneLinder);
}

PVector cartesianToSpherical(PVector xyz){
  PVector rtp = new PVector();
  float r = sqrt(xyz.x*xyz.x + xyz.y*xyz.y + xyz.z*xyz.z);
  if(r != 0){
    rtp.x = r;
    rtp.y = atan2(xyz.y, xyz.x);
    rtp.z = acos(xyz.z / r);
  }
  return rtp;
}

void drawAxis(PVector pos){
  //box(20);
  float l = 50;
  stroke(255, 0, 0);
  strokeWeight(2);
  line(pos.x, pos.y, pos.z, pos.x+l, pos.y, pos.z);
  PVector xAxis = new PVector(screenX(pos.x+l, pos.y, pos.z), 
                  screenY(pos.x+l, pos.y, pos.z), screenZ(pos.x+l, pos.y, pos.z));
  stroke(0, 255, 0);
  line(pos.x, pos.y, pos.z, pos.x, pos.y+l, pos.z);
  PVector yAxis = new PVector(screenX(pos.x, pos.y+l, pos.z),
                  screenY(pos.x, pos.y+l, pos.z), screenZ(pos.x, pos.y+l, pos.z));
  stroke(0, 0, 255);
  line(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z+l);
  PVector zAxis = new PVector(screenX(pos.x, pos.y, pos.z+l), 
                  screenY(pos.x, pos.y, pos.z+l), screenZ(pos.x, pos.y, pos.z+l));
  strokeWeight(1);
  cam.beginHUD();
    textAlign(CENTER);
    textSize(20);
    fill(255, 0, 0);
    text("X Axis", xAxis.x, xAxis.y, xAxis.z);
    fill(0, 255, 0);
    text("Y Axis", yAxis.x, yAxis.y, yAxis.z);
    fill(0, 0, 255);
    text("Z Axis", zAxis.x, zAxis.y, zAxis.z);
    textAlign(LEFT);
    //text("This Text is in the top left", 10, 10);  
  cam.endHUD();
}

void calcBoundaryBox(){
  minCoord = new PVector(MAX_FLOAT, MAX_FLOAT, MAX_FLOAT);
  maxCoord = new PVector(MIN_FLOAT, MIN_FLOAT, MIN_FLOAT);
  for(Vertex vert : verts){
    minCoord.x = min(minCoord.x, vert.x);
    minCoord.y = min(minCoord.y, vert.y);
    minCoord.z = min(minCoord.z, vert.z);
  }
  for(Vertex vert : verts){
    maxCoord.x = max(maxCoord.x, vert.x);
    maxCoord.y = max(maxCoord.y, vert.y);
    maxCoord.z = max(maxCoord.z, vert.z);
  }
  PVector whd = PVector.sub(maxCoord, minCoord);
  PVector offset = PVector.mult(whd, 0.5);
  noFill();
  stroke(255);
  boundBox = createShape(BOX, whd.x, whd.y, whd.z);
  boundBox.translate(minCoord.x+offset.x, minCoord.y+offset.y, 
                     minCoord.z+offset.z);
  println("Boundary box x axis extend: " + whd.x + " units");
  println("Boundary box y axis extend: " + whd.y + " units");
  println("Boundary box z axis extend: " + whd.z + " units");
}

void keyPressed(){
  switch(key){
    case 'b':  toggleBoundBox = !toggleBoundBox;  break;
    case 'a':  toggleArrowsXYZ = !toggleArrowsXYZ;  break;
    case 'o':  toggleOrtho = !toggleOrtho;  break;
    case 'v':  toggleVaricosities = !toggleVaricosities;  break;
    case 'd':  toggleCustomDrawing = !toggleCustomDrawing;  break;
    default:  break;
  }
}

void getVaricosities(){
  vars3D = new ArrayList<PVector>();
  vars2D = new ArrayList<PVector>();
  for(Vertex vert : verts){
    if(vert.structureIdent == 11){
      vars3D.add(new PVector(vert.x, vert.y, vert.z));
      //calculate 2D positions
      vars2D.add(new PVector(screenX(vert.x, vert.y, vert.z), 
                             screenY(vert.x, vert.y, vert.z),
                             screenZ(vert.x, vert.y, vert.z)));
    }
  }
}

void recalculateVaricosities(){
  //recalculate 2D positions every frame
  for(int i=0; i<vars2D.size(); i++){
    PVector var2D = vars2D.get(i);
    PVector var3D = vars3D.get(i);
    //get the screen position for the euclidian position in space
    var2D.set(screenX(var3D.x, var3D.y, var3D.z), 
              screenY(var3D.x, var3D.y, var3D.z), //1); alternatively
              screenZ(var3D.x, var3D.y, var3D.z));
    //the z will always be very close to 1, i.e. 0.99999046 no matter the rotation,
    //x and y will show their position on the 2D x, y grid
  }
  //now show varicosities
  cam.beginHUD();
    ellipseMode(CENTER);
    stroke(255, 0, 0);
    strokeWeight(2);
    noFill();
    for(PVector v : vars2D){
      pushMatrix();
        translate(v.x, v.y, v.z);
        ellipse(0, 0, 20, 20);
      popMatrix();
    }
  cam.endHUD();
  strokeWeight(1);
}

void addCustomDrawing(){
  //draw a purple line between those 2 points
  stroke(255, 0, 255);
  line(687, 57, 74, 362, 628, 475);
  //draw a dark red box with this width, height, depth at this position
  pushMatrix();
    translate(627, 359.998, 463.5);
    noFill();
    stroke(127, 0, 0);
    box(20, 20, 80);
  popMatrix();
}
