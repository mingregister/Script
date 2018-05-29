# /bin/bash

url=$1
monitor_http(){
    status_code=$(curl -m 5 -s -o /dev/null -w %{http_code} $url)
    echo $status_code
}
monitor_http