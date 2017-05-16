//
//  ChatVC.m
//  MqttText
//
//  Created by lqx on 16/11/9.
//  Copyright © 2016年 shanggu. All rights reserved.
//

#import "ChatVC.h"
#import <MQTTSessionManager.h>
#import "AKAlertView.h"
#import <AdSupport/AdSupport.h>
#define GET_COLOR  [UIColor yellowColor]
#define SEND_COLOR [UIColor blueColor];



#define SSL @"ssl://192.168.9.171"
#define SSL_PORT 61614

#define HOST @"localhost"
#define PORT 61613
@interface ChatVC ()<MQTTSessionManagerDelegate, UITextFieldDelegate, UITextViewDelegate, QXMQTTManagerDelegate>
@property (nonatomic, strong)MQTTSessionManager *m;
@property (nonatomic, strong)QXMQTTManager *qxM;
@property (weak, nonatomic) IBOutlet UITextView *show;

@property (weak, nonatomic) IBOutlet UITextField *send;

@property (weak, nonatomic) IBOutlet UITextField *Qos;
@property (weak, nonatomic) IBOutlet UITextField *offLineTopic;
@property (weak, nonatomic) IBOutlet UIImageView *imgV;

@property (weak, nonatomic) IBOutlet UITextField *Recipient;
@property (weak, nonatomic) IBOutlet UISwitch *retainFlag;
@property (weak, nonatomic) IBOutlet UISwitch *clean;
@property (weak, nonatomic) IBOutlet UITextField *sendQos;
@property (weak, nonatomic) IBOutlet UITextField *subQos;
@property (weak, nonatomic) IBOutlet UITextField *subTopic;

@end

@implementation ChatVC

- (void)mqttConnectionStateIsChange:(MQTTSessionManagerState)state{
    switch (state) {
        case MQTTSessionManagerStateClosed: //连接已经关闭
            self.title = @"连接已经关闭";
            break;
        case MQTTSessionManagerStateClosing: //连接正在关闭
            self.title = @"连接正在关闭";
            break;
        case MQTTSessionManagerStateConnected: //已经连接
            self.title = @"已经连接";
            break;
        case MQTTSessionManagerStateConnecting: //正在连接中
            self.title = @"正在连接中";
            break;
        case MQTTSessionManagerStateError: //异常
            self.title = @"连接异常";
            break;
        case MQTTSessionManagerStateStarting: //开始连接
            self.title = @"开始连接";
        default:
            break;
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField  resignFirstResponder];
    return YES;
}
- (IBAction)retain:(UISwitch *)sender {
    [self initManager];
}
- (IBAction)subScripeTopic:(UIButton *)sender {
    [self subscripTopic:self.subTopic.text qos:self.subQos.text.integerValue];
}

- (IBAction)clean:(id)sender {
    [self initManager];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    switch (self.m.state) {
        case MQTTSessionManagerStateClosed: //连接已经关闭
            self.title = @"连接已经关闭";
            break;
        case MQTTSessionManagerStateClosing: //连接正在关闭
            self.title = @"连接正在关闭";
            break;
        case MQTTSessionManagerStateConnected: //已经连接
            self.title = @"已经连接";
            break;
        case MQTTSessionManagerStateConnecting: //正在连接中
            self.title = @"正在连接中";
            break;
        case MQTTSessionManagerStateError: //异常
            self.title = @"连接异常";
            break;
        case MQTTSessionManagerStateStarting: //开始连接
            self.title = @"开始连接";
        default:
            break;
    }
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.m disconnect];
}

