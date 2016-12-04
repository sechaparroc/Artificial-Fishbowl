/*Flock adapted version of Matt Wetmore and Jean Pierre Charalambos*/
class Boid{
  InteractiveFrame f;
  Quat q;
  
  PShape s;
  PVector pos;
  PVector vel;
  PVector acc;
  PVector ali, coh, sep;
  float radius; //num of neighbors
  PVector min_coords;
  PVector max_coords;
  float maxSpeed = 5;
  float maxSteerForce = .1f;
  float flap = 0;
  float t = 0;
  ArrayList<Boid> boids;
  ArrayList<Boid> predators;  
  ArrayList<Boid> preys;  
  float w_a, w_c, w_s, w_m;
  float x_seed, y_seed, z_seed; //used to random walk with perlin noise
  
  
  public Boid(PVector ipos){
    pos = new PVector(ipos.x, ipos.y, ipos.z);
    //TO DO ADD FRAME AND SHAPE CONFS
    vel = new PVector(random(-maxSpeed,maxSpeed),random(-maxSpeed,maxSpeed),random(-maxSpeed,maxSpeed));
    acc = new PVector(0,0,0);
    radius = 100;
    w_c = 3;//random(1,3); 
    w_s = 1;//random(1,3);
    w_a = 1.;//random(1,3);
    w_m = 0.01;//random(0,2);
    x_seed = random(0,1000);
    y_seed = random(3000, 4000);
    z_seed = random(7000, 8000);
    min_coords = pos.get();
    max_coords = pos.get();
    predators = new ArrayList<Boid>();
    preys = new ArrayList<Boid>();
    maxSpeed = 5 - 2*scale_factor;
}
  
  public Boid(PVector ipos, PVector ivel, float r){
    pos = new PVector(ipos.x, ipos.y, ipos.z);
    //TO DO ADD FRAME AND SHAPE CONFS
    vel = new PVector(ivel.x, ivel.y, ivel.z);
    acc = new PVector(0,0,0);
    predators = new ArrayList<Boid>();
    preys = new ArrayList<Boid>();    
    radius = r;
    maxSpeed = 5 - 2*scale_factor;
  }

  void run(){
    t += .1;
    flap = 10 * sin(t);
    avoidWalls();
    avoidPredators();
    followPreys();
    flock(boids); 
    move();
  }
  
  void avoidWalls(){
    float w = w_c + w_s + w_a + w_m;
    w = w + .9*w;
    acc.add(PVector.mult(avoid(new PVector(pos.x,        r_world.y(), pos.z),       true), w));
    acc.add(PVector.mult(avoid(new PVector(pos.x,        0,           pos.z),       true), w));
    acc.add(PVector.mult(avoid(new PVector(r_world.x(),  pos.y,       pos.z),       true), w));
    acc.add(PVector.mult(avoid(new PVector(0,            pos.y,       pos.z),       true), w));
    acc.add(PVector.mult(avoid(new PVector(pos.x,        pos.y,       0),           true), w));
    acc.add(PVector.mult(avoid(new PVector(pos.x,        pos.y,       r_world.z()), true), w));
  }
  
  void avoidPredators(){
    float w = w_c + w_s + w_a + w_m;
    w = w + .6*w;
    //avoid the nearest
    Boid n = null;
    for(Boid b : predators){
      if(n == null) n = b;
      if(b.pos.dist(pos) < pos.dist(n.pos)) n = b;
    }
    if(n != null)acc.add(PVector.mult(avoid(n.pos,       true), w));
  }
  
  void followPreys(){
    float w = w_c + w_s + w_a + w_m;
    w = w + .4*w;
    Boid n = null;
    for(Boid b : preys){
      //follow the nearest
      if(n == null) n = b;
      if(b.pos.dist(pos) < pos.dist(n.pos)) n = b;
    }  
    if(n != null)acc.add(PVector.mult(avoid(n.pos,       true), -1*w));
  }
  
  PVector avoid(PVector target, boolean weight){
    PVector steer = PVector.sub(pos, target);  
    if(weight){
      steer.mult(1/sq(PVector.dist(pos,target)));
    }
    return steer;
  }

  void flock(ArrayList<Boid> bl){
    ali = alignment(bl);
    coh = cohesion(bl);
    sep = separation(bl);
    acc.add(PVector.mult(ali,w_a));    
    acc.add(PVector.mult(coh,w_c));    
    acc.add(PVector.mult(sep,w_s));    
  }
  
