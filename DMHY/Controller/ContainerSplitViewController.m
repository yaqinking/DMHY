//
//  ContainerSplitViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/25/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "ContainerSplitViewController.h"

@interface ContainerSplitViewController ()

@property (nonatomic, assign) BOOL isShowFileManager;

@end

@implementation ContainerSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setupMenuItems];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    [super splitView:splitView shouldHideDividerAtIndex:dividerIndex];
    return NO;
}

- (void)setupMenuItems {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *viewMenuItem = [mainMenu itemWithTitle:@"View"];
    NSMenu *viewSubMenu = [viewMenuItem submenu];
    NSMenuItem *toggleFileManagerMenuItem = [[NSMenuItem alloc] initWithTitle:@"隐藏文件管理区域"
                                                                           action:@selector(toggleFileManager:)
                                                                    keyEquivalent:@""];
    self.isShowFileManager = NO;
    [viewSubMenu addItem:toggleFileManagerMenuItem];
}

- (void)toggleFileManager:(id)sender {
    NSSplitViewItem *item = self.splitViewItems[1];
    item.collapsed = !item.collapsed;
    self.isShowFileManager = !self.isShowFileManager;
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *viewMenuItem = [mainMenu itemWithTitle:@"View"];
    NSMenu *viewSubMenu = [viewMenuItem submenu];
    NSMenuItem *toggleFileManagerMenuItem = [viewSubMenu itemAtIndex:2];
    toggleFileManagerMenuItem.title = self.isShowFileManager ? @"显示文件管理区域" : @"隐藏文件管理区域";
}

@end
