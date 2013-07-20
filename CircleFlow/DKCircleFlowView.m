//
//  DKCircleFlowView.m
//  CircleFlow
//
//  Created by CHIEN-MING LEE on 8/2/12.
//  Copyright (c) 2012 CHIEN-MING LEE. All rights reserved.
//

#import "DKCircleFlowView.h"

#define DISTNACE_TO_MAKE_MOVE_FOR_SWIPE 70

@interface DKFlowUnitLayer : CALayer
@property (nonatomic, strong) CALayer *contentLayer;
@property (nonatomic) NSInteger unitIndex;//used to recoginze the which layer is
@property (nonatomic) NSInteger flowIndex;//used to indetify current user choosen index
-(void)setContentImage:(CGImageRef)imgref withSize:(CGRect)aSize;
-(void)setContentImage:(CGImageRef)imgref;
-(void)setContentSize:(CGRect)aSize;
@end

@implementation DKFlowUnitLayer
@synthesize contentLayer, unitIndex, flowIndex;
-(void)dealloc
{
    [contentLayer release];
    [super dealloc];
}
-(id)initWithFrame:(CGRect)aFrame
{
    self = [super init];
    if (self) {
        //setup property here//
        contentLayer = [[CALayer alloc] init];
        contentLayer.frame = CGRectZero;
        [self addSublayer:contentLayer];
    }
    return self;
}

-(void)setContentImage:(CGImageRef)imgref withSize:(CGRect)aSize
{
    [self setContentImage:imgref];
    [self setContentSize:aSize];
}

-(void)setContentImage:(CGImageRef)imgref
{
    self.contentLayer.contents = (id)imgref;
}

-(void)setContentSize:(CGRect)aSize
{
    self.contentLayer.frame = aSize;
}
@end

/////////////DKCircleFlowView implemetation start here///////////////////////////
@interface DKCircleFlowView()
@property (nonatomic, strong) NSMutableArray *flowUnitArray;
@property (nonatomic) NSInteger maxFlowCount;// cover flow 的總數量
@property (nonatomic) NSInteger centerFlowIndex;// 目前置中的flow index 為何？
@property (nonatomic) NSInteger mostRightIndex;// 最右的 index
@property (nonatomic) NSInteger mostLeftIndex;// 最左的 index
@property (nonatomic) BOOL isFirstInitialization;
-(DKFlowUnitLayer *)createUnit;
-(CATransform3D)getTransformByIndex:(NSInteger)anIndex;
-(NSInteger)getZPositionByIndex:(NSInteger)anIndex;
-(CGPoint)getPositionByIndex:(NSInteger)anIndex;
-(void)handleGesture:(UIPanGestureRecognizer *)recognizer;
-(void)handleTapGesture:(UITapGestureRecognizer *)recognizer;
-(NSInteger)nextFlowIndex:(DKFlowUnitLayer *)aLayer withLeft:(BOOL)toLeftDirection;
-(void)addStepsToReferenceIndex:(NSInteger)aStep;
-(void)setUnitLayer:(DKFlowUnitLayer *)anUnitLayer transformedByIndex:(NSInteger)anUnitIdx;
-(void)moveOneStep:(BOOL)toLeftDirection;
@end

@implementation DKCircleFlowView
@synthesize delegate;
@synthesize flowUnitArray;
@synthesize maxFlowCount;
@synthesize centerFlowIndex, mostLeftIndex, mostRightIndex;
@synthesize isFirstInitialization;
#pragma mark - Memory Management
-(void)dealloc
{
    [flowUnitArray removeAllObjects];
    [flowUnitArray release];
    [super dealloc];
}
#pragma mark - Initialization
-(DKFlowUnitLayer *)createUnit
{
    DKFlowUnitLayer *unitLayer = [[[DKFlowUnitLayer alloc] initWithFrame:CGRectZero] autorelease];
    unitLayer.anchorPoint = CGPointMake(0.5f, 1.0f);
    unitLayer.zPosition = 0;
    return unitLayer;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor greenColor];
        
        mostLeftIndex = 4;
        centerFlowIndex = 0;
        mostRightIndex = -4;
        
        isFirstInitialization = YES;
        
        flowUnitArray = [[NSMutableArray alloc] initWithCapacity:12];
        
        //set up perspective
        CATransform3D transformPerspective = CATransform3DIdentity;
        transformPerspective.m34 = -1.0 / 500.0;
        self.layer.sublayerTransform = transformPerspective;
        
        for (int i = 0; i < 9; i++) {
            DKFlowUnitLayer *aUnit = [self createUnit];
            aUnit.zPosition = [self getZPositionByIndex:i];
            aUnit.unitIndex = i;
            aUnit.flowIndex = (4 - i); //因為 centerFlowIndex 為 0, 所以利用此演算方式來決定起始的 flow index
            [flowUnitArray addObject:aUnit];
        }
        
        for (DKFlowUnitLayer *aLayer in flowUnitArray) {
            aLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width/2, self.bounds.size.height*2);
            aLayer.position = [self getPositionByIndex:aLayer.unitIndex];
            CATransform3D transform = [self getTransformByIndex:aLayer.unitIndex];
            aLayer.transform = transform;
