
FROM centos
MAINTAINER Nirav Mehta <mehtanirav@live.com>

RUN yum -y install epel-release
RUN \
  yum -y update && \
  yum -y install python python-dev python-pip python-virtualenv tar \
  python-devel hostname wget unzip bzip2 git npm fontconfig

# Install JDK 7 Update 75
RUN wget -nv --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u75-b13/jdk-7u75-linux-x64.rpm"
RUN rpm -ivh jdk-7u75-linux-x64.rpm
RUN rm -f jdk-7u75-linux-x64.rpm
RUN alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_75/jre/bin/java 200000 && \
    alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.7.0_75/jre/bin/javaws 200000 && \
    alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_75/bin/javac 200000 && \
    alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_75/bin/jar 200000

RUN yum -y install blas-devel lapack-devel
RUN pip install --upgrade pip
RUN pip install --upgrade py4j numpy scipy pandas scikit-learn

# Install Maven
RUN wget -nv ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
RUN tar -xzf apache-maven-3.3.3-bin.tar.gz
RUN mv apache-maven-3.3.3 /opt/maven
RUN rm -f apache-maven-3.3.3-bin.tar.gz
ENV M2_HOME /opt/maven
ENV PATH $M2_HOME/bin:$PATH

# Environment variables
ENV PATH .:$PATH
ENV SCALA_BINARY_VERSION 2.10
ENV SCALA_VERSION $SCALA_BINARY_VERSION.4
ENV SPARK_PROFILE 1.5
ENV SPARK_VERSION 1.5.1
ENV HADOOP_PROFILE 2.6
ENV HADOOP_VERSION 2.7.1
ENV ZEPPELIN_HOME /opt/zeppelin

# Install Zeppelin
RUN git clone https://github.com/apache/incubator-zeppelin.git
RUN mv /incubator-zeppelin $ZEPPELIN_HOME
ENV PATH $ZEPPELIN_HOME/zeppelin-web/node:$PATH
ENV PATH $ZEPPELIN_HOME/zeppelin-web/node_modules/grunt-cli/bin:$PATH
WORKDIR $ZEPPELIN_HOME
RUN npm update -g npm
RUN npm install -g grunt-cli grunt bower

RUN mvn clean \
    install \
    -pl '!flink,!ignite,!phoenix,!postgresql,!tajo' \
    -Phadoop-$HADOOP_PROFILE \
    -Dhadoop.version=$HADOOP_VERSION \
    -Pspark-$SPARK_PROFILE \
    -Dspark.version=$SPARK_VERSION \
    -Ppyspark \
    -Dscala.version=$SCALA_VERSION \
    -Dscala.binary.version=$SCALA_BINARY_VERSION \
    -Dmaven.findbugs.enable=false \
    -Drat.skip=true \
    -Dcheckstyle.skip=true \
    -DskipTests \
    "$@"

RUN rm -rf .git
WORKDIR /

ENV PYTHONPATH /usr/lib64/python2.7/site-packages:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip:$PYTHONPATH

# Install Spark
RUN wget -nv http://d3kbcqa49mib13.cloudfront.net/spark-1.5.1-bin-hadoop2.6.tgz
RUN tar -xzf spark-1.5.1-bin-hadoop2.6.tgz
RUN mv spark-1.5.1-bin-hadoop2.6 /opt/spark
ENV SPARK_HOME /opt/spark

# Cleanup
RUN rm -f /spark-1.5.1-bin-hadoop2.6.tgz
RUN rm -rf /scikit-learn
RUN rm -rf /opt/maven
RUN rm -rf /root/.m2
RUN rm -rf /root/.npm
RUN rm -rf /root/tmp
RUN yum -y remove npm nodejs
RUN yum clean all

EXPOSE 6080 6081

ENV ZEPPELIN_PORT 6080
ENV MASTER local[*]

ENV ZEPPELIN_NOTEBOOK_DIR /zeppelin/notebooks
ENV ZEPPELIN_CLASSPATH /zeppelin/addjars
VOLUME /zeppelin/notebooks
VOLUME /zeppelin/addjars

# update boot script
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
