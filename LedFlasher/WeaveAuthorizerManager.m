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

#import "WeaveAuthorizerManager.h"
#import "WeaveConstants.h"

static id<GTMFetcherAuthorizationProtocol> auth;
static dispatch_once_t queueCreationPredicate;
static dispatch_queue_t authorizerAccessQueue;

@implementation WeaveAuthorizerManager

+ (id<GTMFetcherAuthorizationProtocol>)getAuthorizerIfExists {
  // Create the queue, or wait for the queue to be created.
  dispatch_once(&queueCreationPredicate, ^{
    authorizerAccessQueue =
        dispatch_queue_create(kWeaveAuthorizerManagerQueueLabel, DISPATCH_QUEUE_CONCURRENT);
  });
  // Access the authorizer and return it.
  __block id<GTMFetcherAuthorizationProtocol> authorizer;
  dispatch_sync(authorizerAccessQueue, ^{
    authorizer = auth;
  });
  return authorizer;
}

+ (void)setAuthorizer:(id<GTMFetcherAuthorizationProtocol>)authorizer {
  // Create the queue, or wait for the queue to be created.
  dispatch_once(&queueCreationPredicate, ^{
    authorizerAccessQueue =
        dispatch_queue_create(kWeaveAuthorizerManagerQueueLabel, DISPATCH_QUEUE_CONCURRENT);
  });
  // Set the authorizer from behind a barrier to prevent inconsistent reads.
  dispatch_barrier_async(authorizerAccessQueue, ^{
    auth = authorizer;
  });
}

@end
