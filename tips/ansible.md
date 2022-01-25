# ansible実践集

-   [環境変数について](./var.md)
-   [モジュールについて](./module.md)

## 概要
* ansibleとはエージェントレス構成管理ツールの1種です。Linux、Windows等に対応しています。(netappのONTAPやciscoのIOSも一部対応)  
* ansibleを実行するサーバがあり、実行されるサーバがあります。  
* サーバの設定情報などをプレイブックというファイルにまとめ、sshでターゲットノードに接続した後に実行されます。（実行されるコードは自動的にpythonコード化されます)
* プレイブックはタスクという実行単位で処理され、モジュールと呼ばれる機能で実行されます。(yumモジュールやsystemdモジュールなど)
* ansibleでの設定は何度繰り返しても常に同じ状態（べき等性）が保たれるようにできています（一部、工夫が必要）

### ansibleで出来ること
* ファイルの配布
* カーネルパラメータ設定
* パッケージのインストール
* ユーザ管理
* シェルコマンドの実行  
* ネットワーク設定
* 正規表現でのファイル書き換え
etc...

### 構成
* ansibleマネジメントサーバ（ansibleを実行するサーバ、以降、ansibleサーバ）  
* ansibleターゲットノード（ansibleを実行されるサーバ）  
※ マネジメントサーバとターゲットノードを兼ねることも可能です

### 動作環境

#### ansibleサーバ
OS: Linux(CentOSなど)  
Python: 2.6以上

#### ansibleターゲットノード
Python: 2.4以上  
※サーバと合わせておいた方が無難

## ansibleのインストール
### yumの場合(RHELやCentOS)

```
# yum install epel-release
# yum install ansible
```

### epelが使えない場合  

```
# easy_install pip
# pip install ansible
```  

注意点としてはrpmでインストールしたときと違い、/etc/ansibleディレクトリが作成されないため、ansible.cfgやhostsファイルが作成されません。  
<br>

---

<br>

## ansibleのディレクトリ・ファイル構成
### プレイブック
ansibleの実行全般を行うファイルを「プレイブック」といいます。
ansible-playbookコマンドで実行します。


### インベントリファイル
ansibleを実行されるホストの情報ファイルです。  
IPアドレス等を記載します。ansible-playbookコマンドで実行する際、オプション **-i** で指定します。指定しない場合、/etc/ansible/hostsファイルがデフォルトで読み込まれます(ansible.cfgで変更可)


### ディレクトリ
プレイブックを単純にディレクトリに分けて整理することが出来ます。  
「ロール」というまとまりで管理するとプレイブックが再利用しやすくなります。

## プレイブックの基本
記述スタイルは2種類あります。ブロックスタイルのほうが可読性が高いので通常はこちらを使います。拡張子は.ymlか.yamlでヤムルと読みます。

インデントはスペース2つ、コメントは#です。(インデント数は奇数も可です)
YAMLファイルのため行初めに---(ハイフンを3つ)、終わりに...(ドットを3つ)がお作法ですが、ansbileでは記載しなくても問題ありません。

プレイブック内は環境変数やモジュールを指定し、タスクを定義します。例えばパッケージのインストールにはyumモジュールを使います。

* ブロックスタイル

```yml
tasks:
  - name: Install Apache
    yum:
      name: httpd
      state: present
```

* フロースタイル

```yml
tasks:
  - name: Install Apache
    yum: name=httpd state=present
```

### 実際のプレイブック  
インベントリファイルhostsのwebグループに所属するターゲットノードに対して、apacheをインストールします。  

* インベントリファイル

```  
/etc/ansible/hosts
[web]
192.168.100.1
192.168.100.2

```

* プレイブック

```yml
httpd.yml
- hosts: web
  become: true
  tasks:
  - name: install Apache
    yum:
      name: httpd
      state: present
```

* 実行方法

```
$ ansible-playbook -i hosts httpd.yml -ask-pass -ask-become-pass
```

### プレイブックの解説

**- hosts:** でインベントリファイル内で定義したターゲットホストグループを指定します。  
**- hosts: all** とするとインベントリファイル内の全てのホストが対象となります。  

