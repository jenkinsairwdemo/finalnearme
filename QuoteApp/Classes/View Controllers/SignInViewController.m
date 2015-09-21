//
//  SignInViewController.m
//  ContentBox
//
//  Created by Igor Sapyanik on 22.01.14.
/**
 * Copyright (c) 2014 Kinvey Inc. *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at *
 * http://www.apache.org/licenses/LICENSE-2.0 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License. *
 */
#import <KinveyKit/KinveyKit.h>
#import "SignInViewController.h"



#import "DejalActivityView.h"

@interface SignInViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *demoButton;
@property (nonatomic, retain) UIViewController *webViewController;
@property (nonatomic, retain) CLLocationManager *locationManager;


- (IBAction)textFieldEditingDidChange:(id)sender;

@end

@implementation SignInViewController

+ (void)presentSignInFlowOnViewController:(UIViewController *)vc animated:(BOOL)animated onCompletion:(STEmptyBlock)success{
    
	if (!vc) return;
	
	SignInViewController *signInViewController = [[SignInViewController alloc] init];
	signInViewController.completionBlock = success;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:signInViewController];
	navigationController.navigationBarHidden = YES;
	[vc presentViewController:navigationController animated:animated completion:nil];


}

#pragma mark - Location Delegate
// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (fabs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Ouch: %@", error);
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)dealloc{
	DVLog(@"");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _webViewController = [[UIViewController alloc] init];

#if 0

	self.title = LOC(SIVC_TITLE);
	[self.signUpButton setTitle:LOC(SIVC_SIGNUP)
                       forState:UIControlStateNormal];
	[self.loginButton setTitle:LOC(SIVC_LOGIN)
                      forState:UIControlStateNormal];
	self.usernameField.placeholder = LOC(SIVC_USERNAME);
	self.passwordField.placeholder = LOC(SIVC_PASSWORD);
    
    self.view.backgroundColor = BAR_COLOR;
    self.contentView.backgroundColor = BAR_COLOR;
#else
    self.title = LOC(SIVC_TITLE);
    [self.signUpButton setTitle:LOC(SIVC_SIGNUP)
                       forState:UIControlStateNormal];
    [self.loginButton setTitle:LOC(SIVC_LOGIN)
                      forState:UIControlStateNormal];
    self.usernameField.placeholder = LOC(SIVC_USERNAME);
    self.passwordField.placeholder = LOC(SIVC_PASSWORD);

    self.view.backgroundColor = BAR_COLOR;
    self.contentView.backgroundColor = BAR_COLOR;

    self.loginButton.hidden = YES;
    self.usernameField.hidden = YES;
    self.passwordField.hidden = YES;
    self.signUpButton.hidden = YES;
    [self.demoButton setTitle:@"Log In" forState:UIControlStateNormal];

#endif
    // Create the location manager if this object does not
    // already have one.
    NSLog(@"Loc services? %d", [CLLocationManager locationServicesEnabled]);
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];

    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

    // Set a movement threshold for new events.
    _locationManager.distanceFilter = 500; // meters

    if ([_locationManager respondsToSelector:
         @selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }

    [_locationManager startUpdatingLocation];

    CLLocation* location = [_locationManager location];
    NSLog(@"Loc: %@", location);

    
}

- (void)viewWillAppear:(BOOL)animated{
    
	[super viewWillAppear:animated];
	
	[self updateButtons];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShow:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHide:)
                               name:UIKeyboardWillHideNotification
                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateButtons{
    
	self.signUpButton.enabled = self.loginButton.enabled = (self.usernameField.text.length && self.passwordField.text.length);
    
}

-(void)keyboardWillShow:(NSNotification *)notification{
    
	NSValue *v = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect rect = [v CGRectValue];
	rect = [self.view convertRect:rect fromView:nil];
	CGFloat keyboardHeight = CGRectGetHeight(rect);
	
	// get keyboard size and loctaion
	NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve curveType = [curve integerValue];
    UIViewAnimationOptions animationOptions = curveType << 16;
    
    [UIView animateWithDuration:[duration doubleValue]
						  delay:0
                        options:animationOptions
                     animations:^{
                         // set views with new info
						 self.contentView.$y -= keyboardHeight / 2;
                     }
                     completion:nil];
}

-(void)keyboardWillHide:(NSNotification *)notification{
    
	NSValue *v = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect rect = [v CGRectValue];
	rect = [self.view convertRect:rect fromView:nil];
	CGFloat keyboardHeight = CGRectGetHeight(rect);
	
	// get keyboard size
	NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve curveType = [curve integerValue];
    UIViewAnimationOptions animationOptions = curveType << 16;
    
    [UIView animateWithDuration:[duration doubleValue]
						  delay:0
                        options:animationOptions
                     animations:^{
                         // set views with new info
						 self.contentView.$y += keyboardHeight / 2;
                     }
                     completion:nil];
}

- (IBAction)pressedSignUp:(id)sender{
    
	[DejalBezelActivityView activityViewForView:self.view];
    
    //Sing up new Kinvey user 
	[[AuthenticationHelper instance] signUpWithUsername:self.usernameField.text
                                               password:self.passwordField.text
											  onSuccess:^{
                                                  
												  [DejalActivityView removeView];
                                                  
												  [self.navigationController dismissViewControllerAnimated:NO
																								completion:^{
																									if (self.completionBlock) {
																										self.completionBlock();
																										self.completionBlock = nil;
																									}
																								}];
											  }
											  onFailure:^(NSError *error) {
                                                  
												  [DejalBezelActivityView removeView];
                                                  
                                                  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                                                      message:error.localizedDescription ? error.localizedDescription : LOC(ERR_SMTH_WENT_WRONG)
                                                                                                     delegate:nil
                                                                                            cancelButtonTitle:LOC(OKAY)
                                                                                            otherButtonTitles:nil];
                                                  [alertView show];
											  }];
}

