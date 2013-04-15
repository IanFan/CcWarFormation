//
//  RobotFighter.m
//  RobotFighter
//
//  Created by Ian Fan on 14/03/13.
//
//

#import "RobotFighter.h"

#pragma mark - ROBOT_FIGHTER_UNIT

@implementation RobotFighterUnit
@synthesize sprite=_sprite;
@synthesize chipmunkObjects=_chipmunkObjects, chipmunkBody=_chipmunkBody, chipmunkShape=_chipmunkShape, touchedShapes=_touchedShapes;
@synthesize hp=_hp, speed=_speed, attack=_attack, attackTime=_attackTime, targetPoint=_targetPoint, attackUnit=_attackUnit;

#pragma mark - Attack

-(void)changeHpWithEditAmount:(int)editAmount {
  _hp = MAX(_hp + editAmount, 0) ;
  
  [self updateMassAndHpLabel];
  
  if (_hp <= 0) {
    //can not do anything
    
    //can not attack
    _attackUnit = nil;
    
    //delegate dont hit me any more!!
    if ([self.robotFighterUnitDelegate respondsToSelector:@selector(robotFighterUnitDelegateHpZeroWithUnit:)] == YES) {
      [self.robotFighterUnitDelegate robotFighterUnitDelegateHpZeroWithUnit:self];
    }
  }
}

#pragma mark - Update

-(void)update {
  if (_hp > 0) {
    [self updateBehaviour];
    [self updateAttackTime];
  }
  
  [self updateSprite];
  [self updateHpLabelPosition];
}

-(void)updateSprite {
  if (_sprite != nil) {
    _sprite.position = _chipmunkBody.pos;
    _sprite.rotation = -CC_RADIANS_TO_DEGREES(_chipmunkBody.angle);
  }
}

-(void)updateMassAndHpLabel {
  if (_chipmunkBody != nil) {
    _chipmunkBody.mass = MAX((float)0.01*_fullMass*_hp, (float)0.01*_fullMass);
  }
  
  if (_hpLabel != nil) {
    _hpLabel.string = [NSString stringWithFormat:@"%d",_hp];
  }
}

-(void)updateHpLabelPosition {
  if (_hpLabel != nil && _sprite != nil) {
    _hpLabel.position = _sprite.position;
  }
}

-(void)updateBehaviour {
  if (_targetPoint.x != 0 && _targetPoint.y != 0) {
    [self seek];
  }
}

-(void)seek {
  ChipmunkBody *mainBody = _chipmunkBody;
  CGPoint mainPos = _chipmunkBody.pos;
  CGPoint targetPoint = _targetPoint;
  float maxSpeed = _speed;
  float steeringForceEffect = 0.2;
  if (self.attackUnit != nil) {
    steeringForceEffect *= 0.2;
    maxSpeed *= 0.2;
  }
  
  float slowingDistance = 30;
  float mainToTargetDis = ccpDistance(mainPos, targetPoint);
  float mainAngle = _chipmunkBody.angle;
  
  //stop
  if (mainToTargetDis < 10) {
    _targetPoint = ccp(0, 0);
  }
  
  CGPoint direction = ccpNormalize(ccp(cosf(mainAngle),sinf(mainAngle)));
  CGPoint velocity = ccpMult(direction, maxSpeed);
  
  CGPoint desiredDirection = ccpNormalize(ccpSub(targetPoint, mainPos));
  CGPoint desiredVelocity = ccpMult(desiredDirection, maxSpeed);
  
  //avoid unable to turn due to exactly opposite direction
  if (direction.x == -desiredDirection.x && direction.y == -desiredDirection.y) {
    NSLog(@"adjust a little direction");
    direction = ccpNormalize(ccp(cosf(mainAngle+0.001),sinf(mainAngle+0.001)));
    velocity = ccpMult(direction, maxSpeed);
  }
  
  //slowing
  if (mainToTargetDis <= slowingDistance) {
    desiredVelocity = ccpMult(desiredDirection, mainToTargetDis/slowingDistance);
  }
  
  CGPoint steeringForce = ccpSub(desiredVelocity, velocity);
  steeringForce = ccpMult(steeringForce, steeringForceEffect);
  
  velocity = ccpAdd(velocity, steeringForce);
  if (mainToTargetDis <= slowingDistance) velocity = ccpMult(velocity, mainToTargetDis/slowingDistance);
  
  //new position and angle
  mainBody.angle = ccpToAngle(velocity);
  mainBody.pos = ccpAdd(mainPos, velocity);
}

