logstash:
  lookup:
    defaults:
    #  JAVA_HOME: /usr/lib/jvm/java-7-openjdk-amd64/jre/
      JAVACMD: /usr/bin/java
      LS_CONF_DIR: /etc/logstash/conf.d
      LS_GROUP: adm
      LS_HEAP_SIZE: 500m
      LS_HOME: /var/lib/logstash
      LS_JAVA_OPTS: '-Djava.io.tmpdir=${LS_HOME}'
      LS_LOG_FILE: /var/log/logstash/logstash.log
      LS_NICE: 19
      LS_OPEN_FILES: 16384
      LS_OPTS: ''
      LS_PIDFILE: /var/run/logstash.pid
      LS_USE_GC_LOGGING: 'true'
      LS_USER: logstash
    plugins:
      - name: contrib
        installed_name: 'logstash-contrib-*'
    config:
      manage:
        - defaults_file
        - comp_test_file
      comp_test_file:
        contents: |
          input {
            file {
              type => "syslog"

              # Wildcards work here
              path => [ "/var/log/messages", "/var/log/syslog", "/var/log/*.log" ]
            }
          }

          output {
            file {
              path => "/tmp/logstash-output-%{+YYYY-MM-dd}.log"
              }
          }


{# https://github.com/bechtoldt/saltstack-repos-formula #}
repos:
  lookup:
    repos:
      logstash:
        url: http://packages.elasticsearch.org/logstash/1.4/debian
        dist: stable
        comps:
          - main
        keyurl: http://packages.elasticsearch.org/GPG-KEY-elasticsearch

      elasticsearch:
        url: http://packages.elasticsearch.org/elasticsearch/1.4/debian
        dist: stable
        comps:
          - main
        keyurl: http://packages.elasticsearch.org/GPG-KEY-elasticsearch

elasticsearch:
  lookup:
    defaults:
      JAVA_HOME: /opt/java/jdk/current/src
      ES_HEAP_SIZE: {{ (salt['grains.get']('mem_total')/2)|round|int }}m
    settings:
      cluster:
        name: myindex
      node:
        name: {{ salt['grains.get']('fqdn') }}
        master: true
        data: true
      index:
        number_of_replicas: 0
      network:
        host: {{ salt['grains.get']('ip_interfaces:eth1', ['127.0.0.1'])[0] }}
      gateway:
        expected_nodes: 1
      discovery:
        zen:
          ping:
            multicast:
              enabled: false
    plugins:
      - name: elasticsearch-kopf
        installed_name: kopf
      - name: karmi/elasticsearch-paramedic
        installed_name: paramedic

{# https://github.com/bechtoldt/saltstack-java-formula #}
java:
  lookup:
    manage:
      jdk:
        current_ver: 8u20
        versions:
          8u20:
            source: file:///vagrant/share/misc/jdk-8u20-linux-x64.tar.gz
            source_hash: md5=ec7f89dc3697b402e2c851d0488f6299
            version: jdk1.8.0_20

{# https://github.com/bechtoldt/saltstack-sysctl-formula #}
# See http://www.elasticsearch.org/guide/en/elasticsearch/reference/1.x/setup-configuration.html#setup-configuration
sysctl:
  lookup:
    params:
      - name: vm.swappiness
        value: 0
      - name: vm.max_map_count
        value: 262144
