//
//  AJBMqttClient.c
//  LKMqttDemo
//
//  Created by anjubao on 4/12/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#include "AJBMqttClient.h"
#include <string.h>
#define strlen(str) strlen((char *)str)
#include <stdlib.h>
#include <stdio.h>

#include "MQTTClient.h"

#if ENABLE_LOG
#define MqttLog(fmt,...) {printf(fmt,##__VA_ARGS__);printf("\n");}
#else
#define MqttLog(fmt,...) {}
#endif

#define MessageMake publishMessage

#pragma mark - client callback
void on_messageArrived(MessageData* md)
{
    MQTTMessage* message = md->message;
    
//    MqttLog("%.*s\t", md->topicName->lenstring.len, md->topicName->lenstring.data);
//    MqttLog("%.*s----qos:%d----dup:%d", (int)message->payloadlen, (char*)message->payload,message->qos,message->dup);
    
}


#pragma mark - client func


void mqttClientDispatcher(void *client,MQTTMessage *message){
    
}

void mqttClient_runloop(AJBMqttClient *client){
    while (client->isConnected) {
        MQTTYield(&client->c, client->timout_ms);
        if (client->c.ping_outstanding > client->keepAlive) {
            printf("client run end ---- %d\n",client->c.ping_outstanding);
            reconnect:
            mqttClient_disconnect(client);
            sleep(2);
            mqttClient_reconnect(client);
            if (!client->isConnected) {
                goto reconnect;
            }
            client->subcribe(client,"testTopic",QOS2);
        }
    }
}

MqttReturnCode mqttClient_connect(AJBMqttClient *client, char *host,int port){
    
    
    
    int rc = 0;//return code of mqtt function
    static unsigned char buf[100];
    static unsigned char readbuf[100];
    if (host != client->host) {
        strcpy(client->host, host);
    }
    
    client->port = port;
    
    NewNetwork(&client->n);
    rc = ConnectNetwork(&client->n, host, port);
    MqttLog("connect network: %d",rc);
    MQTTClient(&client->c, &client->n, client->timout_ms, buf, 100, readbuf, 100);
    
    MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
    
    data.willFlag = 0;
    data.MQTTVersion = 3;
    data.clientID.cstring = client->clientId;
    data.username.cstring = client->username;
    data.password.cstring = client->password;
    data.keepAliveInterval = client->keepAlive;
    data.cleansession = client->cleanSession;
    
//    data.willFlag = 1;
//    data.will.message.cstring = "This is a will";
//    data.will.qos = 1;
//    data.will.retained = 0;
//    data.will.topicName.cstring = "WillTopic";
    
    
    rc = MQTTConnect(&client->c, &data);
    MqttLog("connect to: tcp://%s:%d, result:%d",host,port,rc);
    client->isConnected = (rc==SUCCESS);

    for (int i = 0; i < MAX_MESSAGE_HANDLERS; ++i)
    {
        if (client->c.messageHandlers[i].topicFilter == 0)
        {
            client->c.messageHandlers[i].topicFilter = "testTopic_121";
            client->c.messageHandlers[i].fp = on_messageArrived;
            break;
        }
    }
    
    return rc;
}

MqttReturnCode mqttClient_reconnect(AJBMqttClient *client){
    return mqttClient_connect(client, client->host, client->port);
}

void mqttClient_disconnect(AJBMqttClient *client){
    MQTTDisconnect(&client->c);
    client->n.disconnect(&client->n);
    client->isConnected = false;
}


MQTTMessage publishMessage(MqttClientPublishInfo *publishData,unsigned short messageId){
    MQTTMessage message;
    message.payload = publishData->publishContent;
    message.retained = publishData->retain;
    message.payloadlen = strlen(message.payload);
    message.dup = publishData->dup;
    message.qos = publishData->qos;
    message.id = messageId;
    return message;
}

MqttReturnCode mqttClient_publishData(AJBMqttClient *client,
                            MqttClientPublishInfo *publishData){
    MQTTMessage message = MessageMake(publishData, client->getMessageId(client));
    int rc = MQTTPublish(&client->c, publishData->publishTopic, &message);
    
    return rc;
}

MqttReturnCode mqttClient_subcribe(AJBMqttClient *client,char *topic,MqttServiceQos qos){
    int rc = FAILURE;
    rc = MQTTSubscribe(&client->c, topic, qos, on_messageArrived);
    MqttLog("subcribe: %d",rc);
    return rc;
}

MqttReturnCode mqttClient_unsubcribe(AJBMqttClient *client,char *topic){
   return MQTTUnsubscribe(&client->c, topic);
}

int getMessageId(AJBMqttClient *client){
    client->messageId++;
    return client->messageId;
}

void NewAJBMqttClient(AJBMqttClient *client,char *username,char *password,char *clientId,bool keepSession){
    if (username)
        strcpy(client->username, username);
    if (password)
        strcpy(client->password, password);
    strcpy(client->clientId, clientId);
    client->timout_ms = 2000;
    client->keepAlive = 10;
    client->qos = QOS2;
    client->cleanSession = keepSession^0x01;
    client->connect     = mqttClient_connect;
    client->disconnect  = mqttClient_disconnect;
    client->publish     = mqttClient_publishData;
    client->subcribe    = mqttClient_subcribe;
    client->unsubcribe  = mqttClient_unsubcribe;
    client->keepRunning = mqttClient_runloop;
    client->getMessageId = getMessageId;
}