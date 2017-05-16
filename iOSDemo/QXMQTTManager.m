//
//  QXMQTTManager.m
//  MqttText
//
//  Created by shanggu on 16/11/8.
//  Copyright © 2016年 shanggu. All rights reserved.
//

#import "QXMQTTManager.h"


@interface QXMQTTManager ()

@property (nonatomic, strong) UILabel  *promptLabel;
@property (nonatomic ,strong) UIWindow *window;

@end

@implementation QXMQTTManager

- (UIWindow *)window{
    if (!_window) {
        _window = [UIApplication sharedApplication].keyWindow;
    }
    return _window;
}
- (UILabel *)promptLabel{
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, _window.frame.size.height/2-20, _window.frame.size.width-200, 40)];
        _promptLabel.text = @"发送成功";
        _promptLabel.textColor = [UIColor whiteColor];
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.alpha = 0.f;
        _promptLabel.backgroundColor = [UIColor blackColor];
    }
    return  _promptLabel;
}
- (void)setMqttM:(MQTTSessionManager *)mqttM{
    if (![mqttM isEqual:_mqttM]) {
        if (_mqttM) {
            [_mqttM removeObserver:self forKeyPath:@"state"];
        }
        _mqttM = mqttM;
        [_mqttM addObserver:self
                  forKeyPath:@"state"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew                context:nil];
    }else{
        NSLog(@"++++++++fkl++++++++");
    }
}


+(MQTTSessionManager *)getSessionManager{
    MQTTSessionManager *m = [self shareQXMQTTManager].mqttM;
    if (m) {
        return m;
    }else{
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"请设置并添加MQTTSessionManager"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
        return nil;
    }
}
#pragma mark==============** 检测连接-》用于登录验证 **==============
+ (void)login:(NSString *)host port:(NSInteger)port isSuccessBlock:(void(^)(BOOL isSuccess))block{
    MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
    transport.host = @"localhost";
    transport.port = 61613;
    //创建一个任务
    MQTTSession *session = [[MQTTSession alloc] init];
    //设置任务的传输类型
    session.transport = transport;
    //设置登录账号
    session.clientId = [[NSUUID UUID] UUIDString];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 会话链接并设置超时时间
        BOOL isSuccess = [session connectAndWaitTimeout:30];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(isSuccess);
            if (isSuccess) {
                
                }else{
                AKAlertView* ak= [AKAlertView alertView:@"登录失败" des:@"请验证用户名、密码"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
                [ak show];
            }
            [session disconnect];
        });
    });
}

#pragma mark==============** 获取单例 **====================
+ (QXMQTTManager *)shareQXMQTTManager{
    static QXMQTTManager *m = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        m = [[QXMQTTManager alloc] init];
    });
    return m;
}
#pragma mark==============** disConnect **====================
/**
 断开
 */
+ (void)mqttdisConnect{
    MQTTSessionManager *m = [self getSessionManager];
    if (!m) {
        return;
    }
    [m disconnect];
}
#pragma mark==============** setup Connection **====================
/**
 设置并连接-> 默认isAuth=ture
 默认retainFlag=false——通常没必要
 默认isClean=false——通常接收离线消息
 默认isTls=false——未使用TLS
 */
+ (void)setMQTTSessionManagerByHost:(NSString *)host
                               port:(NSInteger)port
                           keepLive:(NSInteger)keepLive
                           UserName:(NSString *)name
                           passWord:(NSString *)pass
                          willTopic:(NSString *)topic
                           willData:(NSData *)data
                            willQos:(NSInteger)qos{
    [self setMQTTSessionManagerByHost:host port:port isTls:false keepLive:keepLive UserName:name passWord:pass willTopic:topic willData:data willQos:qos];
    
}
/**
 设置并连接-> 默认isAuth=ture
            默认retainFlag=false——通常没必要
            默认isClean=false——通常接收离线消息
 */
