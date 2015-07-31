//
//  ViewController.m
//  BackgroundSession
//
//  Created by 马明晗 on 15/7/30.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import "ViewController.h"
#import "BackgroundSessionManager.h"
#import "LDRLogger.h"

@interface ViewController ()

- (IBAction)tapUpload:(id)sender;

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

- (void)viewDidAppear:(BOOL)animated {
   
}

- (IBAction)tapUpload:(id)sender {
    NSData *data = [@"tttttttttt" dataUsingEncoding:NSUTF8StringEncoding];
    
    for (int i = 0 ; i < 200; i++) {
        [[BackgroundSessionManager sharedManager] sendBatchDataRequestByPostBody:nil
                                                                            data:data
                                                                            date:[[NSDate date] timeIntervalSince1970]
                                                                     finishBlock:^(NSString *request) {
                                                                         DDLogInfo(@"finish:%@",[NSDate date]);
                                                                     } failBlock:^(NSInteger errorCode) {
                                                                         DDLogInfo(@"fail:%@",[NSDate date]);
                                                                     }];
    }
}

@end
