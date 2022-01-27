# OS settings
playbook実行方法

■プレイブック
os/group_vars
os/host_vars
os/inventory
os/roles
os/setup.yml

■プレイブック配置場所
/etc/ansible/配下

■インベントリファイル
os/inventory/inventory.ini
# 環境に応じてホスト名やIPアドレスを変えて下さい

■条件
ansible実行側
・OSはCentOS7.5
・ansibleインストール済であること
・ansibleは2.6.4

ansibleされる側
・OSはCentOS7.5
・sshdの設定済であること（root,password認証OK）
・pythonインストール済であること

■プレイブックの実行方法
/etc/ansible以下にosディレクトリ以下を配置して下さい。
とりあえず読み込み権限があれば動くはずです。

# cd /etc/ansible/os
# ansible-playbook -i inventory/inventory.ini setup.yml --ask-pass

※ --checkオプションを付けると、userロールの処理でコケます。
　まだユーザのホームディレクトリが無いため。

■プレイブック解説
パスは各ロールからの相対パスです。

・inventory/inventory.ini
linux01がホスト名として設定される値です。resolverロールで設定しています（なぜ）
ansible_hostはプレイブック実行時の接続先IPです。
このIP自体を変数として参照することもあります。



・localeロール
タイムゾーン、ロケール、キーボードを設定しています。
変数はlocale/defalts/main.ymlを参照しています。



・networksロール
# 畑野環境では仮想環境の都合上、eth0が管理用、eth1がサービス用になっているので
  環境に合わせて修正して下さい。



・packagesロール
OSディストリビューションがDebianかRHELかで処理を変えています。私の趣味なので不要な処理です。
yum updateを実行するので不要なら削除して下さい。
"{{ required_packages }}"はpackages/vars/Redhat.ymlに定義しています。



・resolverロール
ホスト名、ネットワークマネージャー、nsswitch、resolv.conf、/etc/hostsを設定しています。
設定ファイルは/resolver/files内です。nsswitchの設定をミスてって何度もやり直しました。
hostsはresolver/templates/hosts.j2で定義しています。

配置されると↓になります。
192.168.10.151 linux01 linux01.ansible.local



・timesロール
chronyは前回のソースがあるのでいいかなと思いまして、
ntpの場合で作りました。

- block処理がミソで、通常、ansibleは並列で処理を流しますが、
　ここの処理は1台終わったら次の1台へ、と丁寧にやります。
　※処理される順番の仕組は理解していません。実行する度に変わっている気がします。



・usersロール
ユーザを作成します。一般と管理者です。
ユーザの定義はusers/vars/main.ymlです。
プレイブック内のパスワードは平文ですが、設定値としては暗号化されています。

ここの変数をwith_dictで参照しています。
item.keyはuser01やuser02を指しています。

あと公開鍵バラまいています。
lookupはansibleホストのローカルファイルを
ansible先の同じディレクトリに配置します。~/としているのがミソです。
ansible先には各ユーザのホームディレクトリの.ssh/以下にauthorized_keysとして配置されます。
あと、/etc/sudoers.dにユーザごとのsudoersファイルを配布しています。
users/template配下にあります。
