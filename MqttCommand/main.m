//
//  main.m
//  MqttCommand
//
//  Created by anjubao on 4/13/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#include <stdio.h>

#include <pthread.h>
//int testFunc(int argc, char** argv);
//int testMqttClient(int argc, char** argv);

pthread_cond_t cont_t;
pthread_mutex_t mtx;

char enable_pub = 0;
const char *config_file;

#include "AJBMqttClient.h"
AJBMqttClient client;

typedef struct {
    int interval_ms;
    int times;
}PubConfig;

const char *configFile(int argc,const char *argv[]){
    
    if (argc<2) {
        return "config.cfg";
    }
    return argv[1];
}

void cfinish2(int sig)
{
//    char topic[255]={};
//    getSuggestTopic(topic, client.clientId);
//    mqttClient_unsubscribe(&client, "c/1234567/status");
    pthread_mutex_lock(&mtx);
    enable_pub = 0;
    pthread_mutex_unlock(&mtx);
    mqttClient_stopRunning(&client);
    
}

#pragma mark - callback

void on_connect(void *client1,int code){
//    MqttLog("on connect ok");
//    MqttLog("begin send signal");
    pthread_mutex_lock(&mtx);
    pthread_cond_signal(&cont_t);
    pthread_mutex_unlock(&mtx);
}
void on_subscribe(void *client1,int *qoses){
//    MqttLog("on subcribe ok");
    set_disable_subscribe(config_file, ((AJBMqttClient *)client1)->clientId, 1);
}

void on_receive(void *client1,char *topic,void *message,int len){
//    MqttLog("[USER receive] %s",(char *)message);
}

void on_hasErr(void *client1){
//    MqttLog("[USER hasErr] client error occured" );
    pthread_mutex_lock(&mtx);
    client.isConnected = false;
    pthread_mutex_unlock(&mtx);
}

void on_shouldSubscribe(void *client){
    char topic[255]={};
    getSuggestTopic(topic, ((AJBMqttClient *)client)->clientId);

    mqttClient_subscribe(client, topic, 2);
//    mqttClient_subscribe(client, "c/1234567/status", 2);
}


#pragma mark - main

void *publishMessage_test(void *config){
    PubConfig *cfg = (PubConfig *)config;
    MqttClientPublishInfo info = MqttPublishInfoIniter;
    struct timeval now,now2;
    int spentTime;
    
    int interval = cfg->interval_ms * 1000;
    int leftTime = interval;
    
    int i = 0;
    Timer timer;
    countdown_ms(&timer, client.keepAlive*1000);
    for (i = 0; i<cfg->times; i++) {
        pthread_mutex_lock(&mtx);
        
        if (enable_pub==0) {
            printf("stop the publisher\n");
            return "abort";
        }
        while (!client.isConnected) {
            MqttLog("begin wait");
            pthread_cond_wait(&cont_t, &mtx);
            MqttLog("wait finished");
        }
        pthread_mutex_unlock(&mtx);
        if (leftTime>0) {
            usleep(leftTime);
        }
        
        gettimeofday(&now, NULL);
        
        char state[MAX_CONTENT_LEN]={};
        sprintf(state,"num->%d msg->{\"type\":\"sync\",\"msg\":\"{\"id\":\"0f64c3e0-1e2c-11e6-bdcc-000c29b0af8d\",\"ltdCode\":\"2000001\",\"parkCode\":\"20160520001\",\"macCode\":\"LYJ-20160220110\",\"dataWcpay\":17,\"dataUnionpay\":0,\"dataCoupons\":0,\"dataCardinfo\":0,\"dataMonthlycard\":0,\"dataPetcard\":0,\"dataChargelog\":0,\"dataVisitorcar\":0,\"dataAppmemberfreetime\":0,\"dataAppmenberinfo\":0,\"dataAppparkingset\":0,\"dataAppvisitcar\":0,\"dataMcardprice\":0,\"dataFreesign\":0,\"dataCarenter\":0,\"dataWhitelist\":0,\"dataSoftchannel\":0,\"dataDownloadimg\":0,\"dataMorecarno\":0} sendtime->%ld",i,((long int)now.tv_usec)*1000);
        char topic[MAX_TOPIC_LEN]={};
        sprintf(topic, "c/%s/info",client.clientId);
        info.publishTopic = client.topic;
        info.publishContent = state;
        printf("[id = %d] ",i);
        int rc = mqttClient_publish2(&client, &info);
        if (rc == SUCCESS) {
            countdown_ms(&timer, client.keepAlive*1000);
        }
        else if(rc == SOCK_ERROR){
            MqttLog("Send Message( id = %d ) Failed,Retrying!",i);
            i--;
        }
        else{
            MqttLog("Send Message( id = %d ) Timeout,Retrying!",i);
            MqttLog("[WARNING network] publish message maybe timeout ----- id = %d",i);
            i--;
            if (expired(&timer)) {
                mqttClient_reconnect(&client);
            }
        }
        
        gettimeofday(&now2, NULL);
        spentTime = (now2.tv_sec - now.tv_sec)*1000000 + now2.tv_usec - now.tv_usec;
        leftTime = interval - spentTime;
    }
    return "finished";;
}

