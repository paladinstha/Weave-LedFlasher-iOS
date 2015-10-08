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

#import <Weave/GWLDiscovery.h>
#import <Weave/GWLCommandProtocol.h>
#import <Weave/GWLWeaveCommandDefinitions.h>
#import <Weave/GWLWeaveDevice.h>
#import <Weave/GWLWeaveTransport.h>

#import "DeviceSelectionTableViewController.h"
#import "LedFlasherViewController.h"
#import "WeaveAuthorizerManager.h"
#import "WeaveConstants.h"

@interface DeviceSelectionTableViewController () <GWLDiscoveryDelegate>

@property (nonatomic) NSMutableArray *knownDevices;
@property (nonatomic) GWLWeaveDevice *device;

@end

@implementation DeviceSelectionTableViewController

# pragma mark Lifecycle methods

- (void)viewDidLoad {
  [super viewDidLoad];

  self.knownDevices = [[NSMutableArray alloc] init];

  // Configure the discovery mechanism.
  GWLDiscovery *discovery = [GWLDiscovery sharedInstance];
  [discovery setAuthorizer:[WeaveAuthorizerManager getAuthorizerIfExists]];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  GWLDiscovery *discovery = [GWLDiscovery sharedInstance];
  [discovery addDelegate:self];
  [discovery start];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  GWLDiscovery *discovery = [GWLDiscovery sharedInstance];
  [discovery stop];
  [discovery removeDelegate:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  LedFlasherViewController *destination = [segue destinationViewController];
  [destination setDevice:_device];
}

# pragma mark GWLDiscoveryDelegate implementation

- (void)discoveryController:(GWLDiscovery *)controller didAddDevice:(GWLWeaveDevice *)device {
  id<GWLWeaveTransport> transport =
      [GWLWeaveTransport transportForDevice:device
                                 authorizer:[WeaveAuthorizerManager getAuthorizerIfExists]];
  // Check if the current device supports the LED Flasher command package.
  [transport getCommandDefsForDevice:device
                             handler:^(GWLWeaveCommandDefinitions *commands, NSError *error) {
    if (error) {
      NSLog(@"An error occurred during device discovery - %@", error);
    } else {
      NSInteger supportedPackagesCount = [commands numberOfCommandPackages];
      for (int i = 0; i < supportedPackagesCount; ++i) {
        if ([[commands packageNameForPackage:i] isEqualToString:@"_ledflasher"]) {
          // The current device is a LED Flasher, keep it.
          [_knownDevices addObject:device];
          [self.tableView reloadData];
          break;
        }
      }
    }
  }];
}

- (void)discoveryController:(GWLDiscovery *)controller didRemoveDevice:(GWLWeaveDevice *)device {
  // Removal is idempotent; no existence checks required.
  [_knownDevices removeObject:device];
  [self.tableView reloadData];
}

- (void)discoveryController:(GWLDiscovery *)controller didUpdateDevice:(GWLWeaveDevice *)device {
  // We can "update" a device by removing and readding it. Only do so if we already have the device.
  if ([_knownDevices indexOfObject:device] != NSNotFound) {
    [_knownDevices removeObject:device];
    [_knownDevices addObject:device];
    [self.tableView reloadData];
  }
}

# pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  NSInteger index = [indexPath row];
  self.device = [_knownDevices objectAtIndex:index];
  [[GWLDiscovery sharedInstance] stop];
  // A device has been selected - launch the control view.
  [self performSegueWithIdentifier:kWeaveDeviceSelectedSegueIdentifier sender:self];
}

# pragma mark UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[[GWLDiscovery sharedInstance] devices] count];
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