+ (void)setMQTTSessionManagerByHost:(NSString *)host
                              port:(NSInteger)port
                              isTls:(BOOL)isTls
                           keepLive:(NSInteger)keepLive
                           UserName:(NSString *)name
                           passWord:(NSString *)pass
                          willTopic:(NSString *)topic
                           willData:(NSData *)data
                            willQos:(NSInteger)qos{
    [self setMQTTSessionManagerByHost:host port:port isTls:isTls keepLive:keepLive clean:false auth:true UserName:name passWord:pass willTopic:topic willData:data willQos:qos];
    
}
/**
 设置并连接->默认retainFlag=false——通常没必要
 */
+ (void)setMQTTSessionManagerByHost:(NSString *)host
                              port:(NSInteger)port
                              isTls:(BOOL)isTls
                           keepLive:(NSInteger)keepLive
                              clean:(BOOL)isClean
                               auth:(BOOL)isAuth
                           UserName:(NSString *)name
                           passWord:(NSString *)pass
                          willTopic:(NSString *)topic
                           willData:(NSData *)data
                            willQos:(NSInteger)qos{
    [self setMQTTSessionManagerByHost:host port:port isTls:isTls keepLive:keepLive clean:isClean auth:isAuth UserName:name passWord:pass willTopic:topic willData:data willQos:qos retainFlag:false];
}

/**
 设置MQTTSessionManager并连接
 @param host            服务器地址
 @param port            服务端端口号
 @param isTls           是否使用tls协议，mosca是支持tls的，如果使用了要设置成        
                        true
 @param keepLive        心跳时间，单位秒，每隔固定时间发送心跳包
 @param isClean         session是否清除，这个需要注意，如果味false，代表保持        
                        登录，如果客户端离线了再次登录就可以接收到离线消息
 @param isAuth          是否使用登录验证，和下面的user和pass参数组合使用
 @param name            用户名
 @param pass            密码
 @param topic           下面四个参数用来设置如果客户端离线发送给其它客户端消      
                        息，当前参数是哪个topic用来传输离线消息，这里的离线消息都指的是客户端掉线后发送的掉线消息
 @param data            自定义的离线消息，约定好格式就可以了
 @param qos             接收离线消息的级别
 @param retainFlag      是否保持存储以备后续订阅Client可以接受离线消息()
 */
+ (void)setMQTTSessionManagerByHost:(NSString *)host
                              port:(NSInteger)port
                              isTls:(BOOL)isTls
                           keepLive:(NSInteger)keepLive
                              clean:(BOOL)isClean
                               auth:(BOOL)isAuth
                           UserName:(NSString *)name
                           passWord:(NSString *)pass
                          willTopic:(NSString *)topic
                           willData:(NSData *)data
                            willQos:(NSInteger)qos
                         retainFlag:(BOOL)retainFlag{
    QXMQTTManager *m = [self shareQXMQTTManager];
    m.mqttM = [[MQTTSessionManager alloc] init];
    m.mqttM.delegate = m;
    [m.mqttM connectTo:host
                 port:port
                  tls:isTls
            keepalive:keepLive
                clean:isClean
                 auth:isAuth
                 user:name
                 pass:pass
            willTopic:topic
                 will:data
              willQos:qos
       willRetainFlag:retainFlag
         withClientId:[[NSUUID UUID] UUIDString]]; //客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线
    
}

#pragma mark==============** Public message **====================
/**
 针对已经订阅主题的客户端 发布（推送）消息(默认retain = 0)
 */
+ (UInt16)sendToOnlySubscribedClientMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos callBackBlock:(void (^)(UInt16 msgID))block{
    return [self publicMessage:data topic:topic qos:qos retain:false callBackBlock:block];
    
}
/**
 发布（推送）消息并保存(默认retain = 1)
 */
+ (UInt16)sendAllClientMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos callBackBlock:(void (^)(UInt16 msgID))block{
    UInt16 msgid = [self publicMessage:data topic:topic qos:qos retain:true callBackBlock:block];
    return msgid;
}
/**
 public message
 */
