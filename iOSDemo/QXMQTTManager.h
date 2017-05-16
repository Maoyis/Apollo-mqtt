//
//  QXMQTTManager.h
//  MqttText
//
//  Created by shanggu on 16/11/8.
//  Copyright © 2016年 shanggu. All rights reserved.
//


/**
*qos=》
    qos=0最多一次:只发送一次（单次发送-broker不会返回结果码msgId），当服务器（broker）关闭即会丢包；
    qos=1至少一次：持续发送-两次连线（发送，确认接收（网络影响可能延迟丢失导致多次发送）），受网络影响容易重包；
    qos=2恰好一次：持续发送-四次连接（发送，确认接收，回复，确认回复）, 确保连接后发送，保证正好到达一次
*Clean Sessions=》
    一个Client 发送一个连接，这个连接中clean session 被设置为false,那么之前连接中有相同Client_id 的session 将会被重复使用。这就意味着Client断开了，订阅依然能收到消息。这就等同与同Apollo建立一个长订阅。
 如果 clean session 设置为true ，那么新session就开始了，其他的session会慢慢消失，删除。这就是Apollo中定义的普通的主题订阅。
*Topic Retained Messages=》
 如果消息被发布的同时retain 标记被设置（为true），消息将被主题记住，以至于新的订阅到达，最近的retain 消息会被发送到订阅者。比如说：你想发布一个参数，而且你想让最新的这个参数发布到总是可用的订阅了这个主题的客户端上，你就设置在PUBLISH 框架上设置retain 标签。
 注意：broker 重启过程中且QoS=0，retained 消息 不会被设置成retained。
*Last Will and Testament Message=》
 当Client第一次连接的时候，有一个will（‘遗嘱’） 消息和一个更QoS相关的消息会跟你有关。will消息是一个基础消息，这个基础消息只有在连接异常或者是掉线的时候才会被发送。一般用在你有一个设备，当他们掉了的时候，你需要知道。所以如果一个医疗Client从broker掉线，will消息将会作为一个闹钟主题发送，而且会被系统作为高优先级提醒。
 */

#import <Foundation/Foundation.h>
#import "MQTTClient.h"
#import <MQTTSessionManager.h>
#import "AKAlertView.h"

typedef void(^HandleMessageBlock)(NSData *data, NSString *topic, BOOL retain);
typedef void(^PublicSuccessBlock)(UInt16 msgID);

#pragma mark==============** 代理协议 **====================
@protocol QXMQTTManagerDelegate <NSObject>
/**
 当连接状态发生改变是调用
 */
-(void)mqttConnectionStateIsChange:(MQTTSessionManagerState)state;


@end


@interface QXMQTTManager : NSObject<MQTTSessionDelegate, MQTTSessionManagerDelegate>
//delegate->assign是指针赋值，不对引用计数操作，使用之后如果没有置为nil，可能就会产生野指针；而weak一旦不进行使用后，永远不会使用了，就不会产生野指针！
@property (nonatomic, weak)id<QXMQTTManagerDelegate> delegate;
/*!
	@property	handleMessageBlock
	@abstract	接收到消息自我处理回调
 */
@property (nonatomic, copy)HandleMessageBlock handleMessageBlock;
/*!
	@property	publicCallBackBlock
	@abstract	发布成功回调处理-（用于仿阻塞效果）；
 */
@property (nonatomic, copy)PublicSuccessBlock publicCallBackBlock;
/*!
	@property	mqttM
	@abstract	MQTTSessionManager正真的session管理；
 */
@property (nonatomic, strong)MQTTSessionManager *mqttM;
/*!
	@property	state
	@abstract   连接状态；
 */
@property (nonatomic, assign)MQTTSessionManagerState state;







#pragma mark==============** method **====================
/**
 获取单例
 */
+ (QXMQTTManager *)shareQXMQTTManager;
#pragma mark==============** Public message **====================
/**
 发布（推送）消息
 @param data   要发送的内容
 @param topic  要发布内容到broker的主题
 @param qos    发送的服务质量
 @param retain  =1：表示发送的消息需要一直持久保存（不受服务器重启影响），不但要发送给当前的订阅者，并且以后新来的订阅了此Topic name的订阅者会马上得到推送。备注：新来乍到的订阅者，只会取出最新的一个RETAIN flag = 1的消息推送。
                =0：仅仅为当前订阅者推送此消息。
 */
+ (UInt16)publicMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos retain:(BOOL)retain callBackBlock:(void (^)(UInt16 msgID))block;
/**
 针对已经订阅主题的客户端 发布（推送）消息(默认retain = 0)
 @param data   要发送的内容
 @param topic  要发布内容到broker的主题
 @param qos    发送的服务质量
 */
+ (UInt16)sendToOnlySubscribedClientMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos callBackBlock:(void (^)(UInt16 msgID))block;
/**
 发布（推送）消息并保存(默认retain = 1)
 @param data   要发送的内容
 @param topic  要发布内容到broker的主题
 @param qos    发送的服务质量
 */
+ (UInt16)sendAllClientMessage:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos callBackBlock:(void (^)(UInt16 msgID))block;
#pragma mark==============** subscrip massage **====================
/**
 订阅主题
 @param topic  要从broker订阅的主题
 @param qos    发送的服务质量
 */
+ (void)subscripMqttTopic:(NSString *)topic qos:(NSInteger)qos;

#pragma mark=========** Cancle subscrip massage **============
/**
 订阅主题
 @param topic  要从broker订阅的主题
 */
+ (void)cancleSubscripMqttTopic:(NSString *)topic;

#pragma mark==============** 连接初始化 **====================
/**
 设置MQTTSessionManager并连接
 @param host            服务器地址
 @param port            服务端端口号
 @param isTls           是否使用tls协议，mosca是支持tls的，如果使用了要设置成
 true
 @param keepLive        心跳时间，单位秒，每隔固定时间发送心跳包
 @param isClean         session是否清除，这个需要注意，==false，代表保持
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
                         retainFlag:(BOOL)retainFlag;
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
                            willQos:(NSInteger)qos;
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
                            willQos:(NSInteger)qos;

#pragma mark==============** 检测连接-》用于登录验证 **==============
+ (void)login:(NSString *)host port:(NSInteger)port isSuccessBlock:(void(^)(BOOL isSuccess))block;
#pragma mark==============** 手动断开 **====================
/**
 手动断开
 */
+ (void)mqttdisConnect;
@end
