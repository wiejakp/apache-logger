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