-(void)updateAttackTime {
  if (_attackTimeStack < _attackTime) _attackTimeStack ++;
  else if (_attackUnit != nil) {
    [_attackUnit changeHpWithEditAmount:-_attack];
    _attackTimeStack = 0;
  }
}

#pragma mark - SetupSprite

-(void)setupSpriteWithParentLayer:(CCLayer *)parentL pngName:(NSString *)pngName {
  _parentLayer = parentL;
  
  self.sprite = [CCSprite spriteWithFile:pngName];
  [_parentLayer addChild:_sprite];
}

#pragma mark - Chipmunk

-(void)setupChipmunkObjectsWithParentSpace:(ChipmunkSpace *)parentSp IsCircleNotSquare:(BOOL)isCircleNotSquare mass:(float)mas width:(float)width height:(float)height position:(CGPoint)pos elasticity:(float)elas friction:(float)fric collisionType:(NSString *)colliType {
  _parentSpace = parentSp;
  _fullMass = mas;
  
  if (isCircleNotSquare == YES) {
    cpFloat moment = cpMomentForCircle(mas, 0, height, cpv(0.0f, 0.0f));
    self.chipmunkBody = [ChipmunkBody bodyWithMass:mas andMoment:moment];
    self.chipmunkShape = [ChipmunkCircleShape circleWithBody:_chipmunkBody radius:(0.5*width) offset:CGPointMake(0, 0)];
  }else {
    cpFloat moment = cpMomentForBox(mas, 0, height);
    self.chipmunkBody = [ChipmunkBody bodyWithMass:mas andMoment:moment];
    self.chipmunkShape = [ChipmunkPolyShape boxWithBody:_chipmunkBody width:width height:height];
  }
  
  [_chipmunkBody setPos:pos];
  [_chipmunkShape setElasticity:elas];
  [_chipmunkShape setFriction:fric];
  [_chipmunkShape setCollisionType:colliType];
  [_chipmunkShape setData:self];
  
  self.chipmunkObjects = [NSArray arrayWithObjects:_chipmunkBody,_chipmunkShape, nil];
  [_parentSpace add:_chipmunkObjects];
  
  if (_sprite != nil) {
    _sprite.position = pos;
    _sprite.scale = width/self.sprite.boundingBox.size.width;
  }

}

#pragma mark - Fighter

-(void)setupFighterWithHp:(int)hp speed:(float)speed sight:(float)sight attack:(int)attack attackTime:(int)attackTime {
  _hp = hp;
  _speed = speed;
  _attack = attack;
  _attackTime = attackTime;
  _attackTimeStack = attackTime;
  
  if (_sprite != nil) {
    _hpLabel = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica" fontSize:MAX(MIN(22,16*_sprite.scale),12)];
    [_parentLayer addChild:_hpLabel];
    _hpLabel.scale = _sprite.scale;
    [self updateMassAndHpLabel];
    [self updateHpLabelPosition];
  }
}

#pragma mark - Init

-(id)init {
  if ((self = [super init])) {
  }
  return self;
}

-(void)dealloc {
  self.robotFighterUnitDelegate = nil;
  if (_sprite != nil) [_parentLayer removeChild:_sprite cleanup:YES], self.sprite=nil;
  if (_hpLabel != nil) [_parentLayer removeChild:_hpLabel cleanup:YES];
  
  self.chipmunkBody = nil;
  self.chipmunkShape = nil;
  self.chipmunkObjects = nil;
  
  [super dealloc];
}

@end

#pragma mark - ROBOT_FIGHTER

@implementation RobotFighter
@synthesize robotFighterUnitArray=_robotFighterUnitArray, touchedUnit=_touchedUnit, touchingPoint=_touchingPoint;

#pragma mark - RobotFighterDelegate

-(void)robotFighterUnitDelegateHpZeroWithUnit:(RobotFighterUnit *)unit {
  for (RobotFighterUnit *uni in _robotFighterUnitArray) {
    if (uni.attackUnit == unit) {
      uni.attackUnit = nil;
    }
  }
  
}

#pragma mark - Info

-(RobotFighterUnit*)returnUnitWithChipmunkBody:(ChipmunkBody *)body {
  RobotFighterUnit *targetUnit = nil;
  for (RobotFighterUnit *unit in _robotFighterUnitArray) {
    if (body == unit.chipmunkBody) {
      targetUnit = unit;
      break;
    }
  }
  
  return targetUnit;
}

