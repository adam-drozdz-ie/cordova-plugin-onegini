//  Copyright © 2016 Onegini. All rights reserved.

#import "OneginiUserRegistrationClient.h"
#import "AppDelegate.h"
#import "WebBrowserViewController.h"

@implementation OneginiUserRegistrationClient {}

- (void)startRegistration:(CDVInvokedUrlCommand*)command
{
  self.callbackId = command.callbackId;
  NSDictionary *options = [command.arguments objectAtIndex:0];
  NSArray *scopes = options[@"scopes"];
  [[ONGUserClient sharedInstance] registerUser:scopes delegate:self];
}

- (void)createPIN:(CDVInvokedUrlCommand*)command
{
  self.callbackId = command.callbackId;
  NSDictionary *options = [command.arguments objectAtIndex:0];
  NSString *pin = options[@"pin"];
  [self.challenge.sender respondWithCreatedPin:pin challenge:self.challenge];
}

#pragma mark - ONGRegistrationDelegate

- (void)userClient:(ONGUserClient *)userClient didReceivePinRegistrationChallenge:(ONGCreatePinChallenge *)challenge
{
  if (challenge.error != nil) {
    NSString *errorMessage = [NSString stringWithFormat: @"%@\n%@", challenge.error.localizedDescription, challenge.error.localizedRecoverySuggestion];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"description":errorMessage}] callbackId:self.callbackId];
    return;
  }

  // remember for later
  self.challenge = challenge;

  // dismiss controller
  [self.viewController dismissViewControllerAnimated:YES completion:nil];

  NSDictionary *result = @{@"pinLength":@5};
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:self.callbackId];
}

- (void)userClient:(ONGUserClient *)userClient didReceiveAuthenticationCodeRequestWithUrl:(NSURL *)url
{
  WebBrowserViewController *webBrowserViewController = [WebBrowserViewController new];
  webBrowserViewController.url = url;
  webBrowserViewController.completionBlock = ^(NSURL *completionURL) {};
  [self.viewController presentViewController:webBrowserViewController animated:YES completion:nil];
}

- (void)userClient:(ONGUserClient *)userClient didRegisterUser:(ONGUserProfile *)userProfile
{
  NSDictionary *result = @{@"profileId":userProfile.profileId};
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:self.callbackId];
}

- (void)userClient:(ONGUserClient *)userClient didFailToRegisterWithError:(NSError *)error
{
  [self.viewController dismissViewControllerAnimated:YES completion:nil];

  NSString *errorMessage = [NSString stringWithFormat: @"%@\n%@", error.localizedDescription, error.localizedRecoverySuggestion];
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"description": errorMessage}] callbackId:self.callbackId];

}

#pragma mark - OGPinValidationDelegate

- (void)pinEntryError:(NSError *)error
{
  // TODO (later) extract errorHandler method
  NSString *errorMessage = [NSString stringWithFormat: @"%@\n%@", error.localizedDescription, error.localizedRecoverySuggestion];
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"description": errorMessage}] callbackId:self.callbackId];
}

@end
