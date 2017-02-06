FROM ubuntu
MAINTAINER Fabian M. Borschel <fabian.borschel@commercetools.de>

ENV PIO_VERSION 0.10.0
ENV SPARK_VERSION 1.5.1
ENV ELASTICSEARCH_VERSION 1.4.4
ENV HBASE_VERSION 1.0.0

ENV PIO_HOME /apache-predictionio-${PIO_VERSION}-incubating
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV MAVEN_VERSION 3.3.9
RUN apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends curl openjdk-8-jdk libgfortran3 python-pip git unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-${MAVEN_VERSION} /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN curl -O http://apache.panu.it/incubator/predictionio/${PIO_VERSION}-incubating/${PIO_HOME}.tar.gz \
    && tar -xvzf ${PIO_HOME}.tar.gz -C / && mkdir -p ${PIO_HOME}/vendors \
    && rm ${PIO_HOME}.tar.gz
COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh

RUN curl -O http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop2.6.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop2.6.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-hadoop2.6.tgz

RUN curl -O https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml

RUN curl -O http://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz
COPY files/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
    
RUN pip install --upgrade pip
RUN pip install setuptools
RUN pip install predictionio

#triggers fetching the complete sbt environment
#RUN ${PIO_HOME}/sbt/sbt -batch

EXPOSE 8000 7070 9300