+ (UInt16)publicMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos retain:(BOOL)retain callBackBlock:(void (^)(UInt16 msgID))block{
    MQTTSessionManager *m = [self getSessionManager];
    if (!m) {
        return -1;
    }
    UInt16 msgid;
    if (qos>=0&&qos<=2) {
        msgid = [m sendData:data topic:topic qos:qos retain:true];
    }else{
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"Qos无效"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
        msgid = -1;
    }
    QXMQTTManager *qxM = [self shareQXMQTTManager];
    qxM.publicCallBackBlock = block;
    return msgid;
}
#pragma mark==============** subscrip massage **====================
/**
 subscrip massage
 */
+ (void)subscripMqttTopic:(NSString *)topic qos:(NSInteger)qos{
    MQTTSessionManager *m = [self getSessionManager];
    if (!m) {
        return;
    }
    if (qos>=0&&qos<=2) {
        NSMutableDictionary *mDic = [m.subscriptions mutableCopy];
        [mDic setObject:@(2) forKey:topic];
        m.subscriptions = [mDic copy];
    }else{
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"Qos无效"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
        
    }
}
#pragma mark=========** Cancle subscrip massage **============
+ (void)cancleSubscripMqttTopic:(NSString *)topic{
    MQTTSessionManager *m = [self getSessionManager];
    if (!m) {
        return;
    }
    NSMutableDictionary *mDic = [m.subscriptions mutableCopy];
    if ([mDic objectForKey:topic]) {
        [mDic removeObjectForKey:topic];
    }
    m.subscriptions = [mDic copy];
}

#pragma mark==============** delegate **====================
//发送成功回调
- (void)messageDelivered:(UInt16)msgID{
    if (self.publicCallBackBlock) {
        self.publicCallBackBlock(msgID);
        self.publicCallBackBlock = nil;
    }
    
    [UIView animateWithDuration:2.0 animations:^{
        [self.window addSubview:_promptLabel];
        self.promptLabel.alpha = 1.f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.promptLabel.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self.promptLabel removeFromSuperview];
        }];
    }];
    
}

-(void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained{

    if (self.handleMessageBlock) {
        self.handleMessageBlock(data, topic, retained);
    }else{
        AKAlertView* ak= [AKAlertView alertView:@"提示" des:@"请设置接收消息后的处理方式（handleMessageBlock）"  type:AKAlertFaild effect:AKAlertEffectDrop sureTitle:@"确定" cancelTitle:@"取消"];
        [ak show];
    }
}
#pragma mark==============** 状态监听 **====================
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
  
        if ([self.delegate respondsToSelector:@selector(mqttConnectionStateIsChange:)]) {
            [self.delegate mqttConnectionStateIsChange:self.mqttM.state];
        }
        switch (self.mqttM.state) {
            case MQTTSessionManagerStateClosed: //连接已经关闭
                self.state = MQTTSessionManagerStateClosed;
                break;
            case MQTTSessionManagerStateClosing: //连接正在关闭
                self.state = MQTTSessionManagerStateClosing;
                break;
            case MQTTSessionManagerStateConnected: //已经连接
                self.state = MQTTSessionManagerStateConnected;
                break;
            case MQTTSessionManagerStateConnecting: //正在连接中
                self.state = MQTTSessionManagerStateConnecting;
                break;
            case MQTTSessionManagerStateError: //异常
                self.state = MQTTSessionManagerStateError;
                break;
            case MQTTSessionManagerStateStarting: //开始连接
                self.state = MQTTSessionManagerStateStarting;
            default:
                break;
        }
    }
}



#pragma mark==============** Funcation **====================
- (NSString *)getTime{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY/MM/dd hh:mm:ss SS"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    return dateString;
}
#pragma mark==============** 释放时=移除监听 **====================


- (void)dealloc{
    [self.mqttM removeObserver:self forKeyPath:@"state"];
}

@end
