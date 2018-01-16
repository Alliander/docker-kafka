FROM openjdk:8u151-jre-alpine3.7

MAINTAINER Alliander - Sander Schoot Uiterkamp

ENV KAFKA_VERSION=1.0.0
ENV SCALA_VERSION=2.12
ENV PROMETHEUS_JAVAAGENT_VERSION=0.2.0
ENV KAFKA_UID=1234
ENV KAFKA_GID=1234

RUN apk upgrade --update && \
	apk add --update unzip wget curl jq bash && \
	MIRROR=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred') && \
	URL="${MIRROR}kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" && \
	wget -q ${URL} -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
	echo "downloaded /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz from ${URL}" && \
	mkdir /opt && \
	tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && \
	ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && \
	mkdir /opt/prometheus && \
	wget -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${PROMETHEUS_JAVAAGENT_VERSION}/jmx_prometheus_javaagent-${PROMETHEUS_JAVAAGENT_VERSION}.jar -O /opt/prometheus/jmx_prometheus_javaagent-${PROMETHEUS_JAVAAGENT_VERSION}.jar && \
	echo "downloaded /opt/prometheus/jmx_prometheus_javaagent-${PROMETHEUS_JAVAAGENT_VERSION}.jar" && \
	apk del wget unzip curl jq && \
	rm -rf /tmp/* /var/tmp/* /var/cache/apk/* && \
	addgroup -g ${KAFKA_GID} kafka && \
	adduser -D -G kafka -s /bin/bash -u ${KAFKA_UID} kafka && \
	chown -R kafka:kafka /opt

ENV KAFKA_HOME /opt/kafka
ENV PATH ${PATH}:${KAFKA_HOME}/bin

USER kafka

WORKDIR /opt/kafka

ADD config/server.properties config/
ADD config/kafka-0-8-2.yml /opt/prometheus/config/

ENV KAFKA_OPTS="$KAFKA_OPTS -javaagent:/opt/prometheus/jmx_prometheus_javaagent-${PROMETHEUS_JAVAAGENT_VERSION}.jar=7071:/opt/prometheus/config/kafka-0-8-2.yml"

