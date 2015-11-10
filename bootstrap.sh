#!/usr/bin/env bash

rtotalram="$($_CMD free -mt | grep Mem: | awk '{ print $2 }')"

rmaxjvm=`expr $rtotalram - 1024`
export ZEPPELIN_INTP_MEM="-Xmx"$rmaxjvm"m -XX:MaxPermSize=512m"
echo ZEPPELIN_INTP_MEM=$ZEPPELIN_INTP_MEM

rexemem=`expr $rmaxjvm - 1536`
export SPARK_EXECUTOR_MEMORY=$rmaxjvm"m"
echo SPARK_EXECUTOR_MEMORYM=$SPARK_EXECUTOR_MEMORY

/opt/zeppelin/bin/zeppelin.sh start