**tasks:** で実行するタスクを定義します。  
**- name:** でタスク名を定義します。ansible-playbook実行時に画面に表示される文字列となります。

**yum:** がモジュール名です。その名の通り、yumコマンドを実行します。

ansible-playbookは実行したansibleサーバのユーザ権限で動作します。  
**-ask-pass** はターゲットノードにssh接続するときのパスワード、 **-ask-become-pass** はターゲットノードでのsudoパスワードを入力するために必要とします。

つまりAサーバのAユーザでansible-playbookを実行すると、BサーバにAユーザでSSH接続し、Aユーザでsudoすることになります。

### よく使う構成1
シンプルな構成は下記です。

* プレイブック本体  xxx.yml
* インベントリファイル  /etc/ansible/hosts

```
/etc/ansible
  |-xxx.yml
  |-hosts
```

例えばapacheのインストール、設定ファイルの配布、サービスの起動を1つのプレイブックにまとめ、hostsファイルに定義したノードに対してプレイブックを実行します。


### よく使う構成2

```
/home/ansible/playbook_name
  |-task.yml
  |-httpd.yml
  |-php.yml  
  |-db.yml  

```

task.yml内にhttpd.yml、php.yml、db.ymlをインポートし、まとめて実行します。プレイブックの再利用がしやすいです。

### よく使う構成3

プレイブックを「ロール」という単位で細分化し、サーバの機能や用途などで使い分けます。環境変数や配布する設定ファイルもロール単位でまとめられます。  

注意点はロール対象フォルダにmain.ymlが必須な点です。main.ymlに全てのタスクを記載しても構いませんし、main.ymlから他プレイブックをインポートする構成もOKです。  

またプレイブックではtasksディレクティブは使わず、いきなりタスクリストから記述します。

例)
1. deploy.ymlで全サーバ共通設定となるcommonロール以下を全ターゲットノードに実行
2. webservers.ymlでhttpdロール以下を実行
3. dbservers.ymlでmysqlロール以下を実行

```
/etc  
  |-ansible  
    |-ansible.cfg  #ansibleの設定ファイル
    |-hosts  #ansibleターゲットノード情報を記載するファイル            
    |-deploy.yml  プレイブック本体   
    |-webservers.yml  webサーバに特化したプレイブック
    |-dbservers.yml  dbサーバに特化したプレイブック
  |-inventory  
    |-inventory.ini  #ansibleターゲットノード情報を記載するファイル
  |-roles/  #プレイブックを用途別に細分化したもの。
    |-common/  
      |-tasks/  
        |-main.yml  #ロールのプレイブックは最初にmain.ymlが読み込まれる
        |-include01.yml  
        |-include02.yml  
        |-include03.yml  
      |-handlers/  
        |-main.yml  
      |-templates/  
        |-httpd.conf.j2  #ansible独自のjinjaテンプレート
      |-files/  #コンフィグファイル等を配置
        |-httpd.conf  
        |-configure.sh  
      |-vars/  
        |-main.yml  
        |-include.yml
      |-defaults/  
        |-main.yml  
    |-httpd
    |-mysql  
```   

より具体的な内容は後述する「ロールの構造」以下を参照して下さい。

## モジュールとプレイブック
モジュールの使い方とプレイブック例は別ページにまとめました。  

* [各種モジュールの使い方](./module.md)

<br>

---

<br>

## ロールの構造
ロール名を指定してプレイブックを実行するとき、tasksやvars配下のmain.ymlのみが読み込まれる点に注意して下さい。  

外部の.ymlを読み込む時は、main.yml内に **import_tasks:** や **include_tasks:** で読み込むymlファイルを指定します。通常は **import_tasks:** で指定すればOKです。

* 一般的なロールの構造

```
/roles
  |-common
    |-files
      |-common.txt  
    |-handlers
      |-main.yml  
    |-tasks
      |-main.yml
      |-install.yml
      |-configure.yml  
    |-templates
      |-common.j2
    |-vars
      |-main.yml
      |-include.yml
  |-httpd
  |-mariadb  
  |-wordpress
```  

* import_tasksの例

```yml
main.yml
- name: main / common tasks
  include_vars: roles/common/vars/main.yml
- import_tasks: tasks/install.yml
- import_tasks: tasks/configure.yml
```

