# How to deploy zabbix using ansible

## Clone Repository

`# cd /etc/ansible`
`# git clone https://github.com/hatanoyoshihiko/zabbix.git`
`# cd zabbix/ansible`

## Configure inventory file

`# vi /etc/ansible/inventory/inventory.ini`

```ini
[zabbix_server]
zabbix01 ansible_host=172.20.55.190

[maria_db]
mariadb01 ansible_host=172.20.55.190
```

## Run playbook

- syntax check

`# cd /etc/ansible`
`# ansible-playbook -i inventory/inventory.ini -k --syntax-check`

- run playbook

`# ansible-playbook -i inventory/inventory.ini -k`

## Initial zabbix setting

Access to zabbix URL to be appered end of playbook.

1. Welcome
Push Next step.

2. Check of pre-requisites
Push Next step.

3. Configure DB Connection
Input like below

- Database type: MySQL
- Database host: localhost
- Database port: 0
- Database name: zabbix
- User: zabbix
- Password: zabbix

4. Zabbix server details

- Host: localhost
- Port: 10051
- Name: What you want

5. Pre-installation summary

Push Next step

6. Install

If below message shows, you can access to zabbix server.
"Congratulations! You have successfully installed Zabbix frontend."