-(void)draw {
  if ( (_touchedUnit != nil && _touchedUnit.hp > 0) && (_touchingPoint.x != 0 && _touchingPoint.y != 0) ) {
  glLineWidth(4.0f);
  ccDrawColor4F(.42, 0.56, 0.14, 1.0);
  ccDrawLine(_touchedUnit.sprite.position, _touchingPoint);
  }
}

#pragma  mark - Collision

-(BOOL)beginCollision:(cpArbiter *)arbiter space:(ChipmunkSpace *)space {
  CHIPMUNK_ARBITER_GET_SHAPES(arbiter, shape1, shape2);
  
  RobotFighterUnit *unit1 = shape1.data;
  RobotFighterUnit *unit2 = shape2.data;
  
  [self collisionWithUnit1:unit1 unit2:unit2];
  
  return TRUE;
}

-(void)separateCollision:(cpArbiter *)arbiter space:(ChipmunkSpace *)space {
  CHIPMUNK_ARBITER_GET_SHAPES(arbiter, shape1, shape2);
  
  RobotFighterUnit *unit1 = shape1.data;
  RobotFighterUnit *unit2 = shape2.data;
  
  [self separationWithUnit1:unit1 unit2:unit2];
}

-(void)collisionWithUnit1:(RobotFighterUnit*)unit1 unit2:(RobotFighterUnit*)unit2 {
  if (unit1.hp > 0) {
    if (unit1.attackUnit == nil && unit2.hp > 0) unit1.attackUnit = unit2;
  }else {
    unit1.attackUnit = nil;
  }
  
  if (unit2.hp > 0) {
    if (unit2.attackUnit == nil && unit1.hp > 0) unit2.attackUnit = unit1;
  }else {
    unit2.attackUnit = nil;
  }
  
  unit1.touchedShapes ++;
  unit2.touchedShapes ++;
}

-(void)separationWithUnit1:(RobotFighterUnit *)unit1 unit2:(RobotFighterUnit *)unit2 {
  if (unit1.attackUnit == unit2) unit1.attackUnit = nil;
  if (unit2.attackUnit == unit1) unit2.attackUnit = nil;
  
  unit1.touchedShapes --;
  unit2.touchedShapes --;
}

#pragma mark - TouchEvent

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [self beginLocation:point];
  }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [self updateLocation:point];
  }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [self endLocation:point];
  }
}

-(void)beginLocation:(CGPoint)point {
  for (RobotFighterUnit *unit in _robotFighterUnitArray) {
    float oldDisSQ;
    float newDisSQ = ccpDistanceSQ(unit.sprite.position, point);
    float detectDis = 0.5*unit.sprite.boundingBox.size.width;
    if (newDisSQ <= detectDis*detectDis) {
      NSLog(@"inside");
      if (_touchedUnit == nil || newDisSQ < oldDisSQ) {
        _touchedUnit = unit;
        oldDisSQ = newDisSQ;
      }
    }
  }
  
}

-(void)updateLocation:(CGPoint)point {
  _touchingPoint = point;
}

-(void)endLocation:(CGPoint)point {
  _touchingPoint = CGPointZero;
  
  if (_touchedUnit != nil) {
    _touchedUnit.targetPoint = point;
    NSLog(@"point = %f,%f",point.x,point.y);
  }
  
  _touchedUnit = nil;
}

#pragma mark - Update

-(void)update {
  for (RobotFighterUnit *unit in _robotFighterUnitArray) {
    [self updateDetectNearbyEnemy];
    
    [unit update];
  }
}

-(void)updateDetectNearbyEnemy {
  
}

#pragma mark - AddUnit

-(void)addUnit:(RobotFighterUnit *)unit {
  if ([_robotFighterUnitArray containsObject:unit] == NO) {
    [_robotFighterUnitArray addObject:unit];
  }
}

#pragma mark - Setup

-(void)setupRobotFighterunitArray {
  if (_robotFighterUnitArray != nil) [_robotFighterUnitArray removeAllObjects];
  self.robotFighterUnitArray = [[NSMutableArray alloc]init];
}

#pragma mark - Init

-(id)init {
  if ((self = [super init])) {
    [self setupRobotFighterunitArray];
  }
  return self;
}

-(void)dealloc {
  [super dealloc];
}

@end