## ロールの実行方法
### プレイブック例
ロールにはタグ名を付けることが出来ます。ansible-playbook実行時に **-t** でプレイブック内の指定したロールだけ実行させることも可能です。

ロール名（ディレクトリ名）は自由につけてOKです。ロール内のプレイブックは **main.yml** が必須です。ロール内で最初に読み込まれるプレイブックです。  
**include_vars:** でロール変数を読み込んで使うこともあります。

* ロールを呼び出すプレイブック

**roles:** ディレクティブで呼び出します。  
commonやhttpdは/rolesディレクトリ配下にあるディレクトリ名で、これがそのままロール名になります。

```yml
/etc/ansbile/roles/deploy.yml
- name: deploy test
  hosts: apservers
  become: true
  roles:
    - { role: common, tags: common }
    - { role: httpd, tags: httpd }
    - { role: mariadb, tags: mariadb }
    - { role: wordpress, tags: wordpress ß}
```

* commonロールのmain.yml  
基本的に他プレイブックをインポートしているだけです。

```yml
/etc/ansible/roles/common/tasks/main.yml
- import_tasks: tasks/yum.yml
- import_tasks: tasks/common.yml
- import_tasks: tasks/timezone.yml
- import_tasks: tasks/cron.yml
```

* commonロール内のプレイブック  
実際のタスクを定義します。

```yml
/etc/ansible/roles/common/tasks/yum.yml
# yum updateの実施
- name: configure / update yum packages
  yum:
    name: '*'
    state: latest
    update_cache: yes
```

### ロールのタグ指定実行例
プレイブックに記述したtagsで指定したroleのみを実行するときは **-t** で指定します。  
下記の場合、deploy.ymlのcommonとhttpdロールのみを実行します。

```
$ ansible-playbook deploy.yml -i inventory.ini --ask-become-pass --ask-pass -t common,httpd
```

### ホスト指定実行例
ansible-playbook実行時にインベントリファイル内のグループを指定するときは **-l** （エル）で指定します。  
```
/etc/ansible/inventory/inventory.ini  
[mysql]  
192.168.100.1
192.168.100.2

[web]
192.168.0.1
192.168.0.2
```

実行例
```
$ ansible-playbook deploy.yml -i inventory.ini --ask-become-pass --ask-pass -l mysql
```

<br>

---

<br>

## inventoryファイルの記述例
yumでインストールするとansible.cfgが生成され、デフォルトのインベントリファイルは/etc/ansible/hostsになります。(ansible.cfg内で変更可能)

ansible-playbook **-i** を指定しない場合、/etc/hostsが読み込まれますが、検証、ステージング、本番などでノードを分けたいときなどにインベントリファイルを複数用意します。拡張子は.iniです。


```
/etc/ansible/hosts
[web]
192.168.100.1

[ap]
192.168.101.[1:5] #192.168.101.1〜192.168.101.5

[oracle]
hostname01 ansible_host=192.168.102.1
hostname02 ansible_host=192.168.102.2

[mysql]
mysql_[a:f] # mysql_a〜mysql_f

[db_servers:children]
oracle
mysql
※上記[oracle]と[mysql]を子要素としてまとめます

[all:vars]
ansible_port=22
ansible_user=ansible #ssh接続先ユーザ
ansible_ssh_pass=password #ssh接続先パスワード
ansible_become=true #ssh接続先でsudoするかどうか。デフォルトはfalse
ansible_become_pass=password #ssh接続先sudoパスワード
※上記はインベントリファイルでよく適用する環境変数です
```

<br>

---

<br>

## 環境変数
### 変数の定義
主に3つの参照範囲があります。  

* Global領域  
プレイブックのどこからでも参照可能な変数。  
environment vars(ユーザ独自変数ではなくansibleで予め定められている変数)、extra varsなど。


* Play単位  
個々のプレイブックで定義される変数。  
play vars、task vars、role varsなど。


* Host単位  
各ターゲットノードに紐付く変数。  
inventoruy vars、host vars、registered varsなど。

詳細は別ページにまとめました。

* [ansible環境変数](./var.md)


<br>

---