#warning THE CONTENT SIZE IS DEFINE AT FIXED RECT SIZE   160X180
            [aLayer setContentSize:CGRectMake(0.0f, 0.0f, 160.0f, 180.0f)];
            [self.layer addSublayer:aLayer];
        }
        
        //register the pan gesture to figure out whether user has intention to move to next/previous image
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self addGestureRecognizer:gestureRecognizer];
        [gestureRecognizer release];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGesture];
        [tapGesture release];
    }
    return self;
}
#pragma mark - Custom Methods
-(void)reloadData
{
    [flowUnitArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DKFlowUnitLayer *flowLayer = (DKFlowUnitLayer *)obj;
        if ([self.delegate respondsToSelector:@selector(flowImageAtIndex:)]) {
            if (flowLayer.flowIndex >=0 && flowLayer.flowIndex < self.maxFlowCount) {
                [flowLayer setContentImage:[self.delegate flowImageAtIndex:flowLayer.flowIndex].CGImage];
                [flowLayer setNeedsDisplay];
            }
        }
    }];
}
#pragma mark - Private Methods
-(CATransform3D)getTransformByIndex:(NSInteger)anIndex
{
    CATransform3D flowTransform = CATransform3DIdentity;
    
    ///Unit Index 0 與 1 時，為同樣的變形(transform), 並直接回傳 flowTransform///
    if (anIndex == 0) {
        anIndex = anIndex + 1;
        CATransform3D yLeftSideRotation = CATransform3DMakeRotation(0.04f, 0.0f, 1.0f, 0.0f);
        CATransform3D zLeftSideRotation = CATransform3DMakeRotation((M_PI/4)*(anIndex - 4)/4, 0.0f, 0.0f, 1.0f);
        CATransform3D scaleTransform = CATransform3DMakeScale(1 - ((4 - anIndex)*0.188), 1- ((4 - anIndex)*0.188), 1.0f);
        flowTransform = CATransform3DConcat(CATransform3DConcat(yLeftSideRotation, zLeftSideRotation), scaleTransform);
        return flowTransform;
    }
    
    ///Unit Index 7 與 8 時，為同樣的變形(transform), 並直接回傳 flowTransform///
    if (anIndex == 8) {
        anIndex = anIndex -1;
        CATransform3D yRightSideRotation = CATransform3DMakeRotation(-0.04f, 0.0f, 1.0f, 0.0f);
        CATransform3D zRightSideRotation = CATransform3DMakeRotation((M_PI/4)*(anIndex - 4)/4, 0.0f, 0.0f, 1.0f);
        CATransform3D scaleTransform = CATransform3DMakeScale(1 - ((anIndex - 4)*0.188), 1- ((anIndex - 4)*0.188), 1.0f);
        flowTransform = CATransform3DConcat(CATransform3DConcat(yRightSideRotation, zRightSideRotation), scaleTransform);
        return flowTransform;
    }
    
    //For left side//
    if (anIndex < 4) {
        CATransform3D yLeftSideRotation = CATransform3DMakeRotation(0.04f, 0.0f, 1.0f, 0.0f);
        CATransform3D zLeftSideRotation = CATransform3DMakeRotation((M_PI/4)*(anIndex - 4)/4, 0.0f, 0.0f, 1.0f);
        CATransform3D scaleTransform = CATransform3DMakeScale(1 - ((4 - anIndex)*0.188), 1- ((4 - anIndex)*0.188), 1.0f);
        flowTransform = CATransform3DConcat(CATransform3DConcat(yLeftSideRotation, zLeftSideRotation), scaleTransform);
    }
    
    //For center//
    
    //For right side//
    if (anIndex > 4) {
        CATransform3D yRightSideRotation = CATransform3DMakeRotation(-0.04f, 0.0f, 1.0f, 0.0f);
        CATransform3D zRightSideRotation = CATransform3DMakeRotation((M_PI/4)*(anIndex - 4)/4, 0.0f, 0.0f, 1.0f);
        CATransform3D scaleTransform = CATransform3DMakeScale(1 - ((anIndex - 4)*0.188), 1- ((anIndex - 4)*0.188), 1.0f);
        flowTransform = CATransform3DConcat(CATransform3DConcat(yRightSideRotation, zRightSideRotation), scaleTransform);
    }
    
    return flowTransform;
}