void startClient(const char *type,MqttConfigure config,MqttDispatcher dispatcher){
    if (strcmp(type, "sub")==0) {
        mqttClient_start2(&client, config, dispatcher);
        client.keepRunning(&client);
    }
    else{
        
        pthread_mutex_lock(&mtx);
        enable_pub = 1;
        pthread_mutex_unlock(&mtx);
        
        mqttClient_startPub(&client, config, dispatcher);
        pthread_t thread;
        PubConfig pubcfg = {};
        MqttLog("pub times:%d.%d",config.pubCount,config.pubInterval_ms);
        pubcfg.times = config.pubCount;
        pubcfg.interval_ms = config.pubInterval_ms;
        pthread_create(&thread, NULL, publishMessage_test, &pubcfg);
        char *result;
        pthread_join(thread, (void **)&result);
        
        
        if (strcmp(result, "abort")==0) {
            sleep(2);
            printf("abort the program...\n");
        }
        else{
            client.keepRunning(&client);
            printf("the result is %s\n",result);
        }
        
    }
    
}

void initLock(){
    pthread_mutex_init(&mtx, NULL);
    pthread_cond_init(&cont_t, NULL);
}

void pipeHandle(int signal){
    printf("pipe checked\n");
}

int main(int argc, const char * argv[]) {
    
    initLock();
    
    
    signal(SIGINT, cfinish2);
    signal(SIGTERM, cfinish2);
    
#ifdef SIGPIPE
    signal(SIGPIPE, pipeHandle);
#endif
    
    MqttConfigure config=DEFAULT_CONFIG;
    const char *cFile = configFile(argc,argv);
    config_file = cFile;
    get_mqtt_opts(cFile,&config);
    
    MqttDispatcher dispatcher = {};
    dispatcher.onConnect = on_connect;
    dispatcher.onSubscribe = on_subscribe;
    dispatcher.shouldReSubscribe = on_shouldSubscribe;
    dispatcher.onError = on_hasErr;
    dispatcher.onRecevie = on_receive;
    
//    startClient("pub", config, dispatcher);
//    return 0;
    if (argc == 1) {
        config.pubCount = 200000;
        config.pubInterval_ms = 10;
        strcpy(config.topic, "c/lukai-123456790/info");
//        strcpy(config.topic, "c/AJBMQTTTest-Rec-liucy/info");
        strcpy(log_file_path, "/tmp/mqtt.log");
        strcpy(config.host, "172.16.38.179");
        startClient("pub", config, dispatcher);
    }
    if (argc == 2) {
        startClient("sub",config,dispatcher);
    }
    if (argc == 3) {
        if (strcmp(argv[2], "sub")==0 || strcmp(argv[2], "pub")==0) {
            startClient(argv[2],config,dispatcher);
        }
        else{
            MqttLog("[ERR ] unsupport operation type : %s",argv[2]);
        }
        
    }
//    f64ff90e8ef57eec034d12b361a5383ff46b43e7

    
    /*
    newAJBMqttClient(&client,config.username, config.password, config.clientid,config.cleansession);
    client.keepAlive = config.keepAlive;    //default is 20s
    client.qos = 2;                      //default is QOS2
    client.timout_ms = config.timeout_ms;   //default is 2000ms
    client.aliveAttr = config.aliveAttr;
    MqttLog("%d-%d-%d-%d",client.aliveAttr.auto_con,client.aliveAttr.recon_int,client.aliveAttr.recon_max,client.aliveAttr.reconnecting);

//    setWill(&client, "c/test1234567890/info", "this is a will");
    
    MqttDispatcher dispatcher = {};
    dispatcher.onConnect = on_connect;
    dispatcher.onSubscribe = on_subscribe;

    
    mqttClient_setDispatcher(&client,dispatcher);
    mqttClient_connect(&client,config.host,config.port);
    
    char topic[255]={};
    getSuggestTopic(topic, client.clientId);
    mqttClient_subscribe(&client, topic, 2);
    mqttClient_subscribe(&client, "c/1234567/status", 2);
    
    dispatcher.shouldReSubscribe = on_shouldSubscribe;
    client.keepRunning(&client);
//        client.disconnect(&client);
   
    printf("%s\n",client.clientId);
     */
    return 0;
}
