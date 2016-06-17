//
//  FileManagerViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/25/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "FileManagerViewController.h"
#import "DMHYAPI.h"
#import "PreferenceController.h"
#import "AppDelegate.h"
#import "NSTableView+ContextMenu.h"
#import "FileItem.h"
#import "FileTableView.h"
#import "CDEvent.h"
#import "CDEvents.h"
#import <CDEvents/CDEventsDelegate.h>

@import Quartz;

// QuickLook code from https://developer.apple.com/library/mac/samplecode/QuickLookDownloader/

@interface FileItem (QLPreviewItem) <QLPreviewItem>

@end

@implementation FileItem (QLPreviewItem)

- (NSURL *)previewItemURL {
    return self.url;
}

- (NSString *)previewItemTitle {
    return self.fileName;
}

@end

@interface FileManagerViewController ()<NSTableViewDelegate, NSTableViewDataSource, ContextMenuDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource, CDEventsDelegate>

@property (weak) IBOutlet FileTableView *tableView;
@property (weak) IBOutlet NSTextField *infoTextField;

@property (strong) QLPreviewPanel *previewPanel;

@property (nonatomic, strong) NSMutableArray *files;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSURL *fileWatchURL;

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSDateFormatter *formater;

@property (nonatomic, strong) CDEvents *events;

@end

@implementation FileManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self observeNotification];
    if (self.fileWatchURL) {
        [self setupFileData];
        [self setupFileWatcher];
    } else {
        self.infoTextField.stringValue = @"请在设定里设置文件监控路径 >_<";
    }
    [self setupTableViewDoubleAction];
    
}

- (void)setupTableViewDoubleAction {
    self.tableView.doubleAction = @selector(openLocalFile:);
}

- (void)setupFileWatcher {
    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags;
    
    creationFlags |= kFSEventStreamCreateFlagFileEvents;
    
    
    _events = [[CDEvents alloc] initWithURLs:@[self.fileWatchURL]
                                    delegate:self
                                   onRunLoop:[NSRunLoop mainRunLoop]
                        sinceEventIdentifier:kCDEventsSinceEventNow
                        notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                     ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                 excludeURLs:0
                         streamCreationFlags:creationFlags];
}

- (void)setupTableViewStyle {
    self.tableView.rowSizeStyle = [self preferedRowSizeStyle];
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.columnAutoresizingStyle            = NSTableViewUniformColumnAutoresizingStyle;
    [self.tableView sizeLastColumnToFit];
}

- (NSTableViewRowSizeStyle )preferedRowSizeStyle {
    NSInteger rowStyle = [PreferenceController viewPreferenceTableViewRowStyle];
    switch (rowStyle) {
        case 0:
            return NSTableViewRowSizeStyleSmall;
        case 1:
            return NSTableViewRowSizeStyleMedium;
        case 2:
            return NSTableViewRowSizeStyleLarge;
        default:
            break;
    }
    return NSTableViewRowSizeStyleSmall;
}

- (NSURL *)fileWatchURL {
    if (!_fileWatchURL) {
        _fileWatchURL = [PreferenceController fileWatchPath];
        [_fileWatchURL startAccessingSecurityScopedResource];
    }
    return _fileWatchURL;
}

//const UInt32 DMHYFileEventFlagFileChanged = 67584;
typedef NS_ENUM(UInt32, DMHYFileEventFlag) {
    DMHYFileEventFlagFileMoved = 128256,
    DMHYFileEventFlagFileChanged = 67584,
    DMHYFileEventFlagFileDeleted = 70656,
    DMHYFileEventFlagDirectoryChanged = 163840
};

- (void)URLWatcher:(CDEvents *)urlWatcher eventOccurred:(CDEvent *)event {
    if (event.flags == DMHYFileEventFlagFileChanged ||
        event.flags == DMHYFileEventFlagFileMoved ||
        event.flags == DMHYFileEventFlagDirectoryChanged) {
        [self setupFileData];
    }
    
}

#pragma mark - File Watch

