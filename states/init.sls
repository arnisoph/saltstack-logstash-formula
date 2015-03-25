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

{% for c in datamap.config.manage if c != 'defaults_file' %}
  {% set f = datamap['config'][c]|default({}) %}
logstash_config_{{ c }}:
  file:
    - {{ c.ensure|default('managed') }}
    - name: {{ f.path|default('/etc/logstash/conf.d/' ~ c ~ '.conf') }}
    {# - source: { { f.template_path|default('salt://logstash/files/main') } #}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    {# - template: jinja #}
    {# - context:
      datamap: {{ datamap|json }} #}
  {% if 'contents' in f %}
    - contents_pillar: logstash:lookup:config:{{ c }}:contents
  {% endif %}
    - watch_in:
      - service: logstash
{% endfor %}

{% for p in datamap.plugins|default([]) %}
  {% set java_home = datamap.defaults.JAVA_HOME|default(false) %}

logstash_install_plugin_{{ p.name }}:
  cmd:
    - run
    - name: {% if java_home %}export JAVA_HOME='{{ java_home }}' && {% endif %}{{ datamap.basepath }}/bin/plugin install '{{ p.name }}'
    - unless: test "$(find {{ datamap.basepath }}/vendor/logstash/ -mindepth 1 -maxdepth 1 -type d -name '{{ p.installed_name|default(p.name) }}')"
{% endfor %}
