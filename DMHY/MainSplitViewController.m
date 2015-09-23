//
//  MainSplitViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/19/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "MainSplitViewController.h"
#import "SideViewController.h"

@interface MainSplitViewController ()

@end

@implementation MainSplitViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do view setup here.
    
    /**
     *  Get min/max divider position
     */
//    CGFloat min = [self.splitView minPossiblePositionOfDividerAtIndex:0];
//    CGFloat max = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
//    NSLog(@"min %f max %f",min,max);
    
   
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    [super splitView:splitView shouldHideDividerAtIndex:dividerIndex];
    return NO;
}

//#pragma mark - NSSplitViewDelegate

//- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
//    [super splitView:splitView canCollapseSubview:subview];
//    if ([subview.identifier isEqualToString:@"navigation"]) {
//        return YES;
//    }
//    return NO;
//}
//
//
//- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
//    [super splitView:splitView shouldCollapseSubview:subview forDoubleClickOnDividerAtIndex:dividerIndex];
//    if ([subview.identifier isEqualToString:@"navigation"]) {
//        return YES;
//    }
//    return NO;
//}

- (void)splitViewWillResizeSubviews:(NSNotification *)notification {
//    NSLog(@"subViewController class %@",[self.splitViewItems[0].viewController class]);
}

////不能在 NSSplitViewController 中使用的方法（必须使用 AutoLayout）
//- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
//    if ([view.identifier isEqualToString:@"navigation"]) {
//        //        NSLog(@"navi adjust");
//        view.frame = NSMakeRect(0, 0, 320, splitView.bounds.size.height);
//        return NO;
//    }
//    return YES;
//}

//- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
//    return proposedMinimumPosition + 300;
//}
//
//- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
//    return proposedMaximumPosition - 724;
//}
//


//- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
//    return YES;
//}


@end
