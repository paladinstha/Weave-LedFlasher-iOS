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

#import <Weave/GWLLoginController.h>

#import "AuthViewController.h"
#import "AppDelegate.h"
#import "DeviceSelectionTableViewController.h"
#import "WeaveAuthorizerManager.h"
#import "WeaveConstants.h"

@interface AuthViewController ()

@property (nonatomic) BOOL moveToDeviceSelection;

@end

@implementation AuthViewController

- (void)viewDidLoad {
  self.moveToDeviceSelection = NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // We have to watch here to know when authentication is complete, as the block that runs on
  // completion executes before this view controller regains control.
  if (_moveToDeviceSelection) {
    [self performSegueWithIdentifier:kWeaveAuthorizationCompletedSegueIdentifier sender:self];
  }
}

- (IBAction)authenticateButtonAction:(id)sender {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  GWLLoginController *loginController = appDelegate.loginController;
  if ([loginController isAuthenticated]) {
    [loginController
        getAuthorizer:^(id<GTMFetcherAuthorizationProtocol> authorizer, NSError *error) {
      if (error) {
        NSLog(@"An error occurred during authentication - %@", error);
      } else {
        if (authorizer) {
          // Now that we have a valid authorizer, we can save it and move on to device selection.
          [WeaveAuthorizerManager setAuthorizer:authorizer];
          [self performSegueWithIdentifier:kWeaveAuthorizationCompletedSegueIdentifier sender:self];
        }
      }
    }];
  } else {
    [loginController
     authenticateWithViewController:self
     completionHandler:^(id<GTMFetcherAuthorizationProtocol> authorizer, NSError *error) {
       if (error) {
         NSLog(@"An error occurred during authentication - %@", error);
       } else {
         if (authorizer) {
           // Now that we have a valid authorizer, we can save it and move on to device selection.
           [WeaveAuthorizerManager setAuthorizer:authorizer];
           self.moveToDeviceSelection = YES;
         }
       }
     }];
  }
}

@end
