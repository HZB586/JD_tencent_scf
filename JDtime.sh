#!/bin/bash
## Author: SuperManito
## Modified: 2021-09-30

## 定义允许的误差时间，单位毫秒
case $# in
0)
    TimeError=100
    ;;
1)
    case $1 in
    [1-9] | [1-9][0-9] | [1-9][0-9][0-9])
        TimeError=$1
        ;;
    *)
        echo -e "\n\033[31m ----- 不能这么用哦! ----- \033[0m\n"
        exit 1
        ;;
    esac
    ;;
*)
    echo -e "\n\033[31m ----- 不能这么用哦! ----- \033[0m\n"
    exit 1
    ;;
esac

## 环境判定
function Check() {
    if [ "$(curl -I -s --connect-timeout 5 https://bean.m.jd.com/bean/signIndex.action -w %{http_code} | tail -n1)" -ne "302" ]; then
        echo -e "\n\033[31m ----- 无法连接至京东服务器，请检查你的网络环境 ----- \033[0m\n"
        exit 1
    fi
    if [ "$(cat /etc/os-release | grep "^ID" | awk -F '=' '{print$NF}')" = "alpine" ]; then
        echo -e "\n\033[31m ----- 请到主机环境执行 ----- \033[0m\n"
        exit 1
    fi
}

function Main() {
    Check
    local Interface="https://api.m.jd.com/client.action?functionId=queryMaterialProducts&client=wh5"
    if [[ $(echo $(($(curl -sSL "${Interface}" | awk -F '\"' '{print$8}') - $(eval echo "$(date +%s)$(date +%N | cut -c1-3)"))) | sed "s|\-||g") -lt 10 ]]; then
        echo -e "\n\033[32m------------ 检测到当前本地时间与京东服务器的时间差小于 10ms 因此不同步 ------------\033[0m\n"
    else
        echo -e "\n❖ 同步京东服务器时间"
        echo -en "\n当前设置的允许误差时间为 ${TimeError}ms，脚本将在 3s 后开始运行..."
        sleep 3
        echo -e ''
        while true; do
            ## 先同步京东服务器时间
            date -s $(date -d @$(curl -sSL "${Interface}" | awk -F '\"' '{print$8}' | cut -c1-10) "+%H:%M:%S") >/dev/null
            sleep 1
            ## 定义当前系统本地时间戳
            local LocalTimeStamp="$(date +%s)$(date +%N | cut -c1-3)"
            ## 定义当前京东服务器时间戳
            local JDTimeStamp="$(curl -sSL "${Interface}" | awk -F '\"' '{print$8}')"
            ## 定义当前时间差
            local TimeDifference=$(echo $((${JDTimeStamp} - ${LocalTimeStamp})) | sed "s|\-||g")
            ## 输出时间
            echo -e "\n京东时间戳：\033[34m${JDTimeStamp}\033[0m"
            echo -e "本地时间戳：\033[34m${LocalTimeStamp}\033[0m"
            if [[ ${TimeDifference} -lt ${TimeError} ]]; then
                echo -e "\n\033[32m------------ 同步完成 ------------\033[0m\n"
                if [ -s /etc/apt/sources.list ]; then
                    apt-get install -y figlet toilet >/dev/null
                    local ExitStatus=$?
                else
                    local ExitStatus=1
                fi
                if [ $ExitStatus -eq 0 ]; then
                    echo -e "$(toilet -f slant -F border --gay SuperManito)\n"
                else
                    echo -e '\033[35m    _____                       __  ___            _ __       \033[0m'
                    echo -e '\033[31m   / ___/__  ______  ___  _____/  |/  /___ _____  (_) /_____  \033[0m'
                    echo -e '\033[33m   \__ \/ / / / __ \/ _ \/ ___/ /|_/ / __ `/ __ \/ / __/ __ \ \033[0m'
                    echo -e '\033[32m  ___/ / /_/ / /_/ /  __/ /  / /  / / /_/ / / / / / /_/ /_/ / \033[0m'
                    echo -e '\033[36m /____/\__,_/ .___/\___/_/  /_/  /_/\__,_/_/ /_/_/\__/\____/  \033[0m'
                    echo -e '\033[34m           /_/                                                \033[0m\n'
                fi
                break
            else
                sleep 1s
                echo -e "\n未达到允许误差范围设定值，继续同步..."
            fi
        done
    fi
}

Main "$@"
