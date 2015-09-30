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

#import <Weave/GWLCommandProtocol.h>
#import <Weave/GWLWeaveCommand.h>
#import <Weave/GWLWeaveTransport.h>

#import "LedFlasherViewController.h"
#import "WeaveAuthorizerManager.h"

@interface LedFlasherViewController ()

@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *led1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *led2Switch;
@property (weak, nonatomic) IBOutlet UISwitch *led3Switch;

@property (nonatomic) GWLWeaveTransport *transport;

@end

@implementation LedFlasherViewController

- (void)viewDidLoad {
  // Set the connection label to involve the device name.
  [_connectionLabel setText:[NSString stringWithFormat:@"Connected to %@", [_device name]]];

  // Obtain a transport to the device. The best of Wi-Fi, BLE, and Cloud will be autoselected.
  self.transport =
      [GWLWeaveTransport transportForDevice:_device
                                 authorizer:[WeaveAuthorizerManager getAuthorizerIfExists]];

  // Get the current LED status from the device.
  id<GWLWeaveTransport> txport = (id<GWLWeaveTransport>)_transport;
  [txport getStateForDevice:_device handler:^(NSDictionary *state, NSError *error) {
    if (error) {
      NSLog(@"An error occurred during device state retrieval - %@", error);
    } else {
      // Preset the switches to match the LEDs.
      NSArray *ledStates = [[state valueForKey:@"_ledflasher"] valueForKey:@"_leds"];
      [_led1Switch setOn:[ledStates[0] boolValue]];
      [_led2Switch setOn:[ledStates[1] boolValue]];
      [_led3Switch setOn:[ledStates[2] boolValue]];

      // Enable the switches.
      [_led1Switch setEnabled:YES];
      [_led2Switch setEnabled:YES];
      [_led3Switch setEnabled:YES];
    }
  }];
}

#pragma mark _ledflasher commands

- (void)setLed:(NSInteger)ledNum toState:(BOOL)state {
  NSDictionary *commandParams =
      @{ @"_led" : @(ledNum), @"_on" : @(state)};
  GWLWeaveCommand *ledCommand = [[GWLWeaveCommand alloc] initWithPackageName:@"_ledflasher"
                                                                 commandName:@"_set"
                                                                  parameters:commandParams];
  id<GWLWeaveTransport> txport = (id<GWLWeaveTransport>)_transport;
  [txport execute:ledCommand
           device:_device
          handler:^(GWLWeaveCommandResult *result, NSError *error) {
    if (error) {
      NSLog(@"An error occurred during command execution - %@", error);
    }
  }];
}

# pragma mark Switch actions

- (IBAction)ledSwitchValueChanged:(id)sender {
  // Determine which switch was changed.
  NSInteger ledNumber = [sender tag];
  // Set the state on the appropriate LED.
  [self setLed:ledNumber toState:[(UISwitch *)sender isOn]];
}

@end
