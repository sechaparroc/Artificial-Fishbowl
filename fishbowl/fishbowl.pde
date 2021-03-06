/*
Artificial-Fishbowl
by Sebastian Chaparro

This example is based on Craig Reynolds Algorithm Boids, and the example Flocks provided by Proscene.
Each agent is a Fish with the following features:
- Its joined to a Flock according to a Happiness function based on: Shape and Color 
- Is prey or predator of groups of Fishes according to its dimensions.
- Its Texture is generated by TuringMorph algorithm
- Its Shape is deformed by local affine transformations using MLS approach

It is possible to homogenize the population using a Evolutionary algorithm
Additionaly, there is some pretty straightforward vegetation based on L-Systems

As in Flock example provided by Proscene, when an animation is activated (scene.startAnimation()), the
scene.animatedFrameWasTriggered boolean variable is updated each frame of your drawing loop by proscene
according to scene.animationPeriod().

You can tune the frequency of your animation (default is 60Hz) using
setAnimationPeriod(). The frame rate will then be fixed.

Also, when you click on a boid it will be selected as the avatar, useful for the THIRD_PERSON proscene camera mode.
Click the space bar to switch between the different camera modes: ARCBALL, WALKTHROUGH, and THIRD_PERSON.

Press 'p' to pause or resume the animation.
Press '+' to decrease the animation period (animation speeds up).
Press '-' to increase the animation period (animation speeds down).
Press 'g' to apply a evolutionary algorithm 
          (it is time consuming and must be used when boids seems to not converge in flocks).
Press 'f' to toggle the drawing of the frame selection hits.
Press 'h' to display the key shortcuts and mouse bindings in the console.
*/

import remixlab.proscene.*;
import remixlab.dandelion.core.*;
import remixlab.dandelion.geom.*;

/*Some Global variables*/
int id = 0;//Used to check if a given Fish must be added to another group
Scene scene;//Main scene
InteractiveFrame[] iFrames;//Frames where vegetation is located
PImage bg;//Background
Vec r_world = new Vec(1000, 1000, 1000);//Size of the world
ArrayList<Boid> flock = new ArrayList<Boid> ();//List of all boids in the scene
/*Agents list*/
ArrayList<Fish> agents = new ArrayList<Fish>();//list of all groups of Fish in the scene
ArrayList<Fish> population = new ArrayList<Fish>(); //List of all Fish in the scene (used to apply GA)
String renderer = P3D;
/*Vegetation using L-Systems*/
Animation[] t_shape = new Animation[2];

Trackable lastAvatar;
boolean triggered;
boolean inThirdPerson;
boolean changedMode;


/*Create three kinds of Trees based on some predefined rules*/
Animation[] createVegetation() {
  Animation[] t_shape = new Animation[2];
  t_shape[0] = new Animation();
  RuleSystem t1; 
  for (int k = 0; k <3; k++) {
    t1 = new RuleSystem(20.5 + 2*k, 2, "F", 4, 5, 0);
    t1.rules.add(new rule('F', "F[-/&F][-/|F][-*|F][-*&F][+/|F][+/&F][+*|F][+*&F][F]"));
    //println("initial axiom: " + t1.axiom);
    t1.applyRules();  
    //println("final axiom: " + t1.axiom);
    t_shape[0].p.add(t1.getShape());
  }
  t_shape[1] = new Animation();
  RuleSystem t2; 
  for (int k = 0; k <3; k++) {
    t2 = new RuleSystem(18+2*k, 2, "X", 4, 5, 0.025);
    t2.rules.add(new rule('X', "F[+*|X]F[-/&F][-/|X][-*|X][-*&X][+/|X][+/&X][+*&X]+*|X"));
    t2.rules.add(new rule('F', "FF"));
    //println("initial axiom: " + t1.axiom);
    t2.applyRules();  
    //println("final axiom: " + t1.axiom);
    t_shape[1].p.add(t2.getShape());
  }
  return t_shape;
}

/*Stablish location of some vegetation based on Trees previously created*/
InteractiveFrame[] setupVegetation(Animation[] t_shape) {
  InteractiveFrame[] iFrames = new InteractiveFrame[20];
  for (int i = 0; i < iFrames.length; i++) {
    iFrames[i] = new InteractiveFrame(scene);
    //iFrames[i].setGrabsInputThreshold(scene.radius()/4, true);
    iFrames[i].scale(6);
  }  
  int x_c = 150; 
  int y_c = 150; 
  int dif = 50;
  iFrames[0].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[1].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[2].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[3].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = (int) r_world.x() - 150; 
  y_c = 150;
  iFrames[4].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[5].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[6].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[7].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = 150; 
  y_c = (int) r_world.z() - 150;
  iFrames[8].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[9].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[10].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[11].translate(new Vec(x_c, r_world.y(), y_c - dif));
  x_c = (int) r_world.x() - 150; 
  y_c = (int) r_world.z() - 150;
  iFrames[12].translate(new Vec(x_c + dif, r_world.y(), y_c));
  iFrames[13].translate(new Vec(x_c - dif, r_world.y(), y_c));
  iFrames[14].translate(new Vec(x_c, r_world.y(), y_c + dif));
  iFrames[15].translate(new Vec(x_c, r_world.y(), y_c - dif));
  iFrames[16].translate(new Vec(r_world.x()/2 + dif, r_world.y(), r_world.z()/2));
  iFrames[17].translate(new Vec(r_world.x()/2 - dif, r_world.y(), r_world.z()/2));
  iFrames[18].translate(new Vec(r_world.x()/2, r_world.y(), r_world.z()/2 + dif));
  iFrames[19].translate(new Vec(r_world.x()/2, r_world.y(), r_world.z()/2 - dif));

  return iFrames;
}

