# Weave LEDFlasher iOS
Weave LEDFlasher iOS shows how to send Weave commands from iOS. This app
demonstrates turning LEDs on and off via commands sent via the Weave iOS SDK.

## Setup

1. Install [CocoaPods](https://cocoapods.org)

2. Run `pod install`. An .xcworkspace file will be generated for you. Open it and record the `Bundle Identifier` in the `LedFlasher` target.

3. Go to [Google Developer Console](https://console.developers.google.com) and create a project for the app. Go to _API Manager > Overview > Google APIs_ and enable the _Weave API_.

4. Go to _API Manager > Credentials_ and set up the _OAuth consent screen_.

5. Select _Add credentials > OAuth 2.0 client ID_. Choose _iOS_ as the application type and complete the required fields. The console gives you a `client ID` and an `iOS URL Scheme`.

6. Put the `client ID` in the `kWeaveClientId` constant in `WeaveConstants.m`.

7. Go to _Info > URL Types_. Create two URL types. On one, set the _URL Schemes_ to the `iOS URL Scheme` from the console. On the other, set the _URL Schemes_ to the app's bundle identifier.

## Documentation

Visit the [Weave homepage](https://developers.google.com/weave/).

## Technical Details

This sample is published. No Objective-C class prefix is used. This sample
requires XCode 7.0 or later.

## Tags
- Ubiquity 2016

## Technologies
- iOS
- Weave
- Developer Console

## Languages
- Objective-C



