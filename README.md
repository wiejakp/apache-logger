# apache-logger
## usage

### install requirements
```
sudo apt-get install jq -y
```

### prepare virtual host
Paste following at the beginning of our virtual host file:
```
# LOG FORMAT - JSON
LogFormat "{\"request_datetime\":\"%t\",\"request_date\":\"%{%m:%d:%Y}t\",\"request_time\":\"%{%T}t\",\"request_completed\":\"%D\",\"request_file\":\"%f\",\"request_method\":\"%m\",\"request_uri\":\"%U\",\"server_addr\":\"%A\",\"server_name\":\"%V\",\"server_port\":\"%p\",\"remote_addr\":\"%a\",\"remote_host\":\"%h\",\"query_string\":\"%q\",\"response_status_code\":\"%>s\",\"http_referer\":\"%{Referer}i\",\"http_user_agent\":\"%{User-Agent}i\"}" default-host

# LOG FILE
CustomLog "| /usr/bin/rotatelogs -t /var/log/apache2/default-host.log 86400" default-host
```

### running executable
```
cd ~/
git clone https://github.com/wiejakp/apache-logger.git
cd apache-logger
chmod +x public/src/reader.sh
./public/src/reader.sh
```

### output
```
root@localhost:/var/www/wiejak.info/apache-logger# ./public/src/reader.sh
[ ! ]
[ ! ] START
[ ! ]
[ ! ] init
[ ! ]
[ ! ] USAGE:
[ ! ] -h|--host example.com
[ ! ] -p|--port 80
[ ! ] -s|--status 200
[ ! ] -m|--method GET
[ ! ] -l|--length 25
[ ! ] -i|--input "/var/log/apache2/log/error.log"
[ ! ] -f|--follow
[ ! ] -d|--default
[ ! ]
[ ! ]
[ ! ] listen
[ ! ]
[ ! ] SETTINGS:
[ ! ]
[ ! ] RUNNING COMMAND: tail --follow=name --quiet --retry -- '/var/log/apache2/virtual-host.log' |              jq --raw-output --unbuffered ' [
                .request_time,
                .response_status_code,
                .remote_addr,
                .server_name,
                .server_port,
                .request_file,
                .request_uri,
                .http_user_agent
        ] | @tsv'
        ;
[ ! ]
| 02:50:23 ###.##.##.#     wp       [404] wiejak.info:443     /favicon.ico
| 02:50:22 ###.###.###.### wp       [200] wiejak.info:443     /wp-cron.php
| 02:50:24 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:25 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:26 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:27 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:28 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:29 ###.##.##.#     wp       [200] wiejak.info:443     /wp-admin/admin-ajax.php
| 02:50:34 ::1                      [200] :80                 *
| 02:50:48 ###.##.##.##             [200] pwiam.com:443       /index.php
^C[ ! ]
[ ! ]
[ ! ] CTRL + C
[ ! ]
[ ! ] Good Bye!
[ ! ]
[ ! ] EXIT
[ ! ]
root@localhost:/var/www/wiejak.info/apache-logger# 
```