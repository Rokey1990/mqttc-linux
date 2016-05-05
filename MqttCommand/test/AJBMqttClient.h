//
//  AJBMqttClient.h
//  LKMqttDemo
//
//  Created by anjubao on 4/12/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#ifndef AJBMqttClient_h
#define AJBMqttClient_h

#include "MqttDefines.h"

struct AJBMqttClient{
    /**
     *  用户名，选填，默认为空串
     */
    char username[32];
    /**
     *  密码，选填，默认为空串
     */
    char password[32];
    /**
     *  客户端ID，每个客户端需所对应的唯一ID
     */
    char clientId[32];
    /**
     *  服务器地址，可以为域名和ip
     */
    char host[32];
    /**
     *  服务端端口，默认1883
     */
    int port;
    /**
     *  客户端接收超时时间，默认为1000ms
     */
    short timout_ms;
    /**
     *  客户端心跳时间间隔，默认为10s
     */
    short keepAlive;
    /**
     *  publish的消息ID，初始化为随机值
     */
    unsigned short messageId;
    /**
     *  服务质量，默认为QOS2(一次)，可以为QOS1（至少一次）、QOS0（最多一次）
     */
    MqttServiceQos qos;
    /**
     *  重连时是否清理回话状态标志，为0则不清楚，否则清除回话
     */
    char cleanSession;
    /**
     *  客户端接收到消息的回调
     */
    MqttClientMsgHandler on_recvMessage;
//    void (*on_recvMessage)()
    /**
     *  客户端事件分发器，包含命令请求结果的回调及收到消息的回调
     */
    MqttDispatcher dispather;
    /**
     *  回调函数需要引用的数据
     */
    void *usedobj;
    /**
     *  客户端是否处于连接状态，true连接状态，false非连接状态
     */
    bool isConnected;
    /**
     *  mqtt客户端
     */
    Client c;
    /**
     *  mqtt网络结构体，依赖于硬件平台
     */
    Network n;
    /**
     *  连接服务器，client为需要连接的客户端，host:连接服务器地址，port端口
     */
    MqttReturnCode (*connect)(struct AJBMqttClient *client,char *host,int port);
    /**
     *  断开客户端连接
     */
    void (*disconnect)(struct AJBMqttClient *client);
    /**
     *  发送数据，client为需要发送数据的客户端，info为需要发送的数据
     */
    MqttReturnCode (*publish)(struct AJBMqttClient *client,MqttClientPublishInfo *info);
    /**
     *  订阅话题，topic:需要订阅的话题话题，qos订阅话题的服务质量
     */
    MqttReturnCode (*subcribe)(struct AJBMqttClient *client,char *topic,MqttServiceQos qos);
    /**
     *  取消订阅，topic需要取消订阅的话题
     */
    MqttReturnCode (*unsubcribe)(struct AJBMqttClient *client,char *topic);
    /**
     *  运行runloop，客户端进入持续接收数据的状态
     */
    void (*keepRunning)(struct AJBMqttClient *client);
    /**
     *  获取messageid
     */
    int (*getMessageId)(struct AJBMqttClient *client);
};

typedef struct AJBMqttClient AJBMqttClient;

void NewAJBMqttClient(AJBMqttClient *client,char *username,char *password,char *clientId,bool keepSession);

MqttReturnCode mqttClient_connect(AJBMqttClient *client, char *host,int port);
MqttReturnCode mqttClient_reconnect(AJBMqttClient *client);
void           mqttClient_disconnect(AJBMqttClient *client);
void           mqttClient_setMessageHandler(AJBMqttClient *client);
MqttReturnCode mqttClient_subcribe(AJBMqttClient *client,char *topic,MqttServiceQos qos);
MqttReturnCode mqttClient_unsubcribe(AJBMqttClient *client,char *topic);
MqttReturnCode mqttClient_publishData(AJBMqttClient *client,MqttClientPublishInfo *publishData);
int            getMessageId(AJBMqttClient *client);

#endif /* AJBMqttClient_h */