<br>

## pip関連の操作方法
### インストール済モジュール一覧表示
```
# pip list
```

### 更新対象モジュールの確認
```
# pip list --o
```

### 指定したパッケージのアップデート
```
# pip install XXXX -U
```

### パッケージの一斉更新
```
# pip install pip-review
# pip-review
# pip-review --auto
# pip-review --interactive
```

### pipそのものを更新
```
# pip install --upgrade pip
```

### パッケージのインストール・アンインストール
```
# pip install XXXXX
# pip uninstall XXXXX
```

<br>

---

<br>

## ちょいテク

### gitの活用
プレイブックの修正は直接サーバ上で行なえますが、viだけだと補完もありませんし、インデント誤りに気付きづらいです。  

.ymlファイルの編集はatomなどのエディターを活用し、gitでファイルをアップロード、ダウンロードさせる方法が楽です。またgitならコードの差分等の変更履歴も管理しやすくなり、プレイブックのフォークが楽に行なえます。

例）  
ローカル側で編集したymlファイルをファイルサーバにアップロードし、ansibleサーバでそのファイルをダウンロードする、というイメージです。

ローカル側
```
1. ローカルマシンでプレイブック(.yml)を編集
2. $ git add xxx.yml
3. $ git commit -m “[comment]”
4. $ git push
```

ansibleマネジメントサーバ側  
```
$ git clone https://xxx.xxx/xxx

すでにclone済の場合は下記コマンドで更新
$ git pull
```

## ログ
/etc/ansible/ansible.cfgで指定出来ます。  
注意点はansible-playbookを実行したユーザの権限でログが書き込まれることです。

```
$ log_path=/var/log/ansible.log
```

## 文法チェックとテスト実行
* 文法チェック

```
$ ansible-playbook deploy.yml --syntax-check
```

* テスト実行

ただし、.rpmを配布してからyumを行うなどのプレイブックの場合、実際にファイルが配布されないためエラーとなります。
```
$ ansible-playbook deploy.yml --check
```

ドライランだと上記のケースでエラーとなり切り分けが複雑になるため、シンタックスチェックに通ったら、実際に実行してエラーを追いかけた方が分かりやすいです。  

## デバッグ関連
* プレイブックの処理詳細表示  
**-v** を使います。vの個数を増やすと詳細なログが表示されます。

```
$ ansible-playbook -i hosts deploy.yml -v
```

vの数    |意味  
--------|---
-v      |タスク処理の詳細表示    
-vv     |タスク定義位置の詳細表示     
-vvv    |SSH処理内容の表示     
-vvvv   |SSH処理内容の詳細表示     
-vvvvv  |SSHコネクションのデバッグ表示     

* プレイブックの手動実行  
**--step** を使うと、タスクごとに実行の可否を選択しながら処理を行えます。

```
$ ansible-playbook -i hosts deploy.yml --step
```

* 実行するターゲットノードのホストを表示する  
**--list-hosts** で実行対象のホストを一覧表示させます。下記の場合の対象ホストはmariadb01とmariadb02です。

```
$ ansible-playbook -i hosts deploy.yml --list-hosts
playbook: wordpress_deploy.yml

  play #1 (databases): Deploy Database for wordpress	TAGS: []
    pattern: [u'databases']
    hosts (2):
      mariadb01
      mariadb02
```

* 実行するタスクのタグを表示する  
**--list-tags** を使うと、グループdatabasesのタスクタグはcommon,haproxy,keepalived,mariadbであることが分かります。

```
$ ansible-playbook -i hosts deploy.yml --list-tags
playbook: wordpress_deploy.yml

  play #1 (databases): Deploy Database for wordpress	TAGS: []
      TASK TAGS: [common, haproxy, keepalived, mariadb]

  play #2 (apps): Deploy Application for wordpress	TAGS: []
      TASK TAGS: [common, httpd, wordpress]

  play #3 (lbs): Deploy LoadBalancer for wordpress	TAGS: []
      TASK TAGS: [common, haproxy, keepalived]
```

* 実行するタスクを表示する  

**--start-at-task="TASK名"** でプレイブック内の指定タスク以降を実行することも出来ます。

