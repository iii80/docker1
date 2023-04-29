#!/bin/bash
#from https://github.com/spiritLHLS/docker

# cd /root

red() { echo -e "\033[31m\033[01m$@\033[0m"; }
green() { echo -e "\033[32m\033[01m$@\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "utf8|UTF-8")
if [[ -z "$utf8_locale" ]]; then
  yellow "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  green "Locale set to $utf8_locale"
fi

pre_check(){
    home_dir=$(eval echo "~$(whoami)")
    if [ "$home_dir" != "/root" ]; then
        red "Current path is not /root, script will exit."
        red "当前路径不是/root，脚本将退出。"
        exit 1
    fi
    if ! command -v docker > /dev/null 2>&1; then
        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/pre_build.sh -o pre_build.sh
        chmod 777 pre_build.sh
        dos2unix pre_build.sh
        bash pre_build.sh
    fi
    if [ ! -f ssh.sh ]; then
        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/ssh.sh -o ssh.sh
        chmod 777 ssh.sh
        dos2unix ssh.sh
    fi
    if [ ! -f buildone.sh ]; then
        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/onedocker.sh -o onedocker.sh
        chmod 777 onedocker.sh
        dos2unix onedocker.sh
    fi
}

check_log(){
    log_file="dclog"
    if [ -f "$log_file" ]; then
        green "Log文件存在，正在读取内容..."
        while read line; do
            # echo "$line"
            last_line="$line"
        done < "$log_file"
        last_line_array=($last_line)
        container_name="${last_line_array[0]}"
        ssh_port="${last_line_array[2]}"
        password="${last_line_array[3]}"
        public_port_start="${last_line_array[4]}"
        public_port_end="${last_line_array[5]}"
        if lsmod | grep -q xfs; then
          disk="${last_line_array[6]}"
        fi
        container_prefix="${container_name%%[0-9]*}"
        container_num="${container_name##*[!0-9]}"
        yellow "目前最后一个小鸡的信息："
        blue "容器前缀: $container_prefix"
        blue "容器数量: $container_num"
        blue "SSH端口: $ssh_port"
#         blue "密码: $password"
        blue "外网端口起: $public_port_start"
        blue "外网端口止: $public_port_end"
    else
        red "log文件不存在。"
        container_prefix="dc"
        container_num=0
        ssh_port=25000
        public_port_end=35000
    fi
    
}

build_new_containers(){
    while true; do
        reading "还需要生成几个小鸡？(输入新增几个小鸡)：" new_nums
        if [[ "$new_nums" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            yellow "输入无效，请输入一个正整数。"
        fi
    done
    while true; do
        reading "每个小鸡分配多少内存？(每个小鸡内存大小，若需要256MB内存，输入256)：" memory_nums
        if [[ "$memory_nums" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            yellow "输入无效，请输入一个正整数。"
        fi
    done
    if lsmod | grep -q xfs; then
      while true; do
          reading "每个小鸡分配多大硬盘？(每个小鸡硬盘大小，若需要1G硬盘，输入1)：" disk_nums
          if [[ "$disk_nums" =~ ^[1-9][0-9]*$ ]]; then
              break
          else
              yellow "输入无效，请输入一个正整数。"
          fi
      done
    else
      disk_nums=""
    fi
    for ((i=1; i<=$new_nums; i++)); do
        container_num=$(($container_num + 1))
        container_name="${container_prefix}${container_num}"
        ssh_port=$(($ssh_port + 1))
        public_port_start=$(($public_port_end + 1))
        public_port_end=$(($public_port_start + 25))
        if [ -n "$disk_nums" ]; then
          ./onedocker.sh $container_name $memory_nums $ssh_port $startport $endport $disk_nums
        else
          ./onedocker.sh $container_name $memory_nums $ssh_port $startport $endport
        fi
        cat "$container_name" >> dclog
        rm -rf $container_name
    done
}

pre_check
check_log
build_new_containers
green "生成新的小鸡完毕"
check_log
