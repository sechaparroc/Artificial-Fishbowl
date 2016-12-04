import java.awt.Color;
import java.util.Random;
import remixlab.proscene.*;
import remixlab.dandelion.core.*;
import remixlab.dandelion.geom.*;
import java.awt.Rectangle;

Scene scene;
InteractiveFrame[] iFrames;
PImage bg;
Vec r_world = new Vec(1000,1000,1000);
ArrayList<Boid> flock = new ArrayList<Boid> ();
/*Agents list*/
ArrayList<Fish> agents = new ArrayList<Fish>();
ArrayList<Fish> population = new ArrayList<Fish>();
String renderer = P3D;
/*Vegetation using L-Systems*/
Animation[] t_shape = new Animation[2];

/*Create three kinds of Trees based on some predefined rules*/
Animation[] createVegetation(){
  Animation[] t_shape = new Animation[2];
  t_shape[0] = new Animation();
  RuleSystem t1; 
  for(int k = 0; k <3;k++){
    t1 = new RuleSystem(20.5 + 2*k,2,"F",4, 5, 0);
    t1.rules.add(new rule('F',"F[-/&F][-/|F][-*|F][-*&F][+/|F][+/&F][+*|F][+*&F][F]"));
    //println("initial axiom: " + t1.axiom);
    t1.applyRules();  
    //println("final axiom: " + t1.axiom);
    t_shape[0].p.add(t1.getShape());
  }
  t_shape[1] = new Animation();
  RuleSystem t2; 
  for(int k = 0; k <3;k++){
    t2 = new RuleSystem(18+2*k,2,"X",4, 5, 0.025);
    t2.rules.add(new rule('X',"F[+*|X]F[-/&F][-/|X][-*|X][-*&X][+/|X][+/&X][+*&X]+*|X"));
    t2.rules.add(new rule('F',"FF"));
    //println("initial axiom: " + t1.axiom);
    t2.applyRules();  
    //println("final axiom: " + t1.axiom);
    t_shape[1].p.add(t2.getShape());
  }
  return t_shape;
}

/*Stablish location of some vegetation based on Trees previously created*/
InteractiveFrame[] setupVegetation(Animation[] t_shape){
  InteractiveFrame[] iFrames = new InteractiveFrame[17];
  for(int i = 0; i < iFrames.length; i++){
    iFrames[i] = new InteractiveFrame(scene);
    //iFrames[i].setGrabsInputThreshold(scene.radius()/4, true);
    iFrames[i].scale(3);
  }  
  int x_c = 100; int y_c = 100; int dif = 40;
  iFrames[0].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[1].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[2].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[3].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = (int) r_world.x() - 100; y_c = 100;
  iFrames[4].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[5].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[6].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[7].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = 100; y_c = (int) r_world.z() - 100;
  iFrames[8].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[9].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[10].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[11].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = (int) r_world.x() - 100; y_c = (int) r_world.z() - 100;
  iFrames[12].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[13].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[14].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[15].translate(new Vec(x_c, r_world.y(), y_c - dif));
  iFrames[16].translate(new Vec(r_world.x()/2, r_world.y(), r_world.z()/2));
  return iFrames;
}

void setupScene(Scene scene){
  scene.setAxesVisualHint(false);
  scene.setGridVisualHint(false);
  scene.setCameraType(Camera.Type.ORTHOGRAPHIC);
  scene.setBoundingBox(new Vec(0, 0, 0), r_world);
  scene.showAll();
  scene.enableMotionAgent();
  scene.enableKeyboardAgent();
}

void setup(){  
  size(800, 600, renderer);
  textureWrap(REPEAT);  
  scene = new Scene(this);  
  /*Disable Events while setting up the environment*/
  scene.disableMouseAgent();
  scene.disableMotionAgent();

  t_shape = createVegetation();
  iFrames = setupVegetation(t_shape);
  //Define some scene properties
  preloadMorphology();
  setupScene(scene);

  scale_factor= 0.2;    
  createFishGroup(1);
  
  //println("pez : " + i);
  scale_factor= 0.1;    
  createFishGroup(20);
  createFishGroup(20);

  scale_factor= 0.05;    
  createFishGroup(50);
  createFishGroup(50);

  scale_factor= 0.028;    
  createFishGroup(30);
  createFishGroup(30);

  addEnemies();
  bg = loadImage("background/1.jpeg" );
  bg.resize(800,600);
  /*Enable Events when finishing setting up the environment*/
  scene.enableMouseAgent();
  scene.enableMotionAgent();  
  loop();  
}

