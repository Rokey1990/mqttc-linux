//
//  main.m
//  MqttCommand
//
//  Created by anjubao on 4/13/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#include <stdio.h>

#include <pthread.h>

pthread_cond_t cont_t;
pthread_mutex_t mtx;

char enable_pub = 0;
const char *config_file;

#include "AJBMqttClient.h"

typedef struct {
    int interval_ms;
    int times;
}PubConfig;

typedef struct {
    int index;
    MqttConfigure   *config;
    MqttDispatcher  *dispatcher;
}SeesionConfig;

const char *configFile(int argc,const char *argv[]){
    
    if (argc<2) {
        return "config.cfg";
    }
    return argv[1];
}

void cfinish2(int sig)
{
    pthread_mutex_lock(&mtx);
    enable_pub = 0;
    pthread_cond_signal(&cont_t);
    pthread_mutex_unlock(&mtx);
    
}

void initLock(){
    pthread_mutex_init(&mtx, NULL);
    pthread_cond_init(&cont_t, NULL);
}

void pipeHandle(int signal){
    printf("pipe checked\n");
}


#pragma mark - callback

void on_connect(void *client1,int code){

    pthread_mutex_lock(&mtx);
    pthread_cond_signal(&cont_t);
    pthread_mutex_unlock(&mtx);
}
void on_subscribe(void *client1,int *qoses){

}

void on_receive(void *client1,char *topic,void *message,int len){

}

void on_hasErr(void *client1){
//    MqttLog("[USER hasErr] client error occured" );
}

void on_shouldSubscribe(void *client){
    char topic[255]={};
    getSuggestTopic(topic, ((AJBMqttClient *)client)->clientId);

    mqttClient_subscribe(client, topic, 2);
//    mqttClient_subscribe(client, "c/1234567/status", 2);
}



#pragma mark - publish

int startClientWithSessionConfig(AJBMqttClient *client,SeesionConfig *param){
    MqttConfigure *config = ((SeesionConfig *)param)->config;
    MqttDispatcher dispatcher = *((SeesionConfig *)param)->dispatcher;
    
    newAJBMqttClient(client,config->
                     username, config->password, config->clientid,config->cleansession);
    sprintf(client->clientId, "%s-%d",config->clientid,((SeesionConfig *)param)->index);
    
    client->keepAlive = config->keepAlive;    //default is 20s
    client->qos = 2;                      //default is QOS2
    client->timout_ms = config->timeout_ms;   //default is 2000ms
    client->aliveAttr = config->aliveAttr;
    
    MqttLog("%d-%d-%d-%d",client->aliveAttr.auto_con,client->aliveAttr.recon_int,client->aliveAttr.recon_max,client->aliveAttr.reconnecting);
    
    client->dispatcher = dispatcher;
    client->dispatcher.shouldReSubscribe = NULL;
    
    
    mqttClient_setDispatcher(client,dispatcher);
    
    client->keepworking = 1;
    int rc = mqttClient_connect(client,config->host,config->port);
    //    client->keepworking = 0;
    strcpy(client->topic, config->topic);
    
    client->dispatcher.shouldReSubscribe = dispatcher.shouldReSubscribe;
    
    return rc;
    
}

void mqttSendMsgs(AJBMqttClient *client,PubConfig config,char *topic){
    
}

void *mqttSendRunloop(void *param){
    
    
    if (pthread_detach(pthread_self())==0) {
        
        AJBMqttClient client;
        if(startClientWithSessionConfig(&client,(SeesionConfig *)param) == SUCCESS){
            PubConfig pubcfg;
            pubcfg.interval_ms = ((SeesionConfig *)param)->config->pubInterval_ms;
            pubcfg.times = ((SeesionConfig *)param)->config->pubCount;
            mqttSendMsgs(&client, pubcfg,((SeesionConfig *)param)->config->topic);
        }
        else{
            MqttLog("connect session failed,index :    %4d",((SeesionConfig *)param)->index);
        }
    }
    else{
        MqttLog("thread start failed,index :    %4d",((SeesionConfig *)param)->index);
    }
    
    return "finished";
}

#pragma mark - main

int main(int argc, const char * argv[]) {
    
    initLock();
    
    signal(SIGINT, cfinish2);
    signal(SIGTERM, cfinish2);
    
#ifdef SIGPIPE
    signal(SIGPIPE, pipeHandle);
#endif
    
    MqttConfigure config = DEFAULT_CONFIG;
    if (argc==1) {
        config_file="/Users/lukai/Desktop/Command-Demo/mqttc-linux/MqttCommand/config.cfg";
    }
    else{
        config_file = argv[1];
    }
    get_mqtt_opts(config_file, &config);
    
    MqttDispatcher dispatcher = {};
    dispatcher.onConnect = on_connect;
    dispatcher.onSubscribe = on_subscribe;
    dispatcher.shouldReSubscribe = on_shouldSubscribe;
    dispatcher.onError = on_hasErr;
    dispatcher.onRecevie = on_receive;
    
    for (int i =0 ; i<config.sessionCount; i++) {
        SeesionConfig session = {i+1,&config,&dispatcher};
        pthread_t thread;
        pthread_create(&thread, NULL, mqttSendRunloop, &session);
        usleep(1000*1000);
    }
    printf("start client finished\n");
    pthread_cond_wait(&cont_t, &mtx);
    printf("exit the client finished\n");
    
    return 0;
}
