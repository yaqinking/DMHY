//
//  SavedDataViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/25/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "SavedDataViewController.h"
#import "DMHYAPI.h"
#import "DMHYCoreDataStackManager.h"
#import "DMHYTorrent.h"
#import "DMHYTool.h"
#import "PreferenceController.h"

@interface SavedDataViewController ()<NSTabViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *torrents;

@end

@implementation SavedDataViewController

@synthesize managedObjectContext = _context;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self observeNotification];
    [self setupTableViewStyle];
    [self setupTableViewSort];
    [self setupMenuItems];
}

#pragma mark - Setup

- (void)setupTableViewStyle {
    self.tableView.rowSizeStyle = [self preferedRowSizeStyle];
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.columnAutoresizingStyle            = NSTableViewUniformColumnAutoresizingStyle;
    [self.tableView sizeLastColumnToFit];
}

- (void)setupTableViewSort {
    [self.tableView setSortDescriptors:[NSArray arrayWithObjects:
                                      [NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:YES selector:@selector(compare:)],
                                      [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(compare:)],
                                      nil]];
}

- (void)setupMenuItems {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *editMenuItem = [mainMenu itemWithTitle:@"Edit"];
    NSMenu *editSubMenu = [editMenuItem submenu];
    unichar deleteKey = NSBackspaceCharacter;
    NSString *delete = [NSString stringWithCharacters:&deleteKey length:1];
    NSMenuItem *removeTorrentMenuItem = [[NSMenuItem alloc] initWithTitle:@"删除种子数据"
                                                                      action:@selector(deleteSelectTorrent)
                                                               keyEquivalent:delete];
    removeTorrentMenuItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
    
    [editSubMenu addItem:removeTorrentMenuItem];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    NSString *title = [menuItem title];
    if ([title isEqualToString:@"删除种子数据"]) {
        //什么都没选的时候
        if (self.tableView.selectedRow == -1) {
            return NO;
        }
    }
    return YES;
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

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    DMHYTorrent *torrent = self.torrents[row];
    if ([identifier isEqualToString:@"pubDateCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"pubDateCell" owner:self];
        NSString *pubDate = [[DMHYTool tool] stringFromSavedDate:torrent.pubDate];
        cellView.textField.stringValue = pubDate ? pubDate : @"";
        return cellView;
    }
    if ([identifier isEqualToString:@"titleCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"titleCell" owner:self];
        cellView.textField.stringValue = torrent.title ? torrent.title : @"";
        return cellView;
    }
    
    if ([identifier isEqualToString:@"linkCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"linkCell" owner:self];
        cellView.textField.stringValue = torrent.link ? torrent.link : @"";
        return cellView;
    }
    if ([identifier isEqualToString:@"magnetCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"magnetCell" owner:self];
        cellView.textField.stringValue = torrent.magnet ? torrent.magnet : @"";
        return cellView;
    }
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.torrents.count;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
}

- (void)deleteSelectTorrent {
    if (self.tableView.selectedRow < 0) {
        return;
    }
    NSIndexSet *selectSet = [self.tableView selectedRowIndexes];
    [selectSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        DMHYTorrent *torrent = self.torrents[idx];
        [self.managedObjectContext deleteObject:torrent];
    }];
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges]) {
        if (![self.managedObjectContext save:&error]) {
            [NSApp presentError:error];
        };
    }
    [self.torrents removeObjectsAtIndexes:selectSet];
    [self.tableView reloadData];
}

- (void)observeNotification {
    [DMHYNotification addObserver:self selector:@selector(handleThemeChanged) name:DMHYThemeChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleMainTableViewRowStyleChanged) name:DMHYMainTableViewRowStyleChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDatabaseChanged) name:DMHYDatabaseChangedNotification];
}

- (void)handleDatabaseChanged {
    self.torrents = nil;
    [self.tableView reloadData];
}

- (void)handleThemeChanged {
    [self.view setNeedsDisplay:YES];
}

- (void)handleMainTableViewRowStyleChanged {
    [self setupTableViewStyle];
    [self.tableView setNeedsDisplay:YES];
}

- (NSMutableArray *)torrents {
    if (!_torrents) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYTorrentEntityKey];
       request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:NO]];
        _torrents = [[self.managedObjectContext executeFetchRequest:request
                                                              error:NULL] mutableCopy];
    }
    return _torrents;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
        _context.undoManager = nil;
    }
    return _context;
}
@end
