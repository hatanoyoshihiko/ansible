# ansible 環境変数

## 変数

ansible で扱える変数はプレイブックの様々な場所で定義出来ます。
よく使うのは ansible で元々定義されている変数、ユーザで独自に定義する変数です。
プレイブックで参照する際は **"{{ 変数名 }}"** で呼び出します。

下記が変数定義例です。

```yml
main.yml
yum_packages:
  httpd
  php
  mariadb

httpd_versions: 2.4
php_ini: /etc/php.ini
database_name: database
```

変数呼び出し例です。

```yml
yum.yml
- name: Install packages
  yum:
    name: "{{ yum_packages }}"
    state: latest
```

## よく使う変数

### エクストラ変数

プレイブック実行時に指定する変数。1 番優先度の高い変数です。
**-e** の後に定義します。

```bash
$ ansible-playbook -e "user=ansible password=ansible"
```

### environment variables

ansible 独自定義の環境変数です。LANG や PATH、SHELL など

```yml
- hosts: client
  environment:
    http_proxy: http://proxy.example.com:8080
    https_proxy: https://proxy.example.com:8080
```

### プレイ変数

プレイブック内で定義される変数です。タスク変数の方が優先順位が高いです。ネストが深い方が優先されるようです。

```yml
プレイ変数
- hosts: all
  vars:
    package: httpd
  tasks:
    yum:
      name: {{ package }}
      state: present

タスク変数
- hosts: test
  tasks:
    vars:
      package: httpd
    yum:
      name: {{ package }}
      state: present
```

### インベントリ変数

インベントリファイル内で定義される変数です。
また group_vars、host_vars ディレクトリに変数用ファイルを置いて指定することも可能です。

```bash
# ホスト変数
ansible_host=がホスト変数。

[webservers]
web01 ansible_host=172.16.0.21
web02 ansible_host=172.16.0.22

# グループ変数
[xxx:vars]で定義された変数。

[webservers:vars]
http_port=80
https_port=443
```

- 参照例

```yml
- name: configure / Bootstrap first MariaDB Galera Cluster node. Ignore the Warning.
  command: service mysql bootstrap
  args:
    creates: "/var/lib/mysql/{{ ansible_host }}.pid"
```

**"{ ansible_host }"** は 172.16.0.21、172.16.0.22 で展開されます。

### レジスタ変数

タスク実行結果の戻り値を格納する変数です。

下記では **\$ uname -r** で取得した値を **result** 変数に格納します。
result 変数内の rc の戻り値が 0 の場合に result 変数の内容を echo で表示させています。
register: result の **result** は、result である必要はなく、独自定義で OK です。
プレイブック内の debug ディレクティブでは result 変数に何が格納されたのかを確認するために値を出力しています。

- レジスタ変数を格納するプレイブック

```yml
result.yml
tasks:
  - name: get kerner version
    shell: uname -r
    register: result

  - name: debug registered variable
    debug:
      var: result

  - name: echo
    command: echo {{ result }}
    when: result.rc == 0
```

- result.yml プレイブックの結果