void setupScene(Scene scene) {
  scene.setAxesVisualHint(false);
  scene.setGridVisualHint(false);
  scene.setCameraType(Camera.Type.ORTHOGRAPHIC);
  scene.setBoundingBox(new Vec(0, 0, 0), r_world);
  scene.showAll();
  scene.enableMotionAgent();
  scene.enableKeyboardAgent();
}

void setup() {  
  size(800, 600, renderer);
  textureWrap(REPEAT);  
  scene = new Scene(this);  
  /*Disable Events while setting up the environment*/
  scene.mouseAgent().setPickingMode(MouseAgent.PickingMode.CLICK);
  scene.disableMouseAgent();
  scene.disableMotionAgent();

  t_shape = createVegetation();
  iFrames = setupVegetation(t_shape);
  //Define some scene properties
  preloadMorphology();
  setupScene(scene);
  for(int i = 0; i < 20; i++){
    scale_factor = randomGaussian()*0.02 + 0.06;
    createFishGroup((int)random(10,15));
  }
  
  addEnemies();
  bg = loadImage("background/1.jpeg" );
  bg.resize(800, 600);
  /*Enable Events when finishing setting up the environment*/
  scene.enableMouseAgent();
  scene.enableMotionAgent();   
  scene.startAnimation();
}

int boid_merge_counter = 0, idx = 0;
int boid_merge_wait = 100;
void draw() { 
  background(bg);
  directionalLight(255, 255, 255, 0, 1, -500);  
  directionalLight(255, 255, 255, 0, 1, 500);
  directionalLight(255, 255, 255, 500, 1, 0);
  //directionalLight(255, 255, 255, -500, 1, 0);
  drawContainer();
  //trees
  for (int i = 0; i < iFrames.length; i++) {
    pushMatrix();
    iFrames[i].applyTransformation();//very efficient
      //scene.drawAxes(20);
      t_shape[0].draw();
    popMatrix();
  } 
  triggered = scene.timer().trigggered();
  //fish
  for (int i = 0; i < flock.size(); i++) {
    if (!pause) { 
      flock.get(i).run();
    }
    flock.get(i).render();
  }
  if (!pause)boid_merge_counter = (boid_merge_counter + 1) % boid_merge_wait;
  if(boid_merge_counter == boid_merge_wait - 1){
    for(int i = 0; i < 10; i++){
      if(idx < agents.size()/2) agents.get(idx++).run(); 
      else idx = 0;
    }
  }
  if (inThirdPerson && scene.avatar()==null) {
    inThirdPerson = false;
    adjustFrameRate();
  } else if (!inThirdPerson && scene.avatar()!=null) {
    inThirdPerson = true;
    adjustFrameRate();
  }
  
}

void adjustFrameRate() {
  if (scene.avatar() != null)
    frameRate(1000/scene.animationPeriod());
  else
    frameRate(60);
  if (scene.animationStarted())
    scene.restartAnimation();
}


//create fish group
void createFishGroup(int num) {
  Fish a = new Fish(id++);
  last_texture = applyTuringMorph(true, false, a);
  PShape fish = applyDeformation(a);
  for (int i = 0; i < num; i++) {
    ArrayList<Boid> boids = new ArrayList<Boid>();
    Fish agent = new Fish(id++);
    agent.c1 = a .c1;    agent.c2 = a.c2;
    agent.Da = a.Da;     agent.Db = a.Db; 
    agent.pa = a.pa;     agent.pb = a.pb;
    agent.h = a.h;       agent.w = a.w; 
    agent.l = a.l;       agent.base_model = a.base_model;
    Boid b = generateBoid((int)random(0, r_world.x() - 100), (int)random(0, r_world.y() - 100), (int)random(0, r_world.z() - 100), fish, agent);    
    agent.boid = b;
    boids.add(b);
    flock.add(b);
    b.boids = boids;
    agent.updateVision();
    agents.add(agent);
    population.add(agent);
  }
}

void drawContainer() {
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

void addEnemies() {
  //When a fish is more than twice times bigger another, then consider it a Prey  
  for (Fish ag : agents) {
    for (Fish ag2 : agents) {
      if (ag == ag2) continue;
      if (ag.h < 0.6*ag2.h || ag.w < 0.6*ag2.w || ag.l < 0.6*ag2.l) {
        ag.boid.predators.add(ag2.boid);
        ag2.boid.preys.add(ag.boid);
      }
    }
  }
}

boolean pause = false;
void keyPressed() {
  switch (key) {
  case 'g':
    /*Lock this thread in case, any other want to access to the data*/
    synchronized(this){
      executeGA();
    }
    break;
  case 't':
    scene.shiftTimers();
    break;
  case 'p':
    println("Frame rate: " + frameRate);
    pause = !pause;
    break;
  case '+':
    scene.setAnimationPeriod(scene.animationPeriod()-2, false);
    adjustFrameRate();
    break;
  case '-':
    scene.setAnimationPeriod(scene.animationPeriod()+2, false);
    adjustFrameRate();
    break;
  case ' ':
    if ( scene.avatar() == null && lastAvatar != null)
      scene.setAvatar(lastAvatar);
    else
      lastAvatar = scene.resetAvatar();
    break;
  }
}