```
$ ansible-playbook -i hosts deploy.yml --start-at-task=common
```

## ansible galaxy
世界中のユーザが公開しているプレイブックの共有リポジトリです。

* [ansible galaxy](https://galaxy.ansible.com/)


## ansible valut

.ymlファイルの暗号化と復号化を行えるコマンドです。  
taskを定義したプレイブックで変数名を読み込み、変数（パスワード等）を定義したファイルを暗号化させておいたります。  

* 暗号化

```
$ ansible-vault create xxx_vars.yml
$ cat xxx_vars.yml
87716784394300304300i438900980018802390 #暗号化されます
```

* 暗号化したファイルを閲覧

```
$ ansible-valut view xxx_vars.yml
- name: install / Install httpd
  yum:
    name: httpd
    state: present
```

* 暗号化したファイルを編集

```
$ ansible-vault edit xxx_vars.yml
```

* 暗号化プレイブックの実行

```
$ ansible-playbook xxx.yml --ask-vault-pass
```

* ログのセキュリティ対策  
ansible-valutで暗号化しても ansible-playbook **-v** オプションで標準出力に内容が表示されるため、暗号化した変数を利用する場合はプレイブック内で **no_log** を使います。

```
- name: install / Install httpd
  yum:
    name: httpd
     state: present
     no_log: true
```

## ansibleマネージメントサーバの管理
複数台のansibleマネジメントサーバを管理する方法があります。

### ansible tower  
Redhat社製で管理対象サーバが10台までなら無償で使えます。ブラウザから管理画面にアクセスし、ダッシュボード、ロール（権限）によるアクセスコントロール（権限管理）、ジョブスケジューリングが可能です。

他にもユーザによるジョブ実行履歴参照、通知機能（メールやSlack)、通知機能はワークフロー化し、成功・失敗時のフローを作成出来ます。  
※実際の機能はエディションにより多少差あり

* [ansible towerユーザーズガイド](http://docs.ansible.com/ansible-tower/3.1.4/html_ja/userguide/)  
* [エディション比較](https://www.ansible.com/products/tower/editions)  
* [ansible tower](https://www.ansible.com/products/tower)

### AWX  
ansible towerのOSS版。インストールにはdocker環境が必要です。  
リリースサイクルが早く、towerがRHELならAWXがFedoraのようなイメージです。ただし、あくまで開発中バージョンのため、サポートを受けられません。  

インストールはLifeKeeperで有名なサイオス社の解説が分かりやすいです。

* [THE AWX PROJECT FAQ](https://www.ansible.com/products/awx-project/faq)  
* [AWX Project(github)](https://github.com/ansible/awx)  
* [Ansible Towerのアップストリーム版OSSのAnsible AWXを使ってみる](https://oss.sios.com/yorozu-blog/ansible-awx)



### Jenkins  
言わずと知れたCIツール。ansible用のプラグインが用意されており、プレイブックをジョブとして登録し、管理することが出来ます。

* [Jenkins](https://jenkins.io/)


## ansible失敗例
### インデント位置の誤り
```yml
- name: install / Install httpd
  yum:
    name: httpd
     state: present

  yum:
    name: php
     state: present
```

state:の位置がおかしいです。name:と揃えないとエラーになります。

### 環境変数や外部ファイルの指定ミス
環境変数名やtemplate、copy、fileモジュールで指定したファイルのパス間違いがよくあります。

またこれらモジュールでパーミッションを指定する際は必ず4桁で指定してください。`$ chmod 777`のように3桁指定だと意味不明なパーミッションが適用されます。

## バグ？
ansbile 2.4.0〜2.4.3ではnmcliモジュールが正常に動作しない。  
NetworkManagerのバージョン依存？

## 困った時は
公式のドキュメントを読む。  
モジュールごとにサンプル記述があるので分かりやすいです。  
http://docs.ansible.com/

また`$ ansible-doc yum`のようにその場でモジュールの詳細を調べることも出来ます。


## 参考プレイブック
wordpressをwebサーバ、dbサーバごとに冗長化させたプレイブックです。
Amazon Linux2用ですが、ちょっといじればCentOS7系でも使えると思います。

* [wordpressの冗長化](./README.md)