  void move(){
    acc.add(PVector.mult(myMovement(), w_m));
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    f.setPosition(new Vec(pos.x, pos.y, pos.z));
    acc.mult(0);
  }
  
  // steering. If arrival==true, the boid slows to meet the target. Credit to
  // Craig Reynolds
  PVector steer(PVector target, boolean arrival) {
    PVector steer = new PVector(); // creates vector for steering
    if (!arrival) {
      steer.set(PVector.sub(target, pos)); // steering vector points
      // towards target (switch target and pos for avoiding)
      steer.limit(maxSteerForce); 
      // maxSteerForce
    } 
    else {
      PVector targetOffset = PVector.sub(target, pos);
      float distance = targetOffset.mag();
      float rampedSpeed = maxSpeed * (distance / 100);
      float clippedSpeed = min(rampedSpeed, maxSpeed);
      PVector desiredVelocity = PVector.mult(targetOffset,
      (clippedSpeed / distance));
      steer.set(PVector.sub(desiredVelocity, vel));
    }
    return steer;
  }

  PVector separation(ArrayList boids) {
    PVector posSum = new PVector(0, 0, 0);
    PVector repulse;
    for (int i = 0; i < boids.size(); i++) {
      Boid b = (Boid) boids.get(i);
      if(b == this) continue;
      float d = PVector.dist(pos, b.pos);
      if (d > 0 && d <= radius) {
        repulse = PVector.sub(pos, b.pos);
        repulse.normalize();
        repulse.div(d);
        posSum.add(repulse);
      }
    }
    return posSum;
  }
  
  PVector alignment(ArrayList boids) {
    PVector velSum = new PVector(0, 0, 0);
    int count = 0;
    for (int i = 0; i < boids.size(); i++) {
      Boid b = (Boid) boids.get(i);
      if(b == this) continue;      
      float d = PVector.dist(pos, b.pos);
      if (d > 0 && d <= radius) {
        velSum.add(b.vel);
        count++;
      }
    }
    if (count > 0) {
      velSum.div((float) count);
      velSum.limit(maxSteerForce);
    }
    return velSum;
  }

  PVector cohesion(ArrayList boids) {
    PVector posSum = new PVector(0, 0, 0);
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    for (int i = 0; i < boids.size(); i++) {
      Boid b = (Boid) boids.get(i);
      if(b == this) continue;      
      float d = dist(pos.x, pos.y, b.pos.x, b.pos.y);
      if (d > 0 && d <= radius) {
        posSum.add(b.pos);
        count++;
      }
    }
    if (count > 0) {
      posSum.div((float) count);
      steer = PVector.sub(posSum, pos);
      steer.limit(maxSteerForce);      
    }
    return steer;
  }
  
  //follow a perlin noise movement
  PVector myMovement(){
    float x = noise(x_seed);
    x = map(x,0,1,-1,1);
    x_seed += 0.01;
    float y = noise(y_seed);
    y_seed += 0.01;
    y = map(y,0,1,-1,1);
    float z = noise(z_seed);
    z_seed += 0.01;
    z = map(z,0,1,-1,1);    
    return new PVector(x,y,z);
  }
  
  public void updateCoords(){
    min_coords = pos.get();
    max_coords = pos.get();    
    for (int i = 0; i < boids.size(); i++) {
      Boid b = (Boid) boids.get(i);      
      if(b.pos.x < min_coords.x) min_coords.x = b.pos.x; 
      if(b.pos.y < min_coords.y) min_coords.y = b.pos.y; 
      if(b.pos.z < min_coords.z) min_coords.z = b.pos.z;       
      if(b.pos.x > max_coords.x) max_coords.x = b.pos.x; 
      if(b.pos.y > max_coords.y) max_coords.y = b.pos.y; 
      if(b.pos.z > max_coords.z) max_coords.z = b.pos.z;       

    }  
  }
  
  
  
  void render() {
    /*Basically is doing a rotation in 2 steps:
     1 - align to X axis rotating the frame according to axis Y and the angle btwn X & Z
     2 - align to Y axis rotating the frame according to axis Z and the angle btwn Vec & Y     
    */
    q = Quat.multiply(new Quat( new Vec(0,1,0),  atan2(-vel.z, vel.x)), 
                      new Quat( new Vec(0,0,1),  asin(vel.y / vel.mag())) );    
    f.setRotation(q);

    // Multiply matrix to get in the frame coordinate system.
    pushMatrix();
    f.applyTransformation();
    shape(s);
    popMatrix();
  }
  
}