-(NSInteger)getZPositionByIndex:(NSInteger)anIndex
{
    NSInteger zPosition = 0;
    
    if (anIndex < 4) zPosition = anIndex*2;
    else if(anIndex > 4) zPosition = (8 - anIndex)*2;
    else if (anIndex == 4) zPosition = 8*2;
    
    return zPosition;
}

-(CGPoint)getPositionByIndex:(NSInteger)anIndex
{
    CGPoint position = CGPointZero;
    /////Unit Index 0 8, 1 7 四個採用同樣的 position, 以達到同樣的扇形效果/////
    switch (anIndex) {
        case 0:
            return CGPointMake(self.bounds.size.width/2 - 14.0f, self.bounds.size.height*1.28f);
        case 8:
            return CGPointMake(self.bounds.size.width/2 + 14.0f, self.bounds.size.height*1.28f);
            break;
        case 1:
            return CGPointMake(self.bounds.size.width/2 - 14.0f, self.bounds.size.height*1.28f);
            break;
        case 7:
            return CGPointMake(self.bounds.size.width/2 + 14.0f, self.bounds.size.height*1.28f);
            break;
        case 3:
        case 5:
            return CGPointMake(self.bounds.size.width/2, self.bounds.size.height*1.73f);
            break;
        case 2:
        case 6:
            return CGPointMake(self.bounds.size.width/2, self.bounds.size.height*1.5f);
            break;
        case 4:
            return CGPointMake(self.bounds.size.width/2, self.bounds.size.height*2.0f);
            break;
            
        default:
          return CGPointMake(self.bounds.size.width/2, self.bounds.size.height*1.9f);
            break;
    }
    
    return position;
}
////Handle the pan gesture///
- (void)handleGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged){
        //get offset
        CGPoint offset = [recognizer translationInView:recognizer.view];
        if (abs(offset.x) > DISTNACE_TO_MAKE_MOVE_FOR_SWIPE) {
            BOOL isSwipingToLeftDirection = (offset.x > 0) ? NO :YES;
            [self moveOneStep:isSwipingToLeftDirection];
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
    }
    
}
////Handle the tap gesture///
-(void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded){         
        CGPoint tapLocation = [recognizer locationInView:self];
        CGRect touchRect = CGRectMake(80.0f, 0.0f, 160.0f, 180.0f);
        ///If tap point in the define rect then trigger delegate method///
        if (CGRectContainsPoint(touchRect, tapLocation)) {
            if ([self.delegate respondsToSelector:@selector(centerPageDidTouched:atIndex:)]) {
                [self.delegate centerPageDidTouched:self atIndex:centerFlowIndex];
            }
        }
    }
}
///Return the flow index of unit layer regarding the swipe direction///
-(NSInteger)nextFlowIndex:(DKFlowUnitLayer *)aLayer withLeft:(BOOL)toLeftDirection
{
    NSInteger anIndex = aLayer.flowIndex;
    if (toLeftDirection == NO) {
        if (anIndex == mostRightIndex - 1) {
            return anIndex + 9;
        }
    }else{
        if (anIndex == mostLeftIndex + 1) {
            return anIndex - 9;
        }
    }
    
    return anIndex;
}
///add step for reference index to trace current flow condition///
-(void)addStepsToReferenceIndex:(NSInteger)aStep
{
    centerFlowIndex = centerFlowIndex + aStep;
    mostLeftIndex = mostLeftIndex + aStep;
    mostRightIndex = mostRightIndex + aStep;
}
///make unit layer be transformed by specified index(Unit Index)////
-(void)setUnitLayer:(DKFlowUnitLayer *)anUnitLayer transformedByIndex:(NSInteger)anUnitIdx
{
    anUnitLayer.position = [self getPositionByIndex:anUnitIdx];
    anUnitLayer.zPosition = [self getZPositionByIndex:anUnitIdx];
    anUnitLayer.transform = [self getTransformByIndex:anUnitIdx];
}
///Move every unit layer forward or backward one step///
-(void)moveOneStep:(BOOL)toLeftDirection
{
    if (toLeftDirection == NO) {
        ////Swipe to right seciont///
        if (centerFlowIndex == (maxFlowCount -1)) {
            return;
        }
        
        [self addStepsToReferenceIndex:1];
        
        for (DKFlowUnitLayer *unit in flowUnitArray) {
            unit.unitIndex = unit.unitIndex + 1;
            NSInteger nextIdx = [self nextFlowIndex:unit withLeft:NO];
            if (nextIdx != unit.flowIndex) {
                    unit.flowIndex = nextIdx;
                    if (nextIdx > maxFlowCount - 1) {
                        [unit setContentImage:nil];
                        [unit setNeedsDisplay];
                    }else{
                        if ([self.delegate respondsToSelector:@selector(flowImageAtIndex:)]) {
                            [unit setContentImage:[self.delegate flowImageAtIndex:nextIdx].CGImage];
                            [unit setNeedsDisplay];
                        }
                    }
            }

            if (unit.unitIndex >  8) { ///If unitIndex larger than 8, make cycling happedn with changing unitIndex back to 0//
                unit.unitIndex = 0;
                
                [CATransaction begin];
                [CATransaction setAnimationDuration:0.0f];
                [unit removeFromSuperlayer];
                [self setUnitLayer:unit transformedByIndex:unit.unitIndex];
                [self.layer addSublayer:unit];
                [CATransaction commit];
            }
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.8f];
            [self setUnitLayer:unit transformedByIndex:unit.unitIndex];
            [CATransaction commit];
        }
    }else{
        ////Swipe to left section////
        if (centerFlowIndex == 0) {
            return;
        }
        
        [self addStepsToReferenceIndex:-1];
        
        for (DKFlowUnitLayer *unit in flowUnitArray) {
            unit.unitIndex = unit.unitIndex - 1;
            NSInteger nextIdx = [self nextFlowIndex:unit withLeft:YES];
            if (nextIdx != unit.flowIndex) {
                unit.flowIndex = nextIdx;
                if (nextIdx < 0) {
                    [unit setContentImage:nil];
                    [unit setNeedsDisplay];
                }else{
                    if ([self.delegate respondsToSelector:@selector(flowImageAtIndex:)]) {
                        [unit setContentImage:[self.delegate flowImageAtIndex:nextIdx].CGImage];
                        [unit setNeedsDisplay];
                    }
                }
            }
            
            if (unit.unitIndex <  0) { ///If unitIndex smaller than 0, cycling happen with chaning unitIndex back to 8//
                unit.unitIndex = 8;
                
                [CATransaction begin];
                [CATransaction setAnimationDuration:0.0f];
                [unit removeFromSuperlayer];
                [self setUnitLayer:unit transformedByIndex:unit.unitIndex];
                [self.layer addSublayer:unit];
                [CATransaction commit];
            }
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.8f];
            [self setUnitLayer:unit transformedByIndex:unit.unitIndex];
            [CATransaction commit];
        }
    }
}
#pragma mark - UIKite Methods
-(void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    ////Setup the max flow counts and set initial content images before move to super view///
    if ([self.delegate respondsToSelector:@selector(countsOfFlowPages)]) {
        self.maxFlowCount = [self.delegate countsOfFlowPages];
    }
    
    int initFlowCount = (self.maxFlowCount > 4) ? 5 : self.maxFlowCount;
    
    if (isFirstInitialization == YES) {
        isFirstInitialization = NO;
        if ([self.delegate respondsToSelector:@selector(flowImageAtIndex:)]) {
                for (int i = 0; i < initFlowCount; i++) {
                    DKFlowUnitLayer *aLayer = [flowUnitArray objectAtIndex:(4 - i)];
                    [aLayer setContentImage:[self.delegate flowImageAtIndex:i].CGImage];
                }
        }
    }
    
}
@end
