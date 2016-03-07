//
//  WindowController.m
//  DMHY
//
//  Created by 小笠原やきん on 16/3/7.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "WindowController.h"

@interface WindowController ()

@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
    self.window.titlebarAppearsTransparent = YES;
}

@end