```bash
$ ansible-playbook -i test.ini test.yml -v

PLAY [all] ***********************************************************************************

TASK [Gathering Facts] ***********************************************************************
ok: [172.16.1.20]

TASK [get uname] *****************************************************************************
changed: [172.16.1.20] => {"changed": true, "cmd": "uname -r", "delta": "0:00:00.002496", "end": "2018-04-12 13:09:13.165791", "rc": 0, "start": "2018-04-12 13:09:13.163295", "stderr": "", "stderr_lines": [], "stdout": "4.14.26-54.32.amzn2.x86_64", "stdout_lines": ["4.14.26-54.32.amzn2.x86_64"]}

TASK [debug "result"] ************************************************************************
ok: [172.16.1.20] => {
    "result": {
        "changed": true,
        "cmd": "uname -r",
        "delta": "0:00:00.002496",
        "end": "2018-04-12 13:09:13.165791",
        "failed": false,
        "rc": 0,
        "start": "2018-04-12 13:09:13.163295",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "4.14.26-54.32.amzn2.x86_64",
        "stdout_lines": [
            "4.14.26-54.32.amzn2.x86_64"
        ]
    }
}

TASK [echo] **********************************************************************************
changed: [172.16.1.20] => {"changed": true, "cmd": ["echo", "{stderr_lines:", "[],", "uchanged:", "True,", "uend:", "u2018-04-12 13:09:13.165791,", "failed:", "False,", "ustdout:", "u4.14.26-54.32.amzn2.x86_64,", "ucmd:", "uuname -r,", "urc:", "0,", "ustart:", "u2018-04-12 13:09:13.163295,", "ustderr:", "u,", "udelta:", "u0:00:00.002496,", "stdout_lines:", "[u4.14.26-54.32.amzn2.x86_64]}"], "delta": "0:00:00.002034", "end": "2018-04-12 13:09:13.436480", "rc": 0, "start": "2018-04-12 13:09:13.434446", "stderr": "", "stderr_lines": [], "stdout": "{stderr_lines: [], uchanged: True, uend: u2018-04-12 13:09:13.165791, failed: False, ustdout: u4.14.26-54.32.amzn2.x86_64, ucmd: uuname -r, urc: 0, ustart: u2018-04-12 13:09:13.163295, ustderr: u, udelta: u0:00:00.002496, stdout_lines: [u4.14.26-54.32.amzn2.x86_64]}", "stdout_lines": ["{stderr_lines: [], uchanged: True, uend: u2018-04-12 13:09:13.165791, failed: False, ustdout: u4.14.26-54.32.amzn2.x86_64, ucmd: uuname -r, urc: 0, ustart: u2018-04-12 13:09:13.163295, ustderr: u, udelta: u0:00:00.002496, stdout_lines: [u4.14.26-54.32.amzn2.x86_64]}"]}

PLAY RECAP ***********************************************************************************
172.16.1.20                : ok=4    changed=2    unreachable=0    failed=0
```

### ファクト変数

ターゲットノードのシステム情報が格納されている変数です。
独自にファクト変数を定義することも出来ますが、通常は自動で取得される変数値のため、やむを得ない事情がある場合を除いて独自定義しない方が良いです。

- ターゲットノードのファクト変数を調べる場合

```yml
facts_check.yml
- hosts: all
  tasks:
    - name: debug "var hostvars"
      debug:
        var: hostvars

TASK [debug "var hostvars"]
ok: [172.16.1.20] => {
    "hostvars": {
        "172.16.1.20": {
            "ansible_all_ipv4_addresses": [
                "172.16.1.20"
            ],
```

- ansible マネジメントサーバのファクト変数を調べる場合

```bash
$ ansible localhost -m setup
"ansible_eth0": {
            "active": true,
            "device": "eth0",
            "hw_timestamp_filters": [],
            "ipv4": {
                "address": "172.16.1.10",
                "broadcast": "172.16.1.255",
                "netmask": "255.255.255.0",
                "network": "172.16.1.0"

```

- ファクト変数の定義
  上記の **"address": "172.16.1.10"** を参照するには、
  インデント順に、ansible_eth0、ipv4、address をドットで繋げることで参照出来ます。
  **"{{ ansible_eth0.ipv4.address }}"** で指定します。
  **{{ ansible_eth0['ipv4']['address'] }}** でも参照出来ます。

下記は eth0 の IP アドレスが 172.16.0.21 の場合に実行されるタスクです。

```yml
- name: configure / Setup configuration file
  template:
    src: keepalived.conf.j2
    dest: /etc/keepalived/keepalived.conf
    owner: root
    group: root
    mode: 0644
  when: ansible_eth0.ipv4.address == "172.16.0.21"
```

他にもファクト変数を利用して OS のディストリビューションによって実行するタスクを分けることが出来ます。

