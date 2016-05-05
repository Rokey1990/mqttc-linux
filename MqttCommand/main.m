//
//  main.m
//  MqttCommand
//
//  Created by anjubao on 4/13/16.
//  Copyright © 2016 anjubao. All rights reserved.
//

#import <Foundation/Foundation.h>
//int testFunc(int argc, char** argv);
int testMqttClient(int argc, char** argv);
#include "AJBMqttClient.h"
AJBMqttClient client;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NewAJBMqttClient(&client,NULL, NULL, "ios_test11117",true);
        
        
        mqttClient_connect(&client,"172.16.38.179",1883);
        mqttClient_subcribe(&client, "topic5", QOS2);
//        client.subcribe(&client,"topic5",QOS2);
        client.keepRunning(&client);
        client.disconnect(&client);
        
        printf("%s\n",client.clientId);
    }
    return 0;
}
