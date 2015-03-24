#!jinja|yaml

{% set datamap = salt['formhelper.get_defaults']('logstash', saltenv, ['yaml'])['yaml'] %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

logstash:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs|default({}) }}
  service:
    - {{ datamap.service.ensure|default('running') }}
    - name: {{ datamap.service.name|default('logstash') }}
    - enable: {{ datamap.service.enable|default(True) }}

{% if 'defaults_file' in datamap.config.manage|default([]) %}
  {% set f = datamap.config.defaults_file %}
logstash_defaults_file:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://logstash/files/defaults_file.' ~ salt['grains.get']('oscodename')) }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - template: jinja
    - context:
      datamap: {{ datamap|json }}
    - watch_in:
      - service: logstash
{% endif %}

{% if 'main' in datamap.config.manage|default([]) %}
  {% set f = datamap.config.main %}
logstash_config_main:
  file:
    - managed
    - name: {{ f.path|default('/etc/logstash/logstash.yml') }}
    - source: {{ f.template_path|default('salt://logstash/files/main') }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - template: jinja
    - context:
      datamap: {{ datamap|json }}
    - watch_in:
      - service: logstash
{% endif %}

{% if 'logging' in datamap.config.manage|default([]) %}
  {% set f = datamap.config.logging %}
logstash_config_logging:
  file:
    - managed
    - name: {{ f.path|default('/etc/logstash/logging.yml') }}
    - source: {{ f.template_path|default('salt://logstash/files/logging') }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - template: jinja
    - context:
      datamap: {{ datamap|json }}
    - watch_in:
      - service: logstash
{% endif %}

{% for p in datamap.plugins|default([]) %}
  {% set java_home = datamap.defaults.JAVA_HOME|default(false) %}
  {% if 'url' in p %}
    {% set url = '--url \'' ~ p.url ~ '\'' %}
  {% else %}
    {% set url = '' %}
  {% endif %}

logstash_install_plugin_{{ p.name }}:
  cmd:
    - run
    - name: {% if java_home %}export JAVA_HOME='{{ java_home }}' && {% endif %}{{ datamap.basepath|default('/usr/share/logstash') }}/bin/plugin -v -t 30s {{ url }} install '{{ p.name }}'
    - unless: test -d '{{ datamap.basepath|default('/usr/share/logstash') }}/plugins/{{ p.installed_name }}'
{% endfor %}
