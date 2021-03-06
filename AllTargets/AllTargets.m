//
//  AllTargets.m
//  AllTargets
//
//  Created by Jobs on 15/2/22.
//  Copyright (c) 2015年 Jobs. All rights reserved.
//

#import "AllTargets.h"
#import "Xcode3TargetMembershipDataSource+HookAllTargets.h"
#import "ATMenuItem.h"
#import "ATSavedData.h"

static NSString * const BundleNameKey = @"CFBundleName";
static NSString * const XcodeKey = @"Xcode";
static NSString * const PluginsKey = @"Plugins";
static NSString * const WindowsKey = @"Window";

static AllTargets *sharedPlugin;

@interface AllTargets() <NSTableViewDelegate, ATMenuItemDelegate>

@end

@implementation AllTargets

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][BundleNameKey];
    if ([currentApplicationName isEqualToString:XcodeKey]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    
    if (self) {
        // Reference to plugin's bundle, for resource access
        _bundle = plugin;
        
        [self setupNotifications];
        [Xcode3TargetMembershipDataSource hookAllTargets];
    }
    
    return self;
}

- (void)addPluginsMenu:(NSNotification *)notifications
{
    NSMenu *appMenu = [NSApp mainMenu];
    if (!appMenu) {
        return;
    }
    
    [self removeNotifications];
    
    // Add Plugins menu next to Window menu
    NSMenuItem *pluginsMenuItem = [appMenu itemWithTitle:PluginsKey];
    if (!pluginsMenuItem) {
        pluginsMenuItem = [[NSMenuItem alloc] init];
        pluginsMenuItem.title = PluginsKey;
        pluginsMenuItem.submenu = [[NSMenu alloc] initWithTitle:pluginsMenuItem.title];
        NSInteger windowIndex = [appMenu indexOfItemWithTitle:WindowsKey];
        [appMenu insertItem:pluginsMenuItem atIndex:windowIndex];
    }
    
    ATMenuItem *menuItem = [[ATMenuItem alloc] initWithSavedData:self.savedData];
    menuItem.delegate = self;
    [pluginsMenuItem.submenu addItem:menuItem];
}

#pragma mark - Saved Data methods

- (ATSavedData *)savedData
{
    ATSavedData *savedData;
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromClass([ATSavedData class])];
    if (data) {
        savedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        savedData = [[ATSavedData alloc] init];
    }
    
    return savedData;
}

- (void)setSavedData:(ATSavedData *)savedData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:savedData];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:NSStringFromClass([ATSavedData class])];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - ATMenuItemDelegate

- (void)menuItem:(ATMenuItem *)menuItem didUpdateSavedData:(ATSavedData *)savedData
{
    self.savedData = savedData;
}

#pragma mark - Notifications

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addPluginsMenu:)
                                                 name:NSMenuDidChangeItemNotification
                                               object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMenuDidChangeItemNotification
                                                  object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
