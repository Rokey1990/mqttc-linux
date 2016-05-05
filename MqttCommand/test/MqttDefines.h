//
//  AJBMqttDefines.h
//  LKMqttDemo
//
//  Created by anjubao on 4/12/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#ifndef MqttDefines_h
#define MqttDefines_h

#include <stdio.h>

#include "MQTTPacket.h"
#include "MQTTClient.h"

#define ENABLE_LOG  1

#ifndef bool
typedef char  bool;
#endif
#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif

typedef enum QoS MqttServiceQos;

typedef struct {
    char *willContent;
    char *willTopic;
    MqttServiceQos qos;
    int retain;
}MqttClientWillInfo;

typedef struct{
    char *publishContent;
    char *publishTopic;
    MqttServiceQos qos;
    int dup;
    int retain;
}MqttClientPublishInfo;

#define MqttPublishInfoIniter {NULL,NULL,QOS2,0,0}

/*
typedef enum {
    MqttMsgTypeConnect,
    MqttMsgTypeDisconnect,
    MqttMsgTypeRecevieMsg,
    MqttMsgTypePublish,
    MqttMsgTypeSubcribe,
    MqttMsgTypeUnsubcribe,
    MqttMsgTypeSetWill,
    MqttMsgTypeClearWill,
}MqttMsgType;

typedef struct{
    MqttMsgType msgType;
    int code;
    void *msgData;
}MqttMessage;
*/
typedef void (*MqttClientMsgHandler)(void *client,MQTTMessage *message);

typedef void (*MqttClientOnConnect)(void *client,int code);
typedef void (*MqttClientOnDisconnect)(void *client,int code);
typedef void (*MqttClientOnRecevieMsg)(void *client,MQTTMessage message);
typedef void (*MqttClientOnSubcribe)(void *client,MqttServiceQos *qoses);
typedef void (*MqttClientOnUnsubcribe)(void *client,int code);
typedef void (*MqttClientOnPublish)(void *client,int code);
typedef struct {
    MqttClientOnConnect     callback_onConnect;
    MqttClientOnDisconnect  callback_onDisconnect;
    MqttClientOnPublish     callback_onPublish;
    MqttClientOnRecevieMsg  callback_onRecevie;
    MqttClientOnSubcribe    callback_onSubcribe;
    MqttClientOnUnsubcribe  callback_unSubcribe;
}MqttDispatcher;

typedef enum {
    MqttReturnCodeOverflow = -2,
    MqttReturnCodeFailed = -1,
    MqttReturnCodeSuccess = 0,
}MqttReturnCode;



#endif /* AJBMqttDefines_h */