- (IBAction)sendMessage:(id)sender {
    //发送消息,返回值msgid大于0代表发送成功
    NSData *data = [self sendJsonDataByMsg:self.send.text];
    NSInteger qos = self.sendQos.text.integerValue;
    [QXMQTTManager sendAllClientMessage:data topic:self.Recipient.text qos:qos callBackBlock:^(UInt16 msgID) {
        if (msgID>0 || qos==0) {
            [self showNewMsg:[self.send.text dataUsingEncoding:NSUTF8StringEncoding] color:[UIColor blueColor]];
        }else{
            [self showNewMsg:[@"发送失败" dataUsingEncoding:NSUTF8StringEncoding] color:[UIColor redColor]];
        }
        if (msgID) {
            self.title = [NSString stringWithFormat:@"第%d个消息发送完毕", msgID];
        }
    }];
    
}

- (void)showNewMsg:(NSData *)data color:(UIColor *)color{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg) {
        NSMutableAttributedString *old = [self.show.attributedText mutableCopy];
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"\n%@", msg]];
        NSString *temp = @"\n";
        [str addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(temp.length, msg.length)];
        [old appendAttributedString:str];
        self.show.attributedText = old;
        [self.show scrollRectToVisible:CGRectMake(0, self.show.contentSize.height-15, self.show.contentSize.width, 10) animated:YES];
    }
}

- (void)subscripTopic:(NSString *)topic qos:(NSInteger)qos{
    if (qos>=0&&qos<=2) {
        [QXMQTTManager subscripMqttTopic:topic qos:qos];
    }else{
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"Qos无效"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];

    }
}

- (NSData *)sendJsonDataByMsg:(id)msg{
    NSData *jsonData = nil;
    NSString *jsonStr = nil;
    NSDictionary * dic = nil;
    NSString *class = NSStringFromClass([msg classForCoder]);
    
    if (msg) {
        if ([msg isKindOfClass:[UIImage class]]) {
            jsonStr = [self UIImageToBase64Str:msg];
        }else if ([msg isKindOfClass:[NSString class]]){
            jsonStr = msg;
        }else if ([msg isKindOfClass:[NSData class]]){
            
        }
    }
    if (jsonStr) {
        dic = @{class:jsonStr};
        jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    return jsonData;
}

- (void)getMsgByJsonData:(NSData *)data{
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (dic) {
        for (NSString *class in dic) {
            NSString *jsonStr = dic[class];
            
            if ([NSClassFromString(class) isSubclassOfClass:[UIImage class]]) {
                UIImage *img = [self Base64StrToUIImage:jsonStr];
                self.imgV.image = img;
            }else if ([NSClassFromString(class) isSubclassOfClass:[NSString class]]){
                [self showNewMsg:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] color:GET_COLOR];
            }else if ([NSClassFromString(class) isSubclassOfClass:[NSData class]]){
                
            }
        }
    }else{
        
    }

}



