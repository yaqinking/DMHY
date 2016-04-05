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

@property (nonatomic, assign) BOOL isShowKeywordManager;

@end

@implementation MainSplitViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setupMenuItems];
   
}
- (void)setupMenuItems {
    NSMenu *viewSubMenu = [self viewSubMenu];
    NSMenuItem *toggleKeywordManagerMenuItem = [[NSMenuItem alloc] initWithTitle:@"隐藏关键字管理区域"
                                                                       action:@selector(toggleKeywordManager:)
                                                                keyEquivalent:@""];
    self.isShowKeywordManager = NO;
    [viewSubMenu addItem:toggleKeywordManagerMenuItem];
}

- (void)toggleKeywordManager:(id) sender {
    NSSplitViewItem *item = self.splitViewItems[0];
    item.collapsed = !item.collapsed;
    self.isShowKeywordManager = !self.isShowKeywordManager;
    NSMenu *viewSubMenu = [self viewSubMenu];
    NSMenuItem *toggleKeywordManagerMenuItem = [viewSubMenu itemAtIndex:3];
    toggleKeywordManagerMenuItem.title = self.isShowKeywordManager ? @"显示关键字管理区域" : @"隐藏关键字管理区域";
}

- (NSMenu *)viewSubMenu {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *viewMenuItem = [mainMenu itemWithTitle:@"View"];
    return [viewMenuItem submenu];
}

/*
 Always show divider.
 */
- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    [super splitView:splitView shouldHideDividerAtIndex:dividerIndex];
    return NO;
}


@end
