//
//  RobotFighter.h
//  RobotFighter
//
//  Created by Ian Fan on 14/03/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ObjectiveChipmunk.h"

#pragma mark - ROBOT_FIGHTER_UNIT

@protocol RobotFighterUnitDelegate;

@interface RobotFighterUnit : NSObject
{
  CCLayer *_parentLayer;
  ChipmunkSpace *_parentSpace;
  
  CCLabelTTF *_hpLabel;
  int _attackTimeStack;
  
  float _fullMass;
}

//general
@property (nonatomic,assign) id <RobotFighterUnitDelegate> robotFighterUnitDelegate;
@property int tag;

//Sprite
@property (nonatomic,retain) CCSprite *sprite;

//Chipmunk
@property (nonatomic,retain) ChipmunkBody *chipmunkBody;
@property (nonatomic,retain) ChipmunkShape *chipmunkShape;
@property (nonatomic,retain) NSArray *chipmunkObjects;
@property int touchedShapes;

//Fighter
@property int hp;
@property float speed;
@property int attack;
@property int attackTime;
@property CGPoint targetPoint;
@property (nonatomic,assign) RobotFighterUnit *attackUnit;

-(void)setupSpriteWithParentLayer:(CCLayer*)parentL pngName:(NSString*)pngName;//sprite
-(void)setupChipmunkObjectsWithParentSpace:(ChipmunkSpace*)parentSp IsCircleNotSquare:(BOOL)isCircleNotSquare mass:(float)mas width:(float)width height:(float)height position:(CGPoint)pos elasticity:(float)elas friction:(float)fric collisionType:(NSString*)colliType;//chipmunk
-(void)setupFighterWithHp:(int)hp speed:(float)speed sight:(float)sight attack:(int)attack attackTime:(int)attackTime;//fighter
-(void)update;

//Attack
-(void)changeHpWithEditAmount:(int)editAmount;
@end

#pragma mark - ROBOT_FIGHTER_UNIT_DELEGATE

@protocol RobotFighterUnitDelegate <NSObject>
@optional
-(void)robotFighterUnitDelegateHpZeroWithUnit:(RobotFighterUnit*)unit;
@end

#pragma mark - ROBOT_FIGHTER

@interface RobotFighter : NSObject <RobotFighterUnitDelegate>
@property (nonatomic,retain) NSMutableArray *robotFighterUnitArray;
@property (nonatomic,assign) RobotFighterUnit *touchedUnit;
@property CGPoint touchingPoint;

-(void)update;
-(void)addUnit:(RobotFighterUnit*)unit;

//TouchEvent
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

//CollisionEvent
-(BOOL)beginCollision:(cpArbiter *)arbiter space:(ChipmunkSpace *)space;
-(void)separateCollision:(cpArbiter *)arbiter space:(ChipmunkSpace *)space;
-(void)collisionWithUnit1:(RobotFighterUnit*)unit1 unit2:(RobotFighterUnit*)unit2;
-(void)separationWithUnit1:(RobotFighterUnit*)unit1 unit2:(RobotFighterUnit*)unit2;

//Info
-(RobotFighterUnit*)returnUnitWithChipmunkBody:(ChipmunkBody*)body;

//Draw
-(void)draw;

@end
