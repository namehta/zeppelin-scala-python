#!/usr/bin/env bash

rtotalram="$($_CMD free -mt | grep Mem: | awk '{ print $2 }')"

rmaxjvm=`expr $rtotalram - 1024`
export ZEPPELIN_INTP_MEM="-Xmx"$rmaxjvm"m -XX:MaxPermSize=512m"
echo ZEPPELIN_INTP_MEM=$ZEPPELIN_INTP_MEM

rexemem=`expr $rmaxjvm - 1536`
export ZEPPELIN_JAVA_OPTS="-Dspark.executor.memory="$rexemem"m"
echo ZEPPELIN_JAVA_OPTS=$ZEPPELIN_JAVA_OPTS

/opt/zeppelin/bin/zeppelin.sh start
