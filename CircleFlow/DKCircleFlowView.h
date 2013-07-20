//
//  DKCircleFlowView.h
//  CircleFlow
//
//  Created by CHIEN-MING LEE on 8/2/12.
//  Copyright (c) 2012 CHIEN-MING LEE. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol DKCircleFlowViewDelegate;

@interface DKCircleFlowView : UIView
@property (nonatomic, assign) id <DKCircleFlowViewDelegate> delegate;

-(void)reloadData;
@end

@protocol DKCircleFlowViewDelegate <NSObject>
@required
////Set how many counts of flow pages required///
-(NSInteger)countsOfFlowPages;
////Return related UIImage based on flow index//
-(UIImage *)flowImageAtIndex:(NSInteger)nextIndex;
@optional
///Respond to touch event happen in center flow page//
-(void)centerPageDidTouched:(DKCircleFlowView *)flowView atIndex:(NSInteger)anIndex;
@end