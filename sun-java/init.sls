{%- from 'sun-java/settings.sls' import java with context %}

{#- require a source_url - there is no default download location for a jdk #}

{%- if java.source_url is defined %}

  {%- set archive_file = salt['file.join'](java.prefix, salt['file.basename'](java.source_url)) %}

java-install-dir:
  file.directory:
    - name: {{ java.prefix }}
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

download-jdk-archive:
  cmd.run:
    - name: curl {{ java.dl_opts }} -o '{{ archive_file }}' '{{ java.source_url }}'
    - unless: test -d {{ java.java_real_home }} || test -f {{ archive_file }}
    - require:
      - file: java-install-dir

  {%- if java.source_hash %}

# FIXME: We need to check hash sum separately, because
# ``archive.extracted`` state does not support integrity verification
# for local archives prior to and including Salt release 2016.11.6.
#
# See: https://github.com/saltstack/salt/pull/41914

check-jdk-archive:
  module.run:
    - name: file.check_hash
    - path: {{ archive_file }}
    - file_hash: {{ java.source_hash }}
    - onchanges:
      - download-jdk-archive
    - require_in:
      - archive: unpack-jdk-archive

  {%- endif %}

unpack-jdk-archive:
  archive.extracted:
    - name: {{ java.prefix }}
    - source: file://{{ archive_file }}
    - archive_format: tar
    - user: root
    - group: root
    - if_missing: {{ java.java_real_home }}
    - onchanges:
      - cmd: download-jdk-archive

create-java-home:
  alternatives.install:
    - name: java-home
    - link: {{ java.java_home }}
    - path: {{ java.java_real_home }}
    - priority: 30
    - onlyif: test -d {{ java.java_real_home }} && test ! -L {{ java.java_home }}
    - require:
      - archive: unpack-jdk-archive

update-java-home-symlink:
  file.symlink:
    - name: {{ java.java_home }}
    - target: {{ java.java_real_home }}

remove-jdk-archive:
  file.absent:
    - name: {{ archive_file }}
    - require:
      - archive: unpack-jdk-archive

{%- endif %}
