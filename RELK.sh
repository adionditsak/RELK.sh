#/bin/bash

: '
Create R (Redis) + ELK server from scratch on CentOS 6.5.

- You perhaps have to change the Elasticsearch network.host parameter to the internal IP of your server to use eg. GET on the URL from Kibana.
- You perhaps have to change the Kibana elasticsearch parameter to the actual URL with your internal IP to connect probably to the interface.
'

main() {
  dependencies
  elasticsearch
  logstash
  kibana
  start_and_chkconfig
}

dependencies() {
  echo ""
  echo "Dependencies"

  sleep 2

  yum -y install java-1.7.0-openjdk nginx redis
}

elasticsearch() {
  echo ""
  echo "Elasticsearch"

cat <<EOF >> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-1.1]
name=Elasticsearch repository for 1.1.x packages
baseurl=http://packages.elasticsearch.org/elasticsearch/1.1/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

  yum -y install elasticsearch

  sed -i '/network.host/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
  sed -i '/discovery.zen.ping.multicast.enabled/c\discovery.zen.ping.multicast.enabled: false' /etc/elasticsearch/elasticsearch.yml
  sed -i '/cluster.name/c\cluster.name: elasticsearch' /etc/elasticsearch/elasticsearch.yml

  chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/ /var/log/elasticsearch/
}

logstash() {
  echo ""
  echo "Logstash"

  sleep 2

cat <<EOF >> /etc/yum.repos.d/logstash.repo
[logstash-1.4]
name=logstash repository for 1.4.x packages
baseurl=http://packages.elasticsearch.org/logstash/1.4/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

  yum -y install logstash-1.4.2

cat <<EOF >> /etc/logstash/conf.d/default.conf
input {
  redis {
          host => "localhost"
          type => "redis"
          data_type => "list"
          key => "logstash"
  }
}

filter {

}

output {
  elasticsearch {
    host => "localhost"
    cluster => "elasticsearch"
  }

  stdout { codec => rubydebug }
}
EOF
}

kibana() {
  echo ""
  echo "Kibana"

  sleep 2

  cd /usr/share/nginx/html

  curl -O https://download.elasticsearch.org/kibana/kibana/kibana-3.0.1.tar.gz
  tar -xzvf kibana-3.0.1.tar.gz
  cd kibana-3.0.1
  mv * ..; cd ..; ls
}

start_and_chkconfig() {
  echo ""
  echo "Starting services + chkconfig"

  sleep 2

  chkconfig elasticsearch on
  chkconfig logstash on
  chkconfig redis on
  chkconfig nginx on

  /etc/init.d/elasticsearch start
  /etc/init.d/logstash start
  /etc/init.d/redis start
  /etc/init.d/nginx start
}

# INIT
main

# Install logstash agents on your agent servers and redirect output to Redis at this server:
: '
input {
        file {
                type => "secure-log"
                path => ["/var/log/secure"]
        }
}

output {
        redis {
                host => "ip"
                data_type => "list"
                key => "rediskey"
        }
}
'