// ****************************----- Enter the Kinvey Code here ----------------------------------------------*********//

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    if ([KCSUser isValidMICRedirectURI:@"aw://" forURL:url]) {
        [KCSUser parseMICRedirectURI:@"aw://"
                              forURL:url
                 withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
         {
             NSLog(@"E: %@, U: %@, R: %ld", errorOrNil, user, (long)result);
             [_webViewController dismissViewControllerAnimated:YES completion:^{
                 NSLog(@"Dismissed");
                 if (user){
                     [self.navigationController dismissViewControllerAnimated:NO
                                                                   completion:^{
                                                                       if (self.completionBlock) {
                                                                           self.completionBlock();
                                                                           self.completionBlock = nil;
                                                                       }
                                                                   }];
                     
                 } else {
                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                         message: errorOrNil.localizedDescription ? errorOrNil.localizedDescription : LOC(ERR_SMTH_WENT_WRONG)
                                                                        delegate:nil
                                                               cancelButtonTitle:LOC(OKAY)
                                                               otherButtonTitles:nil];
                     [alertView show];
                     
                 }
             }];
         }];
        
        return NO;
    }
    return YES;
}


// Ready to commit



//*************************** ------------------------------------------------------------------------------------*******//

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error in loading webview: %@", error);

    if ((error.domain != NSURLErrorDomain || error.code != -999) &&
        (![error.domain isEqualToString:@"WebKitErrorDomain"] && error.code != 102)){
        [_webViewController dismissViewControllerAnimated:YES completion:^{

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                message: error.localizedDescription ? error.localizedDescription : LOC(ERR_SMTH_WENT_WRONG)
                                                               delegate:nil
                                                      cancelButtonTitle:LOC(OKAY)
                                                      otherButtonTitles:nil];
            [alertView show];
        }];
    }

}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"Done");
}

- (IBAction)pressedLogin:(id)sender{

#if 1
    NSURL* url = [KCSUser URLforLoginWithMICRedirectURI:@"aw://"];

    UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: self.view.frame];
    [uiWebView loadRequest:[NSURLRequest requestWithURL:url]];
    uiWebView.delegate = self;

    [_webViewController.view addSubview: uiWebView];

    [self.navigationController presentViewController: _webViewController animated:YES completion:^{}];



#if 0
    [KCSUser presentMICLoginViewControllerWithRedirectURI:@"aw://"
                                                  timeout:60 * 5 // Timeout after 5 minutes
                                      withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
    {
        if (user != nil) {
            [self.navigationController dismissViewControllerAnimated:NO
                                                          completion:^{
                                                              if (self.completionBlock) {
                                                                  self.completionBlock();
                                                                  self.completionBlock = nil;
                                                              }
                                                          }];
        } else if (result == KCSUserInteractionCancel) {
            //result parameter will be KCSUserInteractionCancel if the user hit the close button
        } else if (result == KCSUserInteractionTimeout || errorOrNil != nil) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                message: @"Login timed out"
                                                               delegate:nil
                                                      cancelButtonTitle:LOC(OKAY)
                                                      otherButtonTitles:nil];
            [alertView show];

            //result parameter will be KCSUserInteractionTimeout if the user didn't finish the authentication process before the timeout
        } else if (errorOrNil != nil) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                message:errorOrNil.localizedDescription ? errorOrNil.localizedDescription : LOC(ERR_SMTH_WENT_WRONG)
                                                               delegate:nil
                                                      cancelButtonTitle:LOC(OKAY)
                                                      otherButtonTitles:nil];
            [alertView show];
        } else {
            //should never happen!
        }
    }];
#endif
#else

	[DejalBezelActivityView activityViewForView:self.view];
    
    //Login Kinvey user
	[[AuthenticationHelper instance] loginWithUsername:self.usernameField.text
                                              password:self.passwordField.text
											 onSuccess:^{
                                                 
												 [DejalActivityView removeView];
                                                 
												 [self.navigationController dismissViewControllerAnimated:NO
																							   completion:^{
																								   if (self.completionBlock) {
																									   self.completionBlock();
																									   self.completionBlock = nil;
																								   }
																							   }];
											 }
											 onFailure:^(NSError *error) {
                                                 
												 [DejalBezelActivityView removeView];
                                                 
												 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                                                                                     message:error.localizedDescription ? error.localizedDescription : LOC(ERR_SMTH_WENT_WRONG)
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:LOC(OKAY)
                                                                                           otherButtonTitles:nil];
                                                 [alertView show];
											 }];
#endif
}


- (IBAction)textFieldEditingDidChange:(id)sender{
    
	[self updateButtons];
}

- (IBAction)demoPress:(id)sender {
    
    self.usernameField.text = @"demoSampleQuote";
    self.passwordField.text = @"123456";
    [self pressedLogin:sender];
}


#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
	if (textField == self.usernameField) {
		[self.passwordField becomeFirstResponder];
	}
	else {
		[self.passwordField resignFirstResponder];
	}
    
	return YES;
}

@end
