CUR_PATH=`pwd`
echo $CUR_PATH
cd $CUR_PATH
rm mqttc/*
cp main.m mqttc/main.c
cp test/AJBMqttClient.* mqttc/
cp test/Mqtt* mqttc/
cp src/*.* mqttc/
cp src/*/*.* mqttc/
cp src/*/*/*.* mqttc/
cp config.cfg mqttc/
gcc mqttc/*.c -o mqttc/Mqttc
./mqttc/Mqttc mqttc/config.cfg
#./mqttc config.cfg