- (void)setupFileData {
//    NSLog(@"Setup File Data");
    dispatch_queue_t file_queue = dispatch_queue_create("file_watch_queue", 0);
    dispatch_async(file_queue, ^{
//        NSLog(@"File Manager %p File Watch URL %p",self.fileManager, self.fileWatchURL);
        if (!self.fileWatchURL) { //Stop when use didn't select directory.
//            NSLog(@"Not set watch directory.");
            return ;
        }
        
        NSDirectoryEnumerator *enumerator = [self.fileManager enumeratorAtURL:self.fileWatchURL
                                              includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                            errorHandler:^BOOL(NSURL *url, NSError *error)
                                             {
                                                 if (error) {
                                                     NSLog(@"[Error] %@ (%@)", error, url);
                                                     return NO;
                                                 }
                                                 
                                                 return YES;
                                             }];
        
        NSMutableArray *mutableFileURLs = [NSMutableArray array];
        NSMutableArray *mutableFileNames = [NSMutableArray array];
        for (NSURL *fileURL in enumerator) {
            NSString *filename;
            [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
            
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            // Skip directories with '_' prefix, for example
            if ([filename hasPrefix:@"_"] && [isDirectory boolValue]) {
                [enumerator skipDescendants];
                continue;
            }
            
            if (![isDirectory boolValue]) {
                [mutableFileURLs addObject:fileURL];
                [mutableFileNames addObject:filename];
            }
        }
        
        __block NSMutableArray *tempArr = [NSMutableArray new];
        __block NSDate *today = [[NSDate alloc] initWithTimeIntervalSinceNow:-60*60*24*7];
        [mutableFileURLs enumerateObjectsUsingBlock:^(id  _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *url = filePath;
            NSString *extenstion = url.pathExtension;
            if ([extenstion isEqualToString:@"mp4"] ||
                [extenstion isEqualToString:@"mkv"] ) {
                if ([self.fileManager fileExistsAtPath:url.path]) {
                    NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:url.path error:nil];
                    NSDate *modi = attributes[NSFileModificationDate];
                    if ([modi compare:today] == NSOrderedDescending) {
                        FileItem *item = [[FileItem alloc] initWithURL:url
                                                              fileName:mutableFileNames[idx]
                                                            modifyDate:modi];
                        [tempArr addObject:item];
                    }
                }
            }
        }];
        // Didn't stop accessing in order to preview video
//        [fileWatchURL stopAccessingSecurityScopedResource];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"modifyDate" ascending:NO];
        self.files = [[tempArr sortedArrayUsingDescriptors:@[descriptor]] mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.previewPanel reloadData];
            [self setupTableViewStyle];
            [self.tableView setNeedsDisplay:YES];
            NSDate *time = [NSDate new];
            self.infoTextField.stringValue = [NSString stringWithFormat:@"文件列表载入时间：%@",[[DMHYTool tool] infoDateStringFromDate:time]];
        });
    });
    
}

#pragma mark - Table View DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.files.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    FileItem *file = self.files[row];
    if ([identifier isEqualToString:@"modifyDateCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"modifyDateCell" owner:self];
        NSDate *modi = file.modifyDate;
        NSString *cDate = [[DMHYTool tool] stringFromSavedDate:modi];
        cellView.textField.stringValue = cDate;
        return cellView;
    }
    if ([identifier isEqualToString:@"fileNameCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"fileNameCell" owner:self];
        cellView.textField.stringValue = file.fileName;
        return cellView;
    }
    return nil;
}

- (NSDateFormatter *)formater {
    if (!_formater) {
        _formater = [NSDateFormatter new];
        _formater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        _formater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    }
    return _formater;
}

#pragma mark - Context Menu Delegate

- (NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows {
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"打开"
                                                      action:@selector(openLocalFile:)
                                               keyEquivalent:@""];
    NSMenuItem *downloadItem = [[NSMenuItem alloc] initWithTitle:@"在 Finder 中显示"
                                                          action:@selector(locateInFinder:)
                                                   keyEquivalent:@""];
    [rightClickMenu addItem:openItem];
    [rightClickMenu addItem:downloadItem];
    return rightClickMenu;
}

#pragma mark - Utils

- (void)locateInFinder:(id) sender {
    NSInteger selectRow = self.tableView.selectedRow;
    FileItem *file = self.files[selectRow];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[file.url]];
}

- (void)openLocalFile:(id)sender {
    NSInteger selectRow = self.tableView.selectedRow;
    if (selectRow < 0) {
        return;
    }
    FileItem *file = self.files[selectRow];
    [[NSWorkspace sharedWorkspace] openURL:file.url];
}

- (void)observeNotification {
    [DMHYNotification addObserver:self selector:@selector(handleThemeChanged) name:DMHYThemeChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleFileWatchPathChanged) name:DMHYFileWatchPathChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleMainTableViewRowStyleChanged) name:DMHYMainTableViewRowStyleChangedNotification];
}

- (void)handleFileWatchPathChanged {
    self.files = nil;
    self.fileWatchURL = nil;
    [self setupFileData];
}

- (void)handleMainTableViewRowStyleChanged {
    [self setupTableViewStyle];
    [self.tableView setNeedsDisplay:YES];
}

- (void)handleThemeChanged {
    [self.view setNeedsDisplay:YES];
}

- (NSMutableArray *)files {
    if (!_files) {
        _files = [NSMutableArray new];
    }
    return _files;
}

- (NSFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

#pragma mark - Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    _previewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    _previewPanel = nil;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return self.files.count;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    NSInteger selectRow = self.tableView.selectedRow;
    return self.files[selectRow];
}

#pragma mark - QLPreviewPanelDelegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    // redirect all key down events to the table view
    if ([event type] == NSKeyDown) {
        [self.tableView keyDown:event];
        return YES;
    }
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    NSInteger index = [self.files indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    }
    
    NSRect iconRect = [self.tableView frameOfCellAtColumn:0 row:index];
    
    // check that the icon rect is visible on screen
    NSRect visibleRect = [self.tableView visibleRect];
    
    if (!NSIntersectsRect(visibleRect, iconRect)) {
        return NSZeroRect;
    }
    
    // convert icon rect to screen coordinates
    iconRect = [self.tableView convertRectToBacking:iconRect];
    NSRect test = [[self.tableView window] convertRectToScreen:iconRect];
    iconRect.origin = test.origin;
    
    return iconRect;
}

@end
