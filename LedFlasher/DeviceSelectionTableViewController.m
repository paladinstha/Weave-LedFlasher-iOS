/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <GoogleWeave/GWLCommandProtocol.h>
#import <GoogleWeave/GWLDeviceScanner.h>
#import <GoogleWeave/GWLWeaveCommandDefinitions.h>
#import <GoogleWeave/GWLWeaveDevice.h>
#import <GoogleWeave/GWLWeaveTransport.h>

#import "AppDelegate.h"
#import "DeviceSelectionTableViewController.h"
#import "LedFlasherViewController.h"
#import "WeaveConstants.h"

@interface DeviceSelectionTableViewController () <GWLDeviceScannerDelegate>

@property (nonatomic) NSMutableArray *knownDevices;
@property (nonatomic) GWLWeaveDevice *device;

@end

@implementation DeviceSelectionTableViewController

# pragma mark Lifecycle methods

- (void)viewDidLoad {
  [super viewDidLoad];

  self.knownDevices = [[NSMutableArray alloc] init];

  // [START scanning]
  // Configure the discovery mechanism.
  GWLDeviceScanner *scanner = [GWLDeviceScanner sharedInstance];
  [scanner addDelegate:self];
  // [START_EXCLUDE silent]
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  GWLLoginController *loginController = appDelegate.loginController;
  // [END_EXCLUDE]
  [loginController
   getAuthorizer:^(id<GTMFetcherAuthorizationProtocol> authorizer, NSError *error) {
     if (error) {
       NSLog(@"An error occurred while retrieving the authorizer - %@", error);
     } else {
       [scanner startWithAuthorizer:authorizer];
     }
   }];
  // [END scanning]
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  GWLDeviceScanner *scanner = [GWLDeviceScanner sharedInstance];
  [scanner addDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  GWLDeviceScanner *scanner = [GWLDeviceScanner sharedInstance];
  [scanner removeDelegate:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  LedFlasherViewController *destination = [segue destinationViewController];
  [destination setDevice:_device];
}

# pragma mark GWLDeviceScannerDelegate implementation

// [START scanning-delegate]
- (void)deviceScanner:(GWLDeviceScanner *)controller didAddDevice:(GWLWeaveDevice *)device {
  // [START_EXCLUDE silent]
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  GWLLoginController *loginController = appDelegate.loginController;
  [loginController
   getAuthorizer:^(id<GTMFetcherAuthorizationProtocol> authorizer, NSError *error) {
     if (error) {
       NSLog(@"An error occurred while retrieving the authorizer - %@", error);
     } else {
       // [START command-defs]
       id<GWLWeaveTransport> transport =
       [GWLWeaveTransport transportForDevice:device
                                  authorizer:authorizer];
       // Retrieve the device's command definitions.
       [transport getCommandDefsForDevice:device
                                  handler:^(GWLWeaveCommandDefinitions *commands, NSError *error) {
        if (error) {
          NSLog(@"An error occurred during device discovery - %@", error);
        } else {
          // Obtained commands.
          // [END command-defs]
          if ([[commands packages] objectForKey:@"_ledflasher"]) {
            // The current device is a LED Flasher, keep it.
            // [END_EXCLUDE]
            [_knownDevices addObject:device];
            [self.tableView reloadData];
            // [START_EXCLUDE silent]
          }
        }
      }];
     }
   }];
  // [END_EXCLUDE]
}

- (void)deviceScanner:(GWLDeviceScanner *)controller didRemoveDevice:(GWLWeaveDevice *)device {
  // Removal is idempotent; no existence checks required.
  [_knownDevices removeObject:device];
  [self.tableView reloadData];
}

- (void)deviceScanner:(GWLDeviceScanner *)controller didUpdateDevice:(GWLWeaveDevice *)device {
  // We can "update" a device by removing and readding it. Only do so if we already have the device.
  if ([_knownDevices indexOfObject:device] != NSNotFound) {
    [_knownDevices removeObject:device];
    [_knownDevices addObject:device];
    [self.tableView reloadData];
  }
}
// [END scanning-delegate]

# pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  NSInteger index = [indexPath row];
  self.device = [_knownDevices objectAtIndex:index];
  // A device has been selected - launch the control view.
  [self performSegueWithIdentifier:kWeaveDeviceSelectedSegueIdentifier sender:self];
}

# pragma mark UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_knownDevices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kWeaveDeviceSelectionCellIdentifier
                                      forIndexPath:indexPath];
  GWLWeaveDevice *device = [_knownDevices objectAtIndex:[indexPath row]];
  cell.textLabel.text = device.name;
  return cell;
}

@end
