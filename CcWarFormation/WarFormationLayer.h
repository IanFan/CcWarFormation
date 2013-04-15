//
//  WarFormationLayer.h
//  CcWarFormation
//
//  Created by Ian Fan on 21/03/13.
//
//

#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "CPDebugLayer.h"
#import "RobotFighter.h"

@interface WarFormationLayer : CCLayer
{
  ChipmunkSpace *_space;
  ChipmunkMultiGrab *_multiGrab;
  
  RobotFighter *_robotFighter;
}

+(CCScene *) scene;

@end
