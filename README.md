Weave LED Flasher iOS

Requires Xcode 7.0 or higher.

Current setup steps:
* Obtain a copy of Weave.framwork and add to project. Add it to Embedded Binaries too.
* Get a copy of GTMOAuth2ViewTouch.xib, and add it somewhere.
* In WeaveConstants.m, put your own client ID and client secret in the strings. Note that OAuth2 credentials must be created for "Other device", NOT for iOS, as the iOS option currently fails to give you a client secret.