下記プレイブックでは OS が RedHat 系の場合はシャットダウン、Debian 系の場合は再起動させます。

```yml
tasks:
  - name: "shutdown RedHat"
    command: /sbin/shutdown -h now
    when: ansible_os_family == "RedHat"

tasks:
  - name: "reboot Debian"
    command: /sbin/reboot
    when: ansible_os_family == "Debian"
```

### マジック変数

ansible で定義済の変数です。

インベントリファイルに記載された値や ansible の環境情報が格納されます。

| 変数名                   | 概要                                                   | 備考                           |
| ------------------------ | :----------------------------------------------------- | :----------------------------- |
| hostvars                 | 各ターゲットノードのファクト変数を集めた変数           |
| group_names              | 指定したターゲットノードが所属するグループの一覧       | インベントリファイルで定義する |
| groups                   | 全グループとターゲットノード一覧                       |
| inventory_hostname       | インベントリファイルに定義されたホスト名               |
| inventory_hostname_short | ホスト名の最初の.(ドット)までの短縮名                  |
| inventory_dir            | インベントリファイルのディレクトリパス                 |
| inventory_file           | カレントディレクトリからのインベントリファイルの位置   |
| playbook_dir             | カレントディレクトリからのプレイブックディレクトリパス |
| play_hosts               | インベントリに定義され、認識されたホスト一覧           |
| ansible_play_hosts       | プレイが実行されているホストの一覧                     |
| ansible_version          | ansible のバージョン情報                               |
| ansible_check_mode       | 実行時に--check を付けた場合に true になる             |
| envirionment             | 予約済変数                                             |

- jinja2 テンプレートでの変数参照
  groups 変数内の[test_servers]に所属するホストを for の host 変数に格納し、hostvars 変数内の IP アドレスとホスト名をループさせます。

```jinja2
test.conf.j2
{% for host in groups['test_servers'] if host != 'localhost' %}
{{ hostvars[host]['ansible_eth0']['ipv4']['address'] }} {{ host }}
{% endfor %}
```

- テンプレートファイルの配布

インベントリファイル

```ini
test.ini
[test_servers]
test_server01 ansible_host=172.16.1.20
```

プレイブック

```yml
test.yml
- hosts: all
  become: true
  tasks:
    - name: get uname
      template:
        src: /etc/ansible/test/test.conf.j2
        dest: /home/ec2-user/test.conf
        owner: ec2-user
        group: ec2-user
        mode: 0644
        backup: yes
```

- template モジュールで配布した結果

```ini
test.conf
172.16.1.20 test_server01
```

<br>

---

<br>

## 変数の読み込み順

数字が小さいものほど優先される（上書き）

| NO. | 変数の優先順位        | 意味                                    | 備考 |
| --- | :-------------------- | :-------------------------------------- | :--- |
| 1   | extra vars            | コマンド実行時に渡す変数                |
| 2   | task vars             | 指定したタスク内で定義する変数          |
| 3   | block vars            | 指定したブロック内で定義する変数        |
| 4   | role and include vars | ロールの vars や include で定義した変数 |
| 5   | play vars_files       | プレイ内の var_files で定義した変数     |
| 6   | play vars_prompt      | プレイ内の vars_prompt で定義した変数   |
| 7   | play vars             | プレイ内の vars で定義した変数          |
| 8   | set_facts             | set_fatcts モジュールで定義した変数     |
| 9   | registered vars       | レジスタ変数に保存した変数              |
| 10  | host facts            | 各ターゲットノードのファクト変数        |
| 11  | playbook host_vars    | host_vars に分割した変数                |
| 12  | playbook group_vars   | group_vars に分割した変数               |
| 13  | inventory host_vars   | インベントリに定義されたホスト変数      |
| 14  | inventory group_vars  | インベントリに定義されたグループ変数    |
| 15  | inventory vars        | インベントリに定義された変数            |
| 16  | role defaults         | ロールのデフォルト変数                  |
