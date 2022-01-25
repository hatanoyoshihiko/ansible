# ansible 各種モジュールの使い方

プレイブックでよく使うモジュール例をまとめました。

## yum

### パッケージのインストール

httpdをインストールします。

```
## httpdのインストール
- name: install / Install httpd
_  yum:
    name: httpd
    state: present _
```

### yum update

**name:** はパッケージ名を記載するところですが、 ** * **  とすることでインストール済の全てのパッケージのアップデートを行います。** state: latest ** で最新化します。

```
## yum updateの実施
- name: configure / update yum packages
  yum:
    name: '*'
    state: latest
    update_cache: yes
```
### リストを使う
このようなプレイブックは、
```
## httpdのインストール
- name: install / Install httpd
  yum:
    name: httpd
    state: present

  yum:
    name: php
    state: present
```

下記のように記述することが出来ます。

```
# httpdのインストール
- name: install / Install httpd
  yum:
    name: "{{ item }}"
    state: present
  with_items:
    - httpd
    - php
```

環境変数を含めるとこんな感じ。
```
# 環境変数
httpd_packages:
  - httpd
  - php
  - php-mysqlnd
  - php-pdo

# httpdのインストール
- name: install / Install httpd
  yum:
    name: "{{ item }}"
    state: present
  with_items: "{{ httpd_packages }}"
```

* [yum-ansible](http://docs.ansible.com/ansible/latest/modules/yum_module.html)

<br>

---

<br>

## サービスの制御
サービスの制御はsystemdモジュールかserviceモジュールを使います。

### systemdの場合

* サービスの起動

```
- name: Start httpd service
  systemd:
    name: httpd
    state: started
```

* サービスの停止

```
- name: Stop httpd service
  systemd:
    name: httpd
    state: stopped
```

* サービスの再起動

```
- name: retart httpd service
  systemd:
    name: httpd
    state: restarted
    daemon_reload: yes
```

* サービスのリロード

```
- name: reload service httpd
  systemd:
    name: httpd
    state: reloaded
```

* サービスの自動起動登録

```
- name: Start httpd service
  systemd:
    name: httpd
    state: started
    enabled: yes
```

* [systemd-ansible](http://docs.ansible.com/ansible/devel/modules/systemd_module.html)

### serviceの場合
systemdが使えないLinuxではserviceモジュールを使います。

* サービスの起動

```
- name: Start service httpd
  service:
    name: httpd
    state: started
```

* サービスの停止

```
- name: Stop httpd service
  service:
    name: httpd
    state: stopped
```

* サービスの再起動

```
- name: retart httpd service
  service:
    name: httpd
    state: restarted
```

* サービスのリロード

```
- name: reload service httpd
  service:
    name: httpd
    state: reloaded
```

* サービスの自動起動登録

```
- name: Start httpd service
  service:
    name: httpd
    enabled: yes
```

* [service-ansible](https://docs.ansible.com/ansible/2.5/modules/service_module.html)

<br>

---

<br>

## ファイルの操作

### fileモジュール

ファイル、ディレクトリの作成やファイルの所有者、所有グループ、パーミッション等を制御します。パーミッションを指定する際は **4桁** です。

* [file - ansible公式](http://docs.ansible.com/ansible/latest/modules/file_module.html)

### copyモジュール

ansibleマネジメントサーバからターゲットノードへファイルのコピーを行います。またファイルをコピーする際にバックアップを作成することも出来ます。パーミッションを指定する際は **4桁** です。

* [copy - ansible公式](http://docs.ansible.com/ansible/latest/modules/copy_module.html)

### templateモジュール
pythonのjinja2テンプレートファイルを配布する際に使用します。httpd.confのServerNameディレクティブなど、コンフィグ内で各サーバで値が異なる設定を動的に設定出来ます。

* jinja2テンプレート

{{ }}内の部分がtemplateモジュール実行時に動的に置き換わります。
if構文、for構文が使用可能です。

```
$ vi xxx.conf.j2
{% if hostvars[host].ansible_host is defined %}
clinet_ip = {{ hostvars[host].ansible_host }}
{% endif %}

{% for host in groups['all'] %}
  {{ hostvars[host]['ansible_ens160']['ipv4']['address'] }} {{ host }}
```

if構文の方は[hostvars[host].ansible_host]が定義されていた場合のみ、変数値を代入します。

for構文の方はgroups['all']]インベントリに記載した全てのターゲットノード名とIPアドレスを1行ずつ出力します。

192.168.100.1 web_server01
192.168.100.2 web_server02

* jinja2テンプレートを読み出すプレイブック

```
- name: configure / Setup configuration file
  template:
    src: xxx.conf.j2
    dest: /etc/xxx/xxx.cfg
    owner: root
    group: root
    mode: 0644
    backup: yes
```

* [template - ansible公式](http://docs.ansible.com/ansible/latest/plugins/lookup/template.html)

## SELINUX
/etc/selinux/configのselinuxがSELINUX=enforcingのとき、selinuxを無効化します。

```
- name: configure / Selinux off and disable
  selinux:
    state: disabled
  when: ansible_selinux.configu_mode == 'enforcing'
```

* [selinux - ansible公式](http://docs.ansible.com/ansible/latest/modules/selinux_module.html)

## cron

```
- name: configure / cron shutdown at AM 1:00
  cron:
    name: "daily shutdown"
    minute: "0"
    hour: "1"
    job: "/sbin/shutdown -h now"
    user: root
```

* [cron - ansible公式](http://docs.ansible.com/ansible/latest/modules/cron_module.html)

## プラステクニック

### リストを使う
このようなプレイブックは、

```yml
# httpdのインストール
- name: install / Install httpd
  yum:
    name: httpd
    state: present

  yum:
    name: php
    state: present
```

下記のように記述することが出来ます。
**"{{ item }}"** を変数として、インストールパッケージをwith_itemsのリストで定義します。

```yml
# httpdのインストール
- name: install / Install httpd
  yum:
    name: "{{ item }}"
    state: present
  with_items:
    - httpd
    - php
```

環境変数を含めるとこんな感じ。
パッケージリスト自体を **"{{ httpd_packages }}"** で定義しています。

```yml
# 環境変数
httpd_packages:
  - httpd
  - php
  - php-mysqlnd
  - php-pdo

# httpdのインストール
- name: install / Install httpd
  yum:
    name: "{{ item }}"
    state: present
  with_items: "{{ httpd_packages }}"
```
