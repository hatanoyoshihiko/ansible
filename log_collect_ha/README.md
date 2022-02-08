## fluentd, elasticsearch, kibana のデプロイプレイブック

fluentd、elasticsearch、kibanaサーバをデプロイするためのプレイブックです。

## 構成

インベントリファイルの構成は計2台のサーバとなります。
- host A
 - fluentd
- host B
 - fluentd
 - elastic search
 - kibana

fluentd_agentとfluentd_server、elasticsearchとkibanaを同居させてもOKです。  
fluentd_agentとfluentd_server はコンフィグがバッティングするため、同居不可です。

- fluentd_agent
- fluentd_server
- elasticsearch
- kibana

## デプロイ手順

1.  プレイブックのダウンロード  
    `# cd /etc/ansible`  
    `# git clone https://github.com/hatanoyoshihiko/ansible.git`  

2.  プレイブックの実行  
    `# cd /etc/ansible/log`  
    `# ansible-playbook -i inventory/inventory.ini setup.yml`  

5〜10 分ほどでデプロイ完了します。  

## 設定

#### ホスト

`/etc/ansible/log/inventory/inventory.ini`  
デプロイ対象を設定出来ます。  

`[td_server]`  
fluentd_agentのログを集約するホストのIPアドレスを指定して下さい。  

`[td_agent]`  
このホストのログが`[td_server]`に集約されます。  

`[elasticsearch]`  
elasticsearchサーバのIPアドレスを指定して下さい。  
入力したIPアドレスは全てクラスタ用のIPアドレスに設定され、  
minimum_master_nodesの値も自動で計算され、コンフィグに反映されます。  

`[kibana]`  
kibanaサーバのIPアドレスを指定して下さい。  

#### fluentd_agent

コンフィグファイルは下記ファイルを修正して下さい。  
`/etc/ansible/log/roles/fluentd_agent/templates/td-agent.conf.j2`  

収集対象のログは下記の通りです。  
下記ログのうち存在するものだけ収集されます。  

- /var/log/messages  
- /var/log/httpd/access_log  
- /var/log/httpd/error_log  
- /var/log/httpd/ssl_access_log  
- /var/log/httpd/ssl_error_log  

#### fluentd_server

コンフィグファイルは下記ファイルを修正して下さい。  
`/etc/ansible/log/roles/fluentd_agent/templates/td-agent.conf.j2`  

`[td_agent]`から送られてきたログを集約し、elasticsearchサーバへ転送します。  

#### elasticsearch

コンフィグファイルは下記ファイルを修正して下さい。  

- コンフィグ  
  `/etc/ansible/log/roles/elasticsearch/templates/elasticsearch.yml.j2`  

- jvm 用  
  `/etc/ansible/log/roles/elasticsearch/templates/jvm.options.j2`  

eth0のIPで稼働するため、eth1 等に変更するときはnetwork.hostを下記のように変更して下さい。  
`network.host: '_eth1:ipv4_'`  

#### kibana

コンフィグファイルは下記ファイルを修正して下さい。  
`/etc/ansible/log/roles/kibana/templates/kibana.yml.j2`  

管理画面URL  
`http://192.168.10.200:5601`  

## snippet

#### fluentd

- syntax チェック  

#### elasticsearch

- インデックス一覧の確認  
  `$ curl -X GET http://localhost:9200/_cat/indices?v`  
