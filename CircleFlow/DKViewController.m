//
//  DKViewController.m
//  CircleFlow
//
//  Created by CHIEN-MING LEE on 8/1/12.
//  Copyright (c) 2012 CHIEN-MING LEE. All rights reserved.
//

#import "DKViewController.h"


@interface DKViewController ()
@property (nonatomic, strong) DKCircleFlowView *circleFlow;
@property (nonatomic, strong) CALayer *leftLayer;
@property (nonatomic, strong) CALayer *centerLayer;
@property (nonatomic, strong) CALayer *rightLayer;

@property (nonatomic, strong) NSArray *imgArray;
@property (nonatomic) BOOL changeToImgArray;

-(IBAction)reloadCircleFlow:(id)sender;
@end

@implementation DKViewController
@synthesize leftLayer, centerLayer, rightLayer;
@synthesize imgArray;
@synthesize circleFlow;
@synthesize changeToImgArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DKCircleFlowView *aTestView = [[[DKCircleFlowView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)] autorelease];
    aTestView.center = CGPointMake(160.0f, 340.0f);
    aTestView.delegate = self;
    self.circleFlow = aTestView;
    [self.view addSubview:self.circleFlow];
    
    changeToImgArray = NO;
    
    imgArray = [[NSArray arrayWithObjects:[UIImage imageNamed:@"Text10.png"], [UIImage imageNamed:@"Text11.png"], [UIImage imageNamed:@"Text12.png"],nil] retain];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(IBAction)reloadCircleFlow:(id)sender
{
    changeToImgArray = YES;
    [self.circleFlow reloadData];
}

#pragma mark - DKCircleFlowViewDelegate
-(NSInteger)countsOfFlowPages
{
    return 3;
}
-(UIImage *)flowImageAtIndex:(NSInteger)nextIndex
{
    if (changeToImgArray) {
        return [imgArray objectAtIndex:nextIndex];
    }
    return [UIImage imageNamed:[NSString stringWithFormat:@"Text%02d.png", nextIndex+1]];
}
-(void)centerPageDidTouched:(DKCircleFlowView *)flowView atIndex:(NSInteger)anIndex
{
    SHOW_CMD;
    GKLog(@"center page index is %d", anIndex);
}
@end
