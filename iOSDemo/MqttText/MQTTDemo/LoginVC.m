//
//  LoginVC.m
//  MqttText
//
//  Created by lqx on 16/11/9.
//  Copyright © 2016年 shanggu. All rights reserved.
//

#import "LoginVC.h"
#import <MQTTClient.h>
#import "AKAlertView.h"
#import "ChatVC.h"
#import "MQTTClientSSL.h"

#define SSL @"ssl://192.168.9.171"
#define SSL_PORT 61614

#define HOST @"localhost"
#define PORT 61613

@interface LoginVC ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *ps;
@property (weak, nonatomic) IBOutlet UITextField *un;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *act;
@property (nonatomic, strong)MQTTSession *session;
@end

@implementation LoginVC
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField  resignFirstResponder];
    return YES;
}
- (IBAction)login:(UIButton *)sender {
    if ([self verification]) {
        [self signIn:sender];
    }
    
}
- (void)signIn:(UIButton *)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 会话链接并设置超时时间
        self.act.hidden = NO;
        BOOL isSuccess = [self.session connectAndWaitTimeout:30];
        dispatch_async(dispatch_get_main_queue(), ^{

            self.act.hidden = YES;
            if (isSuccess) {
                ChatVC *vc = [[ChatVC alloc] initWithNibName:@"ChatVC" bundle:nil];
                vc.name = self.session.userName;
                vc.pass = self.session.password;
                NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
                [df setObject:vc.name forKey:@"name"];
                [df setObject:vc.pass forKey:@"pass"];
                
                [self.navigationController pushViewController:vc animated:YES];
                CATransition *animation = [CATransition animation];
                
                //设置运动时间
                animation.duration = 3.0;
                //设置运动type
                animation.type = @"rippleEffect";
                animation.subtype = kCATransitionFromLeft;
                //设置运动速度
                animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
                [self.navigationController.view.layer addAnimation:animation forKey:@"animation"];

            }else{
                AKAlertView* ak= [AKAlertView alertView:@"登录失败" des:@"请验证用户名、密码"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
                [ak show];
            }
            [self.session disconnect];
        });
    });
    
}
- (BOOL)verification{
    
    if ([_un.text isEqualToString:@""]) {
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"请输入用户名"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
        return NO;
    }else{
        self.session.userName = _un.text;
    }
    if ([_ps.text isEqualToString:@""]) {
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"请输入密码"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
        return NO;
    }else{
        self.session.password = _ps.text;
    }
    return YES;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self initSession];
//    MQTTClientSSL *ssl = [[MQTTClientSSL alloc] initWithUsername:@"admin" password:@"password" caCert:@"ca.crt" clientCert:@"client.crt" clientKey:@"client.key"];
//    [ssl connectToHost:SSL port:61680 keepAlive:30];
    
    
    
    
    //[self.view addSubview:view];
}
- (void)initSession{
    MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
    transport.host = HOST;
    transport.port = PORT;
    //创建一个任务
    self.session = [[MQTTSession alloc] init];
    //设置任务的传输类型
    self.session.transport = transport;
    //设置登录账号
    self.session.clientId = [[NSUUID UUID] UUIDString];
    //NSString* certificate = [[NSBundle bundleForClass:[MQTTSession class]] pathForResource:@"client" ofType:@"cer"];
    //_session.securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    //_session.securityPolicy.pinnedCertificates = @[ [NSData dataWithContentsOfFile:certificate] ];
    
    _session.securityPolicy.allowInvalidCertificates = YES;
    //_session.certificates = @[ [NSData dataWithContentsOfFile:certificate] ];

    
    self.session.userName = @"admin";
    self.session.password = @"password";
    BOOL isSuccess1 = [self.session connectAndWaitToHost:HOST
                                  port:PORT
                              usingSSL:NO
                               timeout:30];
    [_session connectToHost:HOST port:PORT usingSSL:NO];
}
-(void)initView{
    [self.act startAnimating];
    self.act.hidden = YES;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *name = [df objectForKey:@"name"];
    NSString *pass = [df objectForKey:@"pass"];
    if (name) {
        self.un.text = name;
    }
    if (pass) {
        self.ps.text = pass;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