- (void)sendPicture{
    UIImage *img = [UIImage imageNamed:@"2.jpg"];
    NSData *data = [self sendJsonDataByMsg:img];
    [QXMQTTManager sendAllClientMessage:data topic:self.Recipient.text qos:self.sendQos.text.integerValue callBackBlock:^(UInt16 msgID) {
        if (msgID>0 || self.sendQos.text.integerValue==0) {
            [self showNewMsg:[self.send.text dataUsingEncoding:NSUTF8StringEncoding] color:[UIColor blueColor]];
        }else{
            [self showNewMsg:[@"发送失败" dataUsingEncoding:NSUTF8StringEncoding] color:[UIColor redColor]];
        }
        if (msgID) {
            self.title = [NSString stringWithFormat:@"第%d个消息发送完毕", msgID];
        }
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.show.editable = NO;
    self.show.text = @"";
    self.qxM = [QXMQTTManager shareQXMQTTManager];
    self.qxM.delegate = self;
    //self.m = [[MQTTSessionManager alloc] init];
    //self.m.delegate = self.qxM;
    //[self initManager];
    //self.qxM.mqttM = self.m;
    [self setQxmqtt];
    __weak typeof(self) wf = self;
    self.qxM.handleMessageBlock = ^(NSData *data, NSString *topic, BOOL retain){
        [wf getMsgByJsonData:data];
    };
    [self initImgV];
    [self initNav];
}
- (void)setQxmqtt{
    NSData *data= [@"offline" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *uuid =  [[NSUUID UUID] UUIDString];
    [QXMQTTManager setMQTTSessionManagerByHost:HOST port:PORT keepLive:60 UserName:@"admin" passWord:@"password" willTopic:_offLineTopic.text willData:data willQos:_Qos.text.integerValue];
}
-(void)initNav{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clear)];
}
- (void)clear{
    self.show.text = @"";
}
- (void)subscripTopic{
    //订阅topic //0,1,2为Qos
    NSMutableDictionary *mDic = [[NSMutableDictionary alloc] init];
    [mDic setObject:self.Qos.text forKey:self.name];
    if ([self.offLineTopic.text isEqualToString:@""]) {
        [mDic setObject:self.Qos.text forKey:@"offline"];
    }else{
        [mDic setObject:self.Qos.text forKey:self.offLineTopic.text];
    }
    self.m.subscriptions = [mDic copy];
}

- (void)initImgV{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendPicture)];
    self.imgV.userInteractionEnabled = YES;
    [self.imgV addGestureRecognizer:tap];
}
- (void)initManager{
    NSData *data= [@"offline" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *uuid =  [[NSUUID UUID] UUIDString];
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    NSString* certificate1 = [[NSBundle bundleForClass:[MQTTSession class]] pathForResource:@"client" ofType:@"crt"];
    //NSString* certificate2 = [[NSBundle bundleForClass:[MQTTSession class]] pathForResource:@"ca" ofType:@"crt"];
    //policy.pinnedCertificates = @[[NSData dataWithContentsOfFile:certificate1]];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    
    BOOL tlsFlag = 0;
    if (tlsFlag) {
        [self.m connectTo:HOST port:PORT tls:0 keepalive:60 clean:false auth:true user:@"admin" pass:@"password" will:NO willTopic:nil willMsg:data willQos:2 willRetainFlag:false withClientId:adId securityPolicy:policy certificates:policy.pinnedCertificates];
    }else{
        [self.m connectTo:HOST //@"broker.mqttdashboard.com" //服务器地址
                     port:PORT //服务端端口号1883
                      tls:NO//是否使用tls协议，mosca是支持tls的，如果使用了要设置成true
                keepalive:60 //心跳时间，单位秒，每隔固定时间发送心跳包
                    clean:_clean.on //session是否清除，这个需要注意，如果味false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息
                     auth:0 //是否使用登录验证，和下面的user和pass参数组合使用/degiste验证
                     user:nil //用户名
                     pass:nil //密码
                willTopic:_offLineTopic.text //下面四个参数用来设置如果客户端离线发送给其它客户端消息，当前参数是哪个topic用来传输离线消息，这里的离线消息都指的是客户端掉线后发送的掉线消息
                     will:data //自定义的离线消息，约定好格式就可以了
                  willQos:_Qos.text.integerValue //接收离线消息的级别
           willRetainFlag:_retainFlag.on
             withClientId:adId]; //客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线

    }

    
    
     [self subscripTopic];
}
-(NSString *)UIImageToBase64Str:(UIImage *) image
{
    NSData *data = nil;
    if (UIImagePNGRepresentation(image) == nil) {
        data = UIImageJPEGRepresentation(image, 1.0);//0~1.0压缩比例
    } else {
        data = UIImagePNGRepresentation(image);
    }
    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedImageStr;
}
-(UIImage *)Base64StrToUIImage:(NSString *)encodedImageStr
{
    NSData *decodedImageData   = [[NSData alloc]initWithBase64Encoding:encodedImageStr];
    UIImage *decodedImage      = [UIImage imageWithData:decodedImageData];
    return decodedImage;
}
#pragma mark==============** delegate **====================
- (void)messageDelivered:(UInt16)msgID{
    NSLog(@"%d", msgID);
    NSLog(@"======我先触发=======");
}
-(void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained{
    [self getMsgByJsonData:data];
    
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
