//
//  ViewController.m
//  HelloIntilery
//
//  Copyright © 2016 Intilery.com Ltd. All rights reserved.
//

#import "ViewController.h"
#import "Intilery.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];

    [self loseFocus:self.email withTouch:touch];
    [self loseFocus:self.colour withTouch:touch];
    [self loseFocus:self.film withTouch:touch];
    
    [super touchesBegan:touches withEvent:event];
}

-(void)loseFocus:(UITextField *)field withTouch:(UITouch *)touch {
    if ([field isFirstResponder] && [touch view] != field) {
        [field resignFirstResponder];
    }
}

- (IBAction)handleSendEventTapped:(UIButton *)sender {
    NSLog(@"Sending Event");
    
    Intilery *intilery = [Intilery sharedInstance];
    [intilery track:@"Select Movie" properties:@{@"Movie.Title":@"The Jungle Book"}];
}

- (IBAction)handleSignOut:(UIButton *)sender {
    NSLog(@"Sending sign out event");
    
    [[Intilery sharedInstance] track:@"Sign Out"];
}

- (IBAction)handleIdentify:(UIButton *)sender {
    NSLog(@"Identifying as customer with email %@", [self.email text]);
    
    [[Intilery sharedInstance] track:@"Sign In"
                          properties:@{@"Customer.Email":[self.email text]}];
}

- (IBAction)handleSetVisitorProperties:(UIButton *)sender {
    [[Intilery sharedInstance] setVisitorProperties:@{@"Favourite Colour": [self.colour text], @"Favourite Film": [self.film text]}];
}

- (IBAction)handleGetVisitorProperties:(UIButton *)sender {
    [[Intilery sharedInstance] getVisitorProperties:@[@"Favourite Colour", @"Favourite Film"] callback:
     ^(NSDictionary * properties) {
         [self.properties setText:[NSString stringWithFormat:@"Film: %@, Colour: %@",
                                   [properties valueForKeyPath:@"Favourite Film.value"],
                                   [properties valueForKeyPath:@"Favourite Colour.value"]]];
     }];
}



@end
