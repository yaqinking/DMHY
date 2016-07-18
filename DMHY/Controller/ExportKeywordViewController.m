//
//  ExportViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 7/18/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "ExportKeywordViewController.h"
#import "DMHYCoreDataStackManager.h"

@interface ExportKeywordViewController ()
@property (weak) IBOutlet NSStackView *stackView;
@property (unsafe_unretained) IBOutlet NSTextView *textView;


@property (nonatomic, strong) NSMutableArray *exportSiteNames;
@end

@implementation ExportKeywordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.textView.minSize = NSMakeSize(200, 400);
     NSArray<DMHYSite *> *sites = [[DMHYCoreDataStackManager sharedManager] allSites];
    
    [sites enumerateObjectsUsingBlock:^(DMHYSite * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
        [button setButtonType:NSSwitchButton];
        [button setBezelStyle:NSRoundedBezelStyle];
        button.title = obj.name;
        button.target = self;
        button.action = @selector(checkButtonChanged:);
        [self.stackView insertArrangedSubview:button atIndex:idx];
    }];
    self.exportSiteNames = [NSMutableArray new];
}

- (void)checkButtonChanged:(NSButton *)sender {
    if (sender.state == 1) {
        [self.exportSiteNames addObject:sender.title];
    } else {
        [self.exportSiteNames removeObject:sender.title];
    }
}

- (IBAction)export:(NSButton *)sender {
    [self.textView.textStorage.mutableString setString:@""];
    [[DMHYCoreDataStackManager sharedManager] exportSites:self.exportSiteNames success:^(NSString *json){
        [self.textView insertText:json];
    } failure:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (IBAction)copy:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[self.textView.string]];
}

@end
