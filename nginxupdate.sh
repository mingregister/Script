#! /usr/bin/env bash
# Usage：(sudo) sh nginxupdate.sh

# Check if user is root
# 这里可能不需要root权限也行。
# 因为我测试环境上的nginx是用root(小于1024的端口号需要root才能用)启动的，所以需要root
# 在生产上是使用apmuser启动的，所以不需要root也行。
# if [[ $(id -u) != "0" ]]; then
#     echo "Error: You must be root to run this script, please use root to update"
#     exit 1
# fi

DIR=/opt/nginx_HOME/nginx
CONF=/opt/nginx_HOME/nginx/conf/nginx.conf
TARDIR=/tmp
NGINXVERSION=nginx-1.13.12
# 注意，这里是单引号，不是左上角的``
CONFIGPARA='--prefix=/opt/nginx_HOME/nginx --with-http_ssl_module --with-pcre=/opt/pcre/pcre-8.36 --with-zlib=/opt/zlib-1.2.8 --with-openssl=/opt/openssl-1.0.1c'

pid_old=$(ps -ef | grep nginx | sed -n '1p' | awk '{print $2}')
if [[ ${pid_old} ]]; then
  echo ${pid_old}
else
  echo "the nginx process do not exist, exit"
  exit 1
fi

# 备份二进制文件
cd ${DIR}/sbin/
cp -p nginx{,.bak}

# 确认原本的二进制文件备份完成
if [[ ! -f nginx.bak ]]; then
  echo "Error, can not copy the nginx to nginx.bak"
  exit 1
fi

# 解压新版本tar包
tar -xzvf ${TARDIR}/${NGINXVERSION}.tar.gz -C ${TARDIR}
# 编译及make
cd ${TARDIR}/${NGINXVERSION} && ./configure ${CONFIGPARA} && make
if [[ ! -d ${TARDIR}/${NGINXVERSION}/objs ]]; then
  echo "please compile THE NGINX first!!! exist!!!"
  exit 1
fi
# 替换nginx二进制文件
cp -rfp ${TARDIR}/${NGINXVERSION}/objs/nginx ${DIR}/sbin/nginx

# 平滑停止旧进程
kill -USR2 ${pid_old}
# 启动新进程
# ${DIR}/sbin/nginx -t -c ${CONF}   # 不需要的了，上面会同时启动新旧两个进程。
# ${DIR}/sbin/nginx -c ${CONF}
# sleep 10

# 逐步停止旧的实例
echo "stop the old processing"
kill -WINCH ${pid_old}
echo "####################################################"
echo "To finish this upgrade, you have to do one more step: \nkill -QUIT ${pid_old}"

cat >&2 <<-'EOF'
  # Rollback Solution
  # # 重启旧的工作进程
  # kill -HUP ${pid_old}
  # # 从容关闭新工作进程
  # kill -QUIT 'newpid'
  # if [[ $? -ne 0 ]]; then
  #   kill -TERM 'newpid'
  #   if [[ $? -ne 0 ]]; then
  #     kill -9 'newpid'
  #   fi
  # fi
  # cp -p ${DIR}/sbin/nginx{.bak,}
EOF