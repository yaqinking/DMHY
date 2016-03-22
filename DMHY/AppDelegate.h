//
//  AppDelegate.h
//  DMHY
//
//  Created by 小笠原やきん on 9/9/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic) NSWindowController *preferencesWindowController;

- (IBAction)togglePreviewPanel:(id)previewPanel;

@end

