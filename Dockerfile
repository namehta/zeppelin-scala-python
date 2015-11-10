
FROM centos
MAINTAINER Nirav Mehta <mehtanirav@live.com>

RUN yum -y install epel-release
RUN \
  yum -y update && \
  yum -y install python python-dev python-pip python-virtualenv tar \
  gcc gcc-c++ python-devel hostname wget unzip git

# Install JDK 7 Update 75
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u75-b13/jdk-7u75-linux-x64.rpm"
RUN rpm -ivh jdk-7u75-linux-x64.rpm
RUN rm -f jdk-7u75-linux-x64.rpm
RUN alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_75/jre/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.7.0_75/jre/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_75/bin/javac 200000
RUN alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_75/bin/jar 200000

# Install Spark
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-1.5.1-bin-hadoop2.6.tgz
RUN tar -xzf spark-1.5.1-bin-hadoop2.6.tgz
RUN mv spark-1.5.1-bin-hadoop2.6 /opt/spark
ENV SPARK_HOME /opt/spark

RUN yum -y install blas-devel lapack-devel
RUN pip install --upgrade pip
RUN pip install --upgrade numpy scipy pandas
RUN git clone https://github.com/scikit-learn/scikit-learn.git
WORKDIR /scikit-learn
RUN git checkout 0.17.X
RUN python setup.py build
RUN python setup.py install
WORKDIR /

# Install Maven
RUN wget ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
RUN tar -xzf apache-maven-3.0.5-bin.tar.gz
RUN mv apache-maven-3.0.5 /opt/maven
RUN rm -f apache-maven-3.0.5-bin.tar.gz
ENV M2_HOME /opt/maven
ENV PATH $M2_HOME/bin:$PATH

# Install Zeppelin
RUN git checkout https://github.com/apache/incubator-zeppelin.git
WORKDIR /incubator-zeppelin
RUN mvn clean package -Pspark-1.5.1 -Ppyspark -DskipTests
RUN rm -rf .git
WORKDIR /
COPY incubator-zeppelin /opt/zeppelin
ENV ZEPPELIN_HOME /opt/zeppelin
ENV PYTHONPATH /usr/lib64/python2.7/site-packages:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip:$PYTHONPATH

#Remove Maven
RUN rm -rf /opt/maven

EXPOSE 6080 6081

ENV ZEPPELIN_PORT 6080
ENV MASTER local

ENV ZEPPELIN_NOTEBOOK_DIR /notebooks
ENV ZEPPELIN_CLASSPATH /addjars

# update boot script
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