boolean begin = false;
int conta = 50;
void draw(){
  if(!pause)conta--;
  //background(color(59,145,255));
  background(bg);
  //ambientLight(128, 128, 128);
  directionalLight(255, 255, 255, 0, 1, -500);  
  directionalLight(255, 255, 255, 0, 1, 500);
  directionalLight(255, 255, 255, 500, 1, 0);
  directionalLight(255, 255, 255, -500, 1, 0);
  //directionalLight(255, 255, 255, 1, 500, 0);
  //directionalLight(255, 255, 255, 1, -500, 0);

  drawContainer();
  //trees
  for(int i = 0; i < iFrames.length; i++){
    pushMatrix();
    iFrames[i].applyTransformation();//very efficient
    //scene.drawAxes(20);
    if(i < 15) t_shape[0].draw();
    else t_shape[1].draw();
    popMatrix();
  } 
  if(conta  == 0 && !pause){
    println("entra");
    conta = 50;
    for(int i = 0; i < agents.size(); i++){
      agents.get(i).run();
    }
    println(agents.size());
  }
  //fish
  for(int i = 0; i < flock.size(); i++){
    if(!pause){ 
    flock.get(i).run();
    }
    flock.get(i).render();
  }
}

void mousePressed(){
    Vec v = scene.eye().unprojectedCoordinatesOf(new Vec(mouseX, mouseY));
    print("Vec : " + v);  
}  


//create fish group
void createFishGroup(int num){
  Fish a = new Fish();
  last_texture = applyTuringMorph(true, false, a);
  PShape fish = applyDeformation(a);
  for(int i = 0; i < num; i++){
    ArrayList<Boid> boids = new ArrayList<Boid>();
    Fish agent = new Fish();
    agent.c1 = a .c1; agent.c2 = a.c2;
    agent.Da = a.Da; agent.Db = a.Db; agent.pa = a.pa; agent.pb = a.pb;
    agent.h = a.h; agent.w = a.w; agent.l = a.l;
    agent.base_model = a.base_model;
    Boid b = generateBoid((int)random(0,r_world.x() - 100), (int)random(0,r_world.y() - 100), (int)random(0,r_world.z() - 100),fish);    
    agent.boid = b;
    boids.add(b);
    flock.add(b);
    b.boids = boids;
    agent.updateVision();
    agents.add(agent);
    population.add(agent);
  }
}

void drawContainer(){
  pushStyle();
  stroke(255);
  line(0, 0, 0, 0, r_world.y(), 0);
  line(0, 0, r_world.z(), 0, r_world.y(), r_world.z());
  line(0, 0, 0, r_world.x(), 0, 0);
  line(0, 0, r_world.z(), r_world.x(), 0, r_world.z());

  line(r_world.x(), 0, 0, r_world.x(), r_world.y(), 0);
  line(r_world.x(), 0, r_world.z(), r_world.x(), r_world.y(), r_world.z());
  line(0, r_world.y(), 0, r_world.x(), r_world.y(), 0);
  line(0, r_world.y(), r_world.z(), r_world.x(), r_world.y(), r_world.z());

  line(0, 0, 0, 0, 0, r_world.z());
  line(0, r_world.y(), 0, 0, r_world.y(), r_world.z());
  line(r_world.x(), 0, 0, r_world.x(), 0, r_world.z());
  line(r_world.x(), r_world.y(), 0, r_world.x(), r_world.y(), r_world.z());
  popStyle();  
}

void addEnemies(){
  for(Fish ag : agents){
    for(Fish ag2 : agents){
      if(ag == ag2) continue;
      if(ag.h < 0.6*ag2.h || ag.w < 0.6*ag2.w || ag.l < 0.6*ag2.l){
        ag.boid.predators.add(ag2.boid);
        ag2.boid.preys.add(ag.boid);
        println("Added enemy...");
      }
    }
  }
}

boolean pause = false;
void keyPressed(){
  if(key == ' '){
    pause = !pause;
  }
  if(key == 'g'){
    executeGA();
  }
}