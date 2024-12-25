#!/bin/env bash
# *
# * Author : Yuxuebing
# * Email : yu.xuebing@yottabyte.cn
# * Description :

num=$#

if [[ $num == 4 || $num == 6 ]];then
        resource=$2
        method=$4
        options_5th=$5
elif [[ $num == 10 || $num == 12 ]];then
        url=$2
        user=$4
        user_passwd=$6
        resource=$8
        method=${10}
        options_11th=${11}
fi

if [[ $num == 10 || $num == 12 ]];then
        header="Content-Type: application/json"
        api="/api/v2"
        api3="/api/v3"
	passwd_base64=`echo -n $user:$user_passwd | base64`
        auth="Authorization: Basic $passwd_base64"
        request="curl --connect-timeout 5 -k"
        if [[ $num == 12 && $resource == "report_alert" && $options_11th == "-f" ]];then
                phone_email=${12}
        elif [[ $num == 12 && $resource == "agent_logstream" && $options_11th == "-f" ]];then
                appname_tag=${12}
        elif [[ $num == 12 && $resource == "account" && $options_11th == "-f" ]];then
                account_name=${12}
        elif [[ $num == 12 && $resource == "agent" && $options_11th == "-f" ]];then
                agent_group=${12}
        elif [[ $num == 12 && $resource == "basic" && $options_11th == "-f" ]];then
                system_name=${12}
        elif [[ $num == 12 && $options_11th == "-s" ]];then
                source=${12}
        fi
elif [[ $num == 6 && $options_5th == "-s" ]];then
        source=$6
fi

help() {
    echo "Example:"
    echo -e "\t${0##*/} -h "
    echo -e "\t${0##*/} -r <agent/proxy> -m <install> -s <source>"
    echo -e "\t${0##*/} -r <template> -m <download/review>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <account> -m <add/delete/enable/disable> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <account/agent_logstream/dataset/agentgroup/usergroup/queryscope> -m <add> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <dataset> -m <sync> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <account/agent/upgrading_agent/agent_logstream/agent_topinput/agent_dbinput/agent_processinput/dataset/alert/schedule/report/dashboard/agentgroup/usergroup/app/parserrule> -m <download>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <report_alert> -m <delete> -f <phone,email>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <account> -m <enable> -f <account>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <agent> -m <start/stop/restart/upgrade> -f <agentgroup>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <agent> -m <add_agentgroup> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <role> -m <permission>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <agent_logstream> -m <download> -f <appname,appname/tag>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <agent_logstream> -m <renew/delete> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <agent_topinput> -m <delete> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <resource> -m <import> -s <source>"
    echo -e "\t${0##*/} -i <url> -u <user> -p <passwd> -r <basic> -m <add> -f <业务系统>"

    echo "Options:"
    echo -e "\t-h               : 帮助信息"
    echo -e "\t-i url           : API主机端口"
    echo -e "\t-u user          : 用户名"
    echo -e "\t-p passwd        : 密码"
    echo -e "\t-r resource      : 资源,包含:account/agent/upgrading_agent/agent_logstream/agent_topinput/agent_dbinput/agent_processinput/report/alert/resource/app/dataset/queryscope/schedule/dashboard/usergroup/agentgroup"
    echo -e "			   parserrule/role/basic/template"
    echo -e "\t-m method        : 执行动作,可选:add(创建)/delete(删除)/enable(启用)/disable(禁用)/download(导出清单)/renew(更新agent日志采集配置)/install(agent&proxy安装)"
    echo -e "			   sync(同步数据集)/permission(角色资源授权)/start(agent启动)/stop(agent停止)/restart(agent重启)/upgrade(agent升级)/add_agentgroup(agent添加分组)"
    echo -e "			   import(主备集群差异化同步导入)"
    echo -e "\t-s source        : 从CSV文件添加资源,可选操作类型:account/agent_logstream/dataset/agentgroup/usergroup"
    echo -e "\t-f phone/email   : 从报表和监控清理指定手机号码或邮件地址，多个以逗号分隔"
    echo -e "\t-f appname/tag   : 从agent日志文件采集配置导出指定的appname/tag或appname关联的agent日志文件采集清单,多个以逗号分隔"
    echo -e "\t-f account       : 开启平台应急管控，只启用指定的账号，多个以逗号分隔，其他账号全部禁用，并导出禁用账号清单"
    echo -e "\t-f agentgroup    : 对指定agent分组的agent执行批量操作，包括启动、停止、重启、升级，多个以逗号分隔"
    echo -e "\t-f 业务系统      : 对指定业务系统名称执行批量添加角色、用户分组、资源标签和数据集，多个以逗号分隔"

}

progress_bar() {
        let _progress=(${1}*100/${2}*100)/100
        let _done=(${_progress}*10)/10
        let _left=100-$_done
        _fill=$(printf "%${_done}s")
        _empty=$(printf "%${_left}s")
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
_start=$1
_end=$2
}

params_check() {                #检查api请求返回状态、用户鉴权、文件扩展名、文件字符集编码
if [[ $num == 10 || $num == 12 ]];then
        http_code=`curl -I -m 10 -o /dev/null -k -s -w %{http_code} $url`
        passwd_base64=`echo -n "$user:$user_passwd" | base64`
        auth_return=`$request -H "$auth" "${url}${api}/apikeys/" 2>/dev/null | jq .result`
        if [[ $http_code != "200" ]];then
                echo "API主机$url请求返回状态码$http_code异常."
                exit 1
        elif [[ $auth_return != "true" ]];then
                echo "用户$user鉴权失败."
                exit 1
        elif [[ $num == 12 && $options_11th == '-s' ]] && [[ ! -f $source ]];then
                echo "文件$source不存在."
                exit 1
        elif [[ $num == 12 && $options_11th == '-s' && ${source##*.}x == "csv"x ]];then
                file_encode=`file -i $source | awk -F= '{print $NF}'`
                if [[ ${file_encode^^} != "UTF-8" ]];then
                        iconv -f GB18030 -t UTF-8 $source > ${source%%.*}_utf-8.${source##*.}
                        source=`echo "${source%%.*}_utf-8.${source##*.}"`
                        sed -i 's/\r$//g' $source
                fi
        elif [[ $num == 12 && $options_11th == '-s' && ${source##*.}x != "csv"x ]];then
                echo "文件$source格式错误."
                exit 1
        fi
elif [[ $num == 6 ]];then
        if [[ $num == 6 && $options_5th == '-s' && ${source##*.}x == "csv"x ]];then
                file_encode=`file -i $source | awk -F= '{print $NF}'`
                if [[ ${file_encode^^} != "UTF-8" ]];then
                        iconv -f GB18030 -t UTF-8 $source > ${source%%.*}_utf-8.${source##*.}
                        source=`echo "${source%%.*}_utf-8.${source##*.}"`
                        sed -i 's/\r$//g' $source
                fi
        elif [[ $num == 6 && $options_5th == '-s' && ${source##*.}x != "csv"x ]];then
                echo "文件$source格式错误."
                exit 1
        fi
fi
}

template_download() {
PS3='请选择需要生成的文件模板：'
template=("账号新增、删除、启用、禁用：用户帐号清单.csv" \
"用户分组和角色新增：用户分组清单.csv" \
"数据集新增、同步：数据集清单.csv" \
"Agent分组新增：Agent分组清单.csv" \
"Agent日志采集配置新增：Agent日志采集清单.csv" \
"Agent日志采集配置更新、删除、启用、禁用：指定appname导出Agent日志采集清单.csv" \
"Agent部署清单.csv" \
"Proxy部署清单.csv" \
"Agent关联Agent分组：Agent增加Agent分组清单.csv" \
"添加搜索权限：搜索权限清单.csv" \
"日志易平台集群资源同步：多集群资源同步清单.csv" \
"Exit")
select num in "${template[@]}";do
        case $num in
                "账号新增、删除、启用、禁用：用户帐号清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="用户帐号清单"
                echo "用户名,全名,初始密码,邮箱,电话号码,所属用户分组(多个以空格分隔)" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "用户分组和角色新增：用户分组清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="用户分组清单"
                echo "用户分组名称,描述,管理员,角色(多个以空格分隔)" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "数据集新增、同步：数据集清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="数据集清单"
                echo "数据集层级,父节点,数据集名称,数据集别名,父子行为(0无/1汇聚/2继承),约束语句,资源标签(多个以空格分隔)" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Agent分组新增：Agent分组清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="Agent分组清单"
		echo "Agent分组名称,描述,资源标签,分配角色(多个以空格分隔)" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Agent日志采集配置新增：Agent日志采集清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="Agent日志采集清单"
                echo "Agent-IP,Agent端口,appname,tag,路径,文件路径白名单,分流字段(多个以空格分隔),排序字段(多个以空格分隔),换行正则,最后修改时间,chartset(可选:默认为utf-8),时间戳格式,Agent分组" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Agent日志采集配置更新、删除、启用、禁用：指定appname导出Agent日志采集清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="指定appname导出Agent日志采集清单"
                echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag,路径,文件路径白名单,文件路径黑名单,换行正则,最后修改时间,时间戳格式,字符集编码,分流字段,排序字段" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Agent部署清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="Agent部署清单"
                echo "Agent-IP,运行端口,平台,Agent版本,Agent安装脚本id,SSH端口,Agent登录账号,密码,集群Nginx-IP,是否对接Proxy,Proxy-IP,yottaweb代理端口,auth代理端口,collector代理端口,Proxy登录账号,Proxy密码" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Proxy部署清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="Proxy部署清单"
                echo "Proxy-IP,运行端口,SSH端口,登录账号,密码,Manager-IP,proxy版本,yottaweb代理端口,auth代理端口,collector代理端口,yottaweb-IP,Auth-IP,Collector-IP" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "Agent关联Agent分组：Agent增加Agent分组清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="Agent增加Agent分组清单"
                echo "Agent-IP,Agent端口,Agent分组" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
                "添加搜索权限：搜索权限清单.csv")
                download_time=`date '+%Y%m%d_%H%M'`
                filename="搜索权限清单"
                echo "名称,描述,资源标签,hostname,appname,tag,过滤条件" > ./${filename}_${download_time}.csv
                echo "`pwd`/${filename}_${download_time}.csv已生成."
                ;;
		"日志易平台集群资源同步：多集群资源同步清单.csv")
		download_time=`date '+%Y%m%d_%H%M'`
		filename="多集群资源同步清单"
                echo "主集群mysql节点IP,mysql账号,mysql密码,主集群mongodb节点IP,mongodb账号,mongodb密码,备集群mysql节点IP,mysql账号,mysql密码,备集群mongodb主节点IP,mongodb账号,mongodb密码" > ./${filename}_${download_time}.csv
		echo "`pwd`/${filename}_${download_time}.csv已生成."
		;;
                "Exit")
                echo "退出！"
                exit
                break
                ;;
                *)
                echo "invalid option $REPLY"
                ;;
        esac
done
}

template_review() {
PS3='请选择需要预览的文件模板：'
template=("账号新增、删除、启用、禁用：用户帐号清单.csv" \
"用户分组和角色新增：用户分组清单.csv" \
"数据集新增、同步：数据集清单.csv" \
"Agent分组新增：Agent分组清单.csv" \
"Agent日志采集配置新增：Agent日志采集清单.csv" \
"Agent日志采集配置更新、删除、启用、禁用：指定appname导出Agent日志采集清单.csv" \
"Agent部署清单.csv" \
"Proxy部署清单.csv" \
"Agent关联Agent分组：Agent增加Agent分组清单.csv" \
"添加搜索权限：搜索权限清单.csv" \
"日志易平台集群资源同步：多集群资源同步清单.csv" \
"Exit")
select num in "${template[@]}";do
        case $num in
                "账号新增、删除、启用、禁用：用户帐号清单.csv")
                echo "用户名,全名,初始密码,邮箱,电话号码,所属用户分组(多个以空格分隔)"
                ;;
                "用户分组和角色新增：用户分组清单.csv")
                echo "用户分组名称,描述,管理员,角色(多个以空格分隔)"
                ;;
                "数据集新增、同步：数据集清单.csv")
                echo "数据集层级,父节点,数据集名称,数据集别名,父子行为(0无/1汇聚/2继承),约束语句,资源标签(多个以空格分隔)"
                ;;
                "Agent分组新增：Agent分组清单.csv")
			echo "Agent分组名称,描述,资源标签,分配角色(多个以空格分隔)"
                ;;
                "Agent日志采集配置新增：Agent日志采集清单.csv")
                echo "Agent-IP,Agent端口,appname,tag,路径,文件路径白名单,分流字段(多个以空格分隔),排序字段(多个以空格分隔),换行正则,最后修改时间,chartset(可选:默认为utf-8),时间戳格式,Agent分组"
                ;;
                "Agent日志采集配置更新、删除、启用、禁用：指定appname导出Agent日志采集清单.csv")
                echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag,路径,文件路径白名单,文件路径黑名单,换行正则,最后修改时间,时间戳格式,字符集编码,分流字段,排序字段"
                ;;
                "Agent部署清单.csv")
                echo "Agent-IP,运行端口,平台,Agent版本,Agent安装脚本id,SSH端口,Agent登录账号,密码,集群Nginx-IP,是否对接Proxy,Proxy-IP,yottaweb代理端口,auth代理端口,collector代理端口,Proxy登录账号,Proxy密码"
                ;;
                "Proxy部署清单.csv")
                echo "Proxy-IP,运行端口,SSH端口,登录账号,密码,Manager-IP,proxy版本,yottaweb代理端口,auth代理端口,collector代理端口,yottaweb-IP,Auth-IP,Collector-IP"
                ;;
                "Agent关联Agent分组：Agent增加Agent分组清单.csv")
                echo "Agent-IP,Agent端口,Agent分组"
                ;;
                "添加搜索权限：搜索权限清单.csv")
                echo "名称,描述,资源标签,hostname,appname,tag,过滤条件" 
                ;;
                "日志易平台集群资源同步：多集群资源同步清单.csv")
                echo "主集群mysql节点IP,mysql账号,mysql密码,主集群mongodb节点IP,mongodb账号,mongodb密码,备集群mysql节点IP,mysql账号,mysql密码,备集群mongodb主节点IP,mongodb账号,mongodb密码"
                ;;
                "Exit")
                echo "退出！"
                exit
                break
                ;;
                *)
                echo "invalid option $REPLY"
                ;;
        esac
done
}

agent_agentgroup_add() {
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port&sort=-id" 2>/dev/null | jq -rc '.objects')
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ip port agentgroup;do
	agent_id=`echo "$agent_info_json" | jq '[.[]|{ip:.ip,port:.port,id:.id}]' | jq ".|map(select(.ip==\"$ip\" and .port==$port))|.[].id"`
        if  [[ x$agent_id != x ]] && [[ x$agentgroup != x ]];then
		agentgroup_id=`echo "$agentgroup_json" | jq ".|map(select(.name==\"$agentgroup\"))|.[].id"`
		if [[ x$agentgroup_id != x ]];then
			target_agents=`echo "$agent_info_json" | jq "[.[]|{id:.id,group_ids:.group_ids}]" | jq -rc ".|map(select(.id==$agent_id))|.[].group_ids"`
			group_ids_retrue=`echo "$target_agents" | grep -Eow "$agentgroup_id" | wc -l`
		else
			group_ids_retrue=""
		fi
	fi
	if [[ x$agent_id != x ]] && [[ -n "$agentgroup_id" ]] && [[ $group_ids_retrue == 0 ]];then
		target_agents=`echo "$agent_info_json" | jq "[.[]|{id:.id,group_ids:.group_ids}]" | jq -rc ".|map(select(.id==$agent_id))|.[]"`
		target_agents_json=`jq -Mcn --argjson s "$target_agents" '{target_agents:[$s]}'`
		add_member_return=$($request -H "$header" -H "$auth" -X POST -d "${target_agents_json}" \
		"${url}${api}/agentgroup/$agentgroup_id/add_member/" 2>/dev/null)
		add_member_return_stats=`echo "$add_member_return" | jq -rc .result`
	fi
        if [[ x$group_ids_retrue == x ]];then
                echo "Agent $ip:$port Add Agent分组 $agentgroup 不存在."
	elif [[ $group_ids_retrue != 0 ]];then
                echo "Agent $ip:$port Add Agent分组 $agentgroup 已存在."
	elif [[ $add_member_return_stats == "true" ]];then
                echo "Agent $ip:$port Add Agent分组 $agentgroup 已加入."
        else
                echo "Agent $ip:$port Add Agent分组 $agentgroup failed."
	fi
done
}

agent_logstream_add() {
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
sed -e 1d $source | shuf | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ip port appname tag log_directory file_match differentiator priority splitter_regex oldest_duration chartset time_format agentgroup;do
	agent_id=`echo "$agent_info_json" | jq '[.[]|{ip:.ip,port:.port,id:.id}]' | jq ".|map(select(.ip==\"$ip\" and .port==$port))|.[].id"`
	time_format=`echo "$time_format" | sed "s#ss SSS#ss,SSS#"`
        if  [[ x$agent_id != x ]] && [[ x$agentgroup != x ]];then
		agentgroup_id=`echo "$agentgroup_json" | jq ".|map(select(.name==\"$agentgroup\"))|.[].id"`
		if [[ x$agentgroup_id != x ]];then
			target_agents=`echo "$agent_info_json" | jq "[.[]|{id:.id,group_ids:.group_ids}]" | jq -rc ".|map(select(.id==$agent_id))|.[].group_ids"`
			group_ids_retrue=`echo "$target_agents" | grep -Eow "$agentgroup_id" | wc -l`
		else
			group_ids_retrue=""
		fi
	fi
	if [[ x$agent_id != x ]] && [[ -n "$agentgroup_id" ]] && [[ $group_ids_retrue == 0 ]];then
		target_agents=`echo "$agent_info_json" | jq "[.[]|{id:.id,group_ids:.group_ids}]" | jq -rc ".|map(select(.id==$agent_id))|.[]"`
		target_agents_json=`jq -Mcn --argjson s "$target_agents" '{target_agents:[$s]}'`
		add_member_return=$($request -H "$header" -H "$auth" -X POST -d "${target_agents_json}" \
		"${url}${api}/agentgroup/$agentgroup_id/add_member/" 2>/dev/null)
		add_member_return_stats=`echo "$add_member_return" | jq -rc .result`
	fi
	if [[ x$agent_id != x ]];then
		proxy_ip=$(echo "$agent_info_json" | jq -rc ".|map(select(.id==$agent_id))|.[].proxy_ip")
		proxy_port=$(echo "$agent_info_json" | jq -rc ".|map(select(.id==$agent_id))|.[].proxy_port")
                file_match=`echo "$file_match" | sed 's/\\\\/\\\\\\\\/g'`
                tag=`echo "$tag" | sed 's/ /,/g'`
                splitter_regex=`echo "$splitter_regex" | sed 's/\\\\/\\\\\\\\/g'`
                differentiator=`jq -Mnc --arg s "$differentiator" '($s|split(" "))'`
                priority=`jq -Mnc --arg s "$priority" '($s|split(" "))'`
		request_json=`jq -Mnr --argjson v \
                "{\"appname\":\"$appname\",\"charset\":\"${chartset:-utf-8}\",\"exclude\":\"\",\"file_match\":\"$file_match\",\
		\"log_directory\":\"$log_directory\",\"oldest_duration\":\"$oldest_duration\",\
                \"splitter_regex\":\"$splitter_regex\",\"tag\":\"$tag\",\"timestamp_configs\":\
		[{\"locale\":\"en\",\"max_timestamp_lookahead\":128,\"time_format\":\"$time_format\",\"time_prefix\":\"\",\"timezone\":\"Asia/Shanghai\"}],\
		\"differentiator\":$differentiator,\"priority\":$priority,\"type\":\"LogstreamerInput\"}" '$v'`
	    if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
		return_json=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" \
		"${url}${api}/agent/config/?ip_port=$ip:$port&proxy=&type=LogstreamerInput" 2>/dev/null)
	    else
		return_json=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" \
		"${url}${api}/agent/config/?ip_port=$ip:$port&proxy=$proxy_ip:$proxy_port&type=LogstreamerInput" 2>/dev/null)
	    fi
	    return_stats=$(echo "$return_json" | jq -rc .result)
            if [[ $return_stats == "true" ]] && [[ x$group_ids_retrue == x ]];then
                echo "Agent $ip:$port Add $(echo "$return_json" | jq -rc .object.reason),Agent分组 $agentgroup 不存在."
	    elif [[ $return_stats == "true" ]] && [[ $group_ids_retrue != 0 ]];then
                echo "Agent $ip:$port Add $(echo "$return_json" | jq -rc .object.reason),Agent分组 $agentgroup 已存在."
	    elif [[ $return_stats == "true" ]] && [[ $add_member_return_stats == "true" ]];then
                echo "Agent $ip:$port Add $(echo "$return_json" | jq -rc .object.reason),Agent分组 $agentgroup 已加入."
	    elif [[ $return_stats == "true" ]];then
		echo "Agent $ip:$port Add $(echo "$return_json" | jq -rc .object.reason)"
            elif [[ $return_stats == "false" ]] && [[ x$group_ids_retrue == x ]];then
                echo "Agent $ip:$port Add failed, $(echo "$return_json" | jq -rc .error.message),Agent分组 $agentgroup 不存在."
            elif [[ $return_stats == "false" ]] && [[ $group_ids_retrue != 0 ]];then
                echo "Agent $ip:$port Add failed, $(echo "$return_json" | jq -rc .error.message),Agent分组 $agentgroup 已存在."
	    elif [[ $return_stats == "false" ]] && [[ $add_member_return_stats == "true" ]];then
		echo "Agent $ip:$port Add failed, $(echo "$return_json" | jq -rc .error.message),Agent分组 $agentgroup 已加入."
	    else
		echo "Agent $ip:$port Add failed, $(echo "$return_json" | jq -rc .error.message)"
	    fi
	else
		echo "Agent $ip:$port Not Found, Skipped."
	fi
done
}

queryscope_add() {             #创建搜索权限，已存在的搜索权限将提示并跳过
queryscope_json=`$request -H "$auth" "${url}${api}/queryscopes/?fields=id,name&size=1000" 2>/dev/null | jq -rc '[.objects[]|{name:.name}]'`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d'| while IFS=',' read -r name description rt_names hostname appname tag querysting;do
        name_check=`echo "$queryscope_json" | jq -rc ".|map(select(.name==\"$name\"))|.[].name"`
        if [[ $(test "$name_check" && echo "yes" || echo "no") == "no" ]];then
            request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"description\":\"$description\",\"rt_names\":\"$rt_names\",\"hostname\":\"$hostname\",\"appname\":\"$appname\",\"tag\":\"$tag\",\"querysting\":\"$querysting\"}" '$v'`
            return_json=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api}/queryscopes/" 2>/dev/null)
            return_stats=$(echo "$return_json" | jq -rc .result)
            if [[ $return_stats == "true" ]];then
                echo "搜索权限【$name】添加完成."
            else
                echo "搜索权限【$name】添加失败,错误信息: $(echo "$return_stats" | jq -rc .error.message)"
            fi
        else
            echo "搜索权限【$name】已存在."
        fi
done
}

dataset_add() {                 #创建数据集，最多支持4级层级结构
dataset_json=`$request -H "$auth" "${url}${api3}/datasets/?size=1000&sort=-id" 2>/dev/null | jq -rcM '[.objects[]|{name:.name,alias:.alias}]'`

sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r level_id parent_name name alias action queryfilter rt_names;do
        if [[ $level_id == 1 ]];then
                dataset_check=`echo "$dataset_json" | jq -r ".|map(select(.name==\"$name\" and .alias==\"$alias\"))|.|length"`
                if [[ $dataset_check == 0 ]];then
                        rt_names=`echo "$rt_names" | sed -e 's/\"//g' -e 's/ /,/g'`
                        request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"alias\":\"$alias\",\"action\":\"$action\",\"queryfilter\":\"$queryfilter\",\"rt_names\":\"$rt_names\",\"app_ids\":1,\"fields\":\"[]\"}" '$v'`
                        return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api3}/datasets/" 2>/dev/null)
                        if [[ $(echo "$return" | jq .result) == "true" ]];then
                                echo "$level_id级数据集【$name】添加完成."
                        else
                                echo "$level_id级数据集【$name】添加失败,错误代码 $(echo "$return" | jq .error.code),错误信息: $(echo "$return" | jq -rc .error.message)"
                        fi
                else
                        echo "$level_id级数据集【$name】添加失败,节点已存在."
                fi
        elif [[ $level_id == 2 ]];then
                dataset_id=`$request -H "$auth" "${url}${api3}/datasets/?size=1000&sort=-id" 2>/dev/null \
                | jq -rcM '[.objects[]|{name:.name,id:.id}]' | jq -r ".|map(select(.name==\"$parent_name\"))|.[].id"`
                if [[ x$dataset_id != x ]];then
                        node_check=`$request -H "$auth" "${url}${api3}/datasets/$dataset_id/" 2>/dev/null \
                        | jq -r ".object.nodes|map(select(.name==\"$name\"))|length"`
                        if [[ $node_check == 0 ]];then
                                request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"queryfilter\":\"$queryfilter\",\"parent_id\":0}" '$v'`
                                return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api3}/datasets/$dataset_id/add_node/" 2>/dev/null)
                                echo "$level_id级数据集【$name】添加完成."
                        else
                                echo "$level_id级数据集【$name】添加失败,节点已存在."
                        fi
                else
                        echo "$level_id级数据集【$name】添加失败,1级数据集【$parent_name】不存在."
                fi
        elif [[ $level_id == 3 ]];then
                node_json=`$request -H "$auth" "${url}${api3}/datasets/?size=1000&sort=-id" 2>/dev/null \
                | jq -r "[.objects[].nodes]" | jq -rc ".[]|map(select(.name==\"$parent_name\"))|.[]|{id:.id,dataset_id:.dataset_id,nodes:.nodes}"`
                if [[ x$node_json != x ]];then
                        parent_id=`echo "$node_json" | jq .id`
                        dataset_id=`echo "$node_json" | jq .dataset_id`
                        if [[ x$parent_id != x ]];then
                                node_check=`echo "$node_json" | jq -r ".nodes|map(select(.name==\"$name\"))|length"`
                                if [[ $node_check == 0 ]];then
                                        request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"queryfilter\":\"$queryfilter\",\"parent_id\":$parent_id}" '$v'`
                                        return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api3}/datasets/$dataset_id/add_node/" 2>/dev/null)
                                        echo "$level_id级数据集【$name】添加完成."
                                else
                                        echo "$level_id级数据集【$name】添加失败,节点已存在."
                                fi
                        else
                                echo "$level_id级数据集【$name】添加失败,2级数据集【$parent_name】不存在."
                        fi
                else
                        echo "$level_id级数据集【$name】添加失败,2级数据集【$parent_name】不存在."
                fi
        elif [[ $level_id == 4 ]];then
                node_json=`$request -H "$auth" "${url}${api3}/datasets/?size=1000&sort=-id" 2>/dev/null \
                | jq -r "[.objects[].nodes[].nodes]" | jq -rc ".[]|map(select(.name==\"$parent_name\"))|.[]|{id:.id,parent_id:.parent_id,dataset_id:.dataset_id,nodes:.nodes}"`
                if [[ x$node_json != x ]];then
                        parent_id=`echo "$node_json" | jq .id`
                        dataset_id=`echo "$node_json" | jq .dataset_id`
                        if [[ x$parent_id != x ]];then
                                node_check=`echo "$node_json" | jq -r ".nodes|map(select(.name==\"$name\"))|length"`
                                if [[ $node_check == 0 ]];then
                                        request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"queryfilter\":\"$queryfilter\",\"parent_id\":$parent_id}" '$v'`
                                        return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api3}/datasets/$dataset_id/add_node/" 2>/dev/null)
                                        echo "$level_id级数据集【$name】添加完成."
                                else
                                        echo "$level_id级数据集【$name】添加失败,节点已存在."
                                fi
                        else
                                echo "$level_id级数据集【$name】添加失败,3级数据集【$parent_name】不存在."
                        fi
                else
                        echo "$level_id级数据集【$name】添加失败,3级数据集【$parent_name】不存在."
                fi        
	fi
done
}

agentgroup_add() {
roles_json=`$request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null | jq -rMc '[.objects[]|{name:.name,id:.id}]'`

sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name memo rt_names roles;do
	roles=`echo "$roles" | sed -e 's/\"//g' | sed -e 's/\r$//g'`
	roles=(${roles[@]})
	for (( i=0; i<${#roles[@]}; i++ ));do
        	role_id=`echo "$roles_json" | jq -rc ".|map(select(.name==\"${roles[$i]}\"))|.[].id"`
		roles_id[${#roles_id[@]}]=${role_id}
	done
	role_ids=`echo "${roles_id[@]}" | sed 's/ /,/g'`
	role_ids=`jq -Mnc --arg s "$role_ids" '($s|split(","))' | sed 's/\"//g'`
	unset roles_id
	request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"memo\":\"$memo\",\"rt_names\":\"$rt_names\",\"roles\":$role_ids}" '$v'`
	return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api3}/agentgroup/" 2>/dev/null)
	if [[ $(echo "$return" | jq .result) == "true" ]];then
		echo "Agent分组【$name】created success."
	else
		echo "Agent分组【$name】created failure,error message:$(echo "$return" | jq -rc .error.message)"
	
	fi
done
}

usergroup_add() {
roles_json=`$request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null | jq -rMc '[.objects[]|{name:.name,id:.id}]'`
account_json=`$request -H "$auth" "${url}${api}/accounts/?size=1000&sort=-id" 2>/dev/null | jq -Mrc "[.objects[]|{id:.id,name:.name}]"`

sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name memo admin roles;do
	roles=`echo "$roles" | sed -e 's/\"//g'`
	roles=(${roles[@]})
	if [[ x$admin != x ]];then
		admin_id=`echo "$account_json" | jq -rc ".|map(select(.name==\"$admin\"))|.[].id"`	
	else
		admin_id=""
	fi
	for (( i=0; i<${#roles[@]}; i++ ));do
		role_id=`echo "$roles_json" | jq -rc ".|map(select(.name==\"${roles[$i]}\"))|.[].id"`
		if [[ x$role_id == x ]];then
			roles_return=$($request -H "$header" -H "$auth" -X POST -d "{\"name\":"\"${roles[$i]}\"",\"memo\":\"\"}" "${url}${api}/roles/" 2>/dev/null)
			role_id=`$request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null \
			| jq -rMc '[.objects[]|{name:.name,id:.id}]' | jq -rc ".|map(select(.name==\"${roles[$i]}\"))|.[].id"`
		fi
		roles_id[${#roles_id[@]}]=$role_id	
	done
	role_ids=`echo "${roles_id[@]}" | sed 's/ /,/g'`
	unset roles roles_id
	request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"memo\":\"$memo\",\"administrator_ids\":\"$admin_id\",\"role_ids\":\"$role_ids\"}" '$v'`	
	return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api}/usergroups/" 2>/dev/null)
        if [[ $(echo "$return" | jq .result) == "true" ]];then
                echo "用户分组【$name】created success."
        else
                echo "用户分组【$name】created failure,error message:$(echo "$return" | jq -rc .error.message)"
        fi
done
}

account_add() {                  #用户账号创建
groups_json=`$request -H "$auth" "${url}${api}/usergroups/" 2>/dev/null | jq -rMc '[.objects[]|{name:.name,id:.id}]'`

sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name full_name passwd email phone groups_name;do
        account_check=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -r '[.objects[]|{name:.name}]' | jq '.|map(select(.name=="'$name'"))|.[].name'`
        email_check=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -r '[.objects[]|{email:.email}]' | jq '.|map(select(.email=="'$email'"))|.[].email'`
if [[ -z "$account_check" ]] && [[ -z "$email_check" ]];then 
        passwd=`echo -n "$passwd" | md5sum | awk '{print $1}'`
        array=`echo "$groups_name" | tr ',' ' ' | sed 's/\"//g' | sed 's/\r$//g'`
        n=0;for group_name in ${array[@]};do
                group_id=`echo "$groups_json" | jq '.|map(select(.name=="'$group_name'"))|.[].id'`
                if [[ -n $group_id ]];then
                        group_ids[$n]=$group_id;((n++));
                fi
	done
	unset group_id
        group_ids=`echo "${group_ids[@]}" | sed 's/\s/,/g'`
        if [[ x$groups_name != x ]] && [[ x$group_ids != x ]];then
		request_json=`echo -e "$name $full_name $passwd $email $phone $group_ids" | jq -Mnr --argjson v \
        	'{"name":"'$name'","full_name":"'$full_name'","passwd":"'$passwd'","email":"'$email'","phone":"'$phone'","group_ids":"'$group_ids'"}' '$v'`
        	return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api}/accounts/" 2>/dev/null)
        	if [[ $(echo "$return" | jq .result) == "true" ]];then
                	echo "$full_name Account $name created success,userid: $(echo "$return" | jq .object)"
        	else
                	echo "$full_name Account $name created failure,error message: $(echo "$return" | jq -rc .error.message)"
        	fi
	else
		echo "Account $name groups [$groups_name] Not Found."
	fi
	unset group_ids
elif [[ -n $account_check ]];then
        echo "$full_name Account name $name already exists."
elif [[ -n $email_check ]];then
        echo "$full_name Account name $name email $email already exists."
fi
done
}

account_disable() {
account_json=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name full_name passwd email phone groups_name;do
        account_id=`echo "$account_json" | jq -rc '.|map(select(.name=="'$name'"))|.[].id'`
if [[ -n "$account_id" ]];then
	return=$($request -H "$auth" -H "$header" -X PUT -d "{}" "${url}${api}/accounts/$account_id/disable/" 2>/dev/null)
	if [[ $(echo "$return" | jq .result) == "true" ]];then
		echo "Account $name($full_name) is disabled."
	else
		echo "Account $name($full_name) disable failure,error message: $(echo "$return" | jq -rc .error.message)"
	fi	
fi
done
}

account_enable() {
account_json=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
account_cnt=`sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | wc -l`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name full_name passwd email phone groups_name;do
        account_id=`echo "$account_json" | jq -rc '.|map(select(.name=="'$name'"))|.[].id'`
        if [[ -n "$account_id" ]];then
                return=$($request -H "$auth" -H "$header" -X PUT -d "{}" "${url}${api}/accounts/$account_id/enable/" 2>/dev/null)
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo "Account $name($full_name) is enabled."
                else
                        echo "Account $name($full_name) enable failure,error message: $(echo "$return" | jq -rc .error.message)"
                fi
        fi
done
}

account_delete() {
account_json=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r name full_name passwd email phone groups_name;do
        account_id=`echo "$account_json" | jq -rc '.|map(select(.name=="'$name'"))|.[].id'`
if [[ -n "$account_id" ]];then
        return=$($request -H "$auth" -X DELETE "${url}${api}/accounts/$account_id/" 2>/dev/null)
        if [[ $(echo "$return" | jq .result) == "true" ]];then
                echo "Account $name($full_name) is deleted"
        else
                echo "Account $name($full_name) delete failure,error message: $(echo "$return" | jq -rc .error.message)"
        fi
fi
done
}

account_filter_enable() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出管控账号清单"
accounts=`echo "$account_name" | sed -e 's/\"//g;s/,/ /g'`
accounts=(${accounts[@]})
account_json=`$request -H "$auth" "${url}${api}/accounts/" 2>/dev/null | jq -r '[.objects[]|{name:.name,id:.id,full_name:.full_name,enabled:.enabled}]'`
enabled_account_ids=`echo "$account_json"  | jq -rc ".|map(select(.enabled==true))|.[].id" | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
enabled_account_ids=(${enabled_account_ids[@]})         #平台启用状态的账号id数组
for (( i=0; i<${#accounts[@]}; i++ ));do                #指定启用的账号id数组
        account_id=`echo "$account_json" | jq -rc ".|map(select(.enabled==true and .name==\"${accounts[$i]}\"))|.[].id"`
        account_ids[${#account_ids[@]}]=${account_id}
done
account_ids=(${account_ids[@]})
unset account_id accounts
for (( x=0;  x<${#account_ids[@]}; x++ ));do    #平台启用状态的账号id数组，去除指定的启用账号id数组，得到待禁用的账号id数组
        disable_account_id=$(echo ${enabled_account_ids[@]} | sed 's/\<'${account_ids[$x]}'\>//')
        unset enabled_account_ids
        enabled_account_ids=(${disable_account_id[@]})
done
disable_account_ids=(${enabled_account_ids[@]})
unset disable_account_id enabled_account_ids
if [[ -n $disable_account_ids ]];then   #批量禁用管控账号，并输出禁用账号清单到csv文件
        echo "账号名,全名,启用状态" >> ./${filename}_${download_time}.csv
        for (( y=0; y<${#disable_account_ids[@]}; y++ ));do
                start=`expr $y + 1`
                progress_bar $start ${#disable_account_ids[@]}
                name=`echo "$account_json" | jq -rc ".|map(select(.id==${disable_account_ids[$y]}))|.[].name"`
                full_name=`echo "$account_json" | jq -rc ".|map(select(.id==${disable_account_ids[$y]}))|.[].full_name"`
                return=$($request -H "$auth" -H "$header" -X PUT -d "{}" \
                "${url}${api}/accounts/${disable_account_ids[$y]}/disable/" 2>/dev/null)
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo -e "\nAccount $name($full_name) is disabled."
                        echo "$name,$full_name,false" >> ./${filename}_${download_time}.csv
                else
                        echo -e "\nAccount $full_name $name disable failure,error message: $(echo "$return" | jq -rc .error.message)"
                fi

        done
echo "file ${filename}_${download_time}.csv Export success"
printf 'Finished!\n'
else
        echo "没有符合的账号被禁用."
fi
}

account_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出用户清单"
echo "用户ID,名称,全名,邮箱地址,电话号码,启用状态,所属分组" >> ./${filename}_${download_time}.csv
account_ids=`$request -H "$auth" "${url}${api}/accounts/?&size=1000&sort=-id" 2>/dev/null | jq '.objects[]|.id' \
| sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
account_ids=(${account_ids[@]})
for (( i=0; i<${#account_ids[@]}; i++ ));do
        account_info=`$request -H "$auth" "${url}${api}/accounts/${account_ids[$i]}/" 2>/dev/null \
        | jq -rc '.object|[.id,.name,.full_name,.email,.phone,.enabled]' | sed -e 's/^\[//g' -e 's/\]$//g'`
        usergroups=`$request -H "$auth" "${url}${api}/accounts/${account_ids[$i]}/" 2>/dev/null | jq -rc '.object|[.account_groups[].name]' \
        | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"//g'`
        echo "$account_info","\"$usergroups\"" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#account_ids[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

dataset_sync() {                #从数据集清单csv文件同步1级数据集到平台，以csv文件中1级数据集为准进行同步
dataset_name_array=$($request -H "$auth" "${url}${api}/dataset/?size=1000&sort=-id" 2>/dev/null \
 | jq -rc '.objects[]|.name' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
dataset_name_array=(${dataset_name_array[@]})
sync_dataset_name_array=`sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | grep -Ew '^1' | awk -F ',' '{print $3}' | tr '\n' ' '`
sync_dataset_name_array1=(${sync_dataset_name_array[@]})
sync_dataset_name_array2=(${sync_dataset_name_array[@]})
for (( x=0; x<${#dataset_name_array[@]}; x++ ));do      #排除平台已存在的数据集，得到待新增的数据集列表
        add_dataset_name_array=$(echo "${sync_dataset_name_array1[@]}" | sed 's/\<'${dataset_name_array[$x]}'\>//')
        unset sync_dataset_name_array1
        sync_dataset_name_array1=(${add_dataset_name_array[@]})
done
add_dataset_name_array=(${sync_dataset_name_array1[@]})
unset sync_dataset_name_array1
if [[ -n $add_dataset_name_array ]];then
        for (( i=0; i<${#add_dataset_name_array[@]}; i++ ));do
                add_dataset_raw=`grep -Ew '^1' $source | grep -Ew "${add_dataset_name_array[$i]}"`
                level_id="";parent_name="";name="";alias="";action="";queryfilter="";rt_nams="";
                eval $(echo "$add_dataset_raw" | awk -F ',' '{ printf("level_id=%s;parent_name=%s;name=\"%s\";alias=\"%s\";action=%s;queryfilter=\"%s\";rt_names=\"%s\"",$1,$2,$3,$4,$5,$6,$7)}')
                rt_names=`echo "$rt_names" | sed -e 's/\"//g' -e 's/ /,/g'`
                request_json=`jq -Mnr --argjson v "{\"name\":\"$name\",\"alias\":\"$alias\",\"action\":\"$action\",\"queryfilter\":\"$queryfilter\",\"rt_names\":\"$rt_names\",\"app_ids\":\"\"}" '$v'`
                return=$($request -H "$header" -H "$auth" -X POST -d "${request_json}" "${url}${api}/dataset/" 2>/dev/null)
                start=`expr $i + 1`
                progress_bar $start ${#add_dataset_name_array[@]}
                printf '\nFinished!\n'
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo "新增数据集【$name】添加完成."
                else
                        echo "新增数据集【$name】添加失败,错误信息: $(echo "$return" | jq -rc .error.message)"
                fi
        done
fi
for (( x=0; x<${#sync_dataset_name_array2[@]}; x++ ));do        #排除数据集清单中已存在的数据集，得到待清理的数据集列表
        del_dataset_name_array=$(echo "${dataset_name_array[@]}" | sed 's/\<'${sync_dataset_name_array2[$x]}'\>//')
        unset dataset_name_array
        dataset_name_array=(${del_dataset_name_array[@]})
done
del_dataset_name_array=(${dataset_name_array[@]})
unset dataset_name_array
if [[ -n $del_dataset_name_array ]];then
        dataset_id_name_json=$($request -H "$auth" "${url}${api}/dataset/?size=1000&sort=-id" 2>/dev/null \
        | jq -c '[.objects[]|{id:.id,name:.name}]')
        for (( i=0; i<${#del_dataset_name_array[@]}; i++ ));do
                name=${del_dataset_name_array[$i]}
                dataset_id=`echo "$dataset_id_name_json" | jq -rc '.|map(select(.name=="'${del_dataset_name_array[$i]}'"))|.[].id'`
                return=$($request -H "$auth" -X DELETE "${url}${api}/dataset/$dataset_id/" 2>/dev/null)
                start=`expr $i + 1`
                progress_bar $start ${#del_dataset_name_array[@]}
                printf '\nFinished!\n'
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo "下线数据集【$name】删除完成."
                else
                        echo "下线数据集【$name】删除失败,错误信息: $(echo "$return" | jq -rc .error.message)"
                fi
        done
fi
if [[ -z $add_dataset_name_array && -z $del_dataset_name_array ]];then
        echo "数据集清单与平台数据集一致,无须同步."
fi
}

dataset_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出数据集清单"
echo "数据集ID,名称,约束语句,父子行为" >> ./${filename}_${download_time}.csv
dataset_id_array=$($request -H "$auth" "${url}${api}/dataset/?size=10000&sort=id" 2>/dev/null \
| jq '.objects[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
dataset_id_array=(${dataset_id_array[@]})
for (( i=0; i<${#dataset_id_array[@]}; i++ ));do
	dataset_json=`$request -H "$auth" "${url}${api}/dataset/${dataset_id_array[$i]}/" 2>/dev/null`
        echo "$dataset_json" | jq -rc '[.object|.id,.name,.queryfilter,.action]' | sed 's/^\[//g;s/\]$//g;s/1$/汇聚/g;s/0$/无/g;s/2$/继承/g' >> ./${filename}_${download_time}.csv
	i_len=`echo "$dataset_json"| jq -rc ".object.nodes|length"`
	if [[ "$i_len" != "0" ]];then
		for (( x=0; x<$i_len; x++ ));do
		echo "$dataset_json" | jq -rc ".object.nodes[$x]" | jq -rc '.|[.dataset_id,.id,.name,.queryfilter]' \
                | sed 's/^\[//g;s/\]$//g;s@,@.@1' >> ./${filename}_${download_time}.csv
		x_len=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes|length"`
			if [[ "$x_len" != "0" ]];then
			for (( y=0; y<$x_len; y++ ));do
                                echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y]" | jq -rc '.|[.dataset_id,.parent_id,.id,.name,.queryfilter]' \
                                | sed 's/^\[//g;s/\]$//g;s@,@.@1;s@,@.@1' >> ./${filename}_${download_time}.csv
                                y_len=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y].nodes|length"`
                                if [[ "$y_len" != "0" ]];then
                                        parent_up_id=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y]" | jq -rc '.|[.dataset_id,.parent_id]' | sed 's/^\[//g;s/\]$//g;s@,@.@1'`
                                        for (( z=0; z<$y_len; z++ ));do
                                                dataset_4_info=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y].nodes[$z]" | jq -rc '.|[.parent_id,.id,.name,.queryfilter]' \
                                                | sed 's/^\[//g;s/\]$//g;s@,@.@1'` 
                                                echo "$parent_up_id.$dataset_4_info" >> ./${filename}_${download_time}.csv
                                                z_len=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y].nodes[$z].nodes|length"`
                                                if [[ "$z_len" != "0" ]];then
                                                        parent_up2_id=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y]" | jq -rc '.|[.dataset_id,.parent_id,.id]' | sed 's/^\[//g;s/\]$//g;s@,@.@1;s@,@.@1'`
                                                        for (( s=0; s<$y_len; s++ ));do
                                                                dataset_5_info=`echo "$dataset_json" | jq -rc ".object.nodes[$x].nodes[$y].nodes[$z].nodes[$s]" | jq -rc '.|[.parent_id,.id,.name,.queryfilter]' \
                                                                | sed 's/^\[//g;s/\]$//g;s@,@.@1'` 
                                                                echo "$parent_up2_id.$dataset_5_info" >> ./${filename}_${download_time}.csv
                                                        done
                                                fi
                                        done
                                fi
			done
			fi
		done
	fi
        start=`expr $i + 1`
        progress_bar $start ${#dataset_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

schedule_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出定时任务清单"
echo "定时任务ID,名称,启用状态,运行用户,check_interval,crontab,搜索条数,时间范围,搜索内容" >> ./${filename}_${download_time}.csv
schedule_id_array=$($request -H "$auth" "${url}${api}/schedules/?&size=10000&sort=-id" 2>/dev/null \
| jq '.objects[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
schedule_id_array=(${schedule_id_array[@]})
for (( i=0; i<${#schedule_id_array[@]}; i++ ));do
	schedule_json=`$request -H "$auth" "${url}${api}/schedules/${schedule_id_array[$i]}/" 2>/dev/null`
        schedule_info=`echo "$schedule_json" | jq -rc "[.object|.id,.name,.enabled,.executor_name,.check_interval,.crontab]" | sed -e 's/^\[//g' -e 's/\]$//g'`
	request_json=`echo "$schedule_json" | jq -rc ".object.request"`
	query=`echo "$request_json" | grep -Eo "query[^&]*" | awk -F '=' '{print $2}'`
	size=`echo "$request_json" | grep -Eo "size=[^&]*" | awk -F '=' '{print $2}'`
	time_range=`echo "$request_json" | grep -Eo "time_range[^&]*" | awk -F '=' '{print $2}'`
	time_range_encode=`echo "$time_range" | sed -e 's/%2C/,/g'`
	query_encode1=`echo -n "$query" | sed 's/\\\\/\\\\\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\\x\2/g'`
	query_encode=`printf $query_encode1"\n" | sed -e 's/"/""/g' | tr -d "[\n\t]"`
	#URL解码，单引号替换为双引号，删除\t换行符和\t制表符
	echo "$schedule_info",\"$size\",\"$time_range_encode\","\"$query_encode\"" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#schedule_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}


dashboard2_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出仪表盘清单"
echo "仪表盘ID,名称,资源标签,标签页名称,趋势图名称" >> ./${filename}_${download_time}.csv
dashboard_id_array=$($request -H "$auth" "${url}${api}/dashboards/?size=1000&fields=id&sort=-id" 2>/dev/null \
| jq '.objects[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
dashboard_id_array=(${dashboard_id_array[@]})
for (( i=0;i<${#dashboard_id_array[@]};i++ ));do
        dashboard_json=`$request -H "$auth" "${url}${api}/dashboards/${dashboard_id_array[$i]}/" 2>/dev/null`
        id_name=`echo "$dashboard_json" | jq -rc '[.object|.id,.name]' | sed -e 's/^\[//g' -e 's/\]$//g'`
        rt_list=`$request -H "$auth" "${url}${api}/dashboards/?size=1000&fields=id&sort=-id" 2>/dev/null \
        | jq -rc '.objects' | jq -rc ".|map(select(.id==${dashboard_id_array[$i]}))|.[].rt_list[].name" | sed '/\r$/d' | tr '\n' ',' | sed 's/\,$//g'`
        tabs_count=`echo "$dashboard_json" | jq '.object.tabs|length'`
	for (( x=0;x<$tabs_count;x++));do
        	#tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[$x].content" | jq -rc ".info.title"`
        	tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[$x].content" | jq -rc ".name"`
        	trend_count=`echo "$dashboard_json" | jq -rc ".object|.tabs[$x].content" | jq -rc ".widgets|length"`
		for ((y=0;y<$trend_count;y++));do
			trendName=`echo "$dashboard_json" | jq -rc ".object|.tabs[$x].content" | jq -rc ".widgets[$y].searchData.trendName"`
			echo "$id_name",\"$rt_list\",\"$tabs_name\",\"$trendName\" >> ./${filename}_${download_time}.csv
		done
	done
        start=`expr $i + 1`
        progress_bar $start ${#dashboard_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

dashboard_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出仪表盘清单"
echo "仪表盘ID,名称,资源标签,1标签页趋势图合集,2标签页趋势图合集,3标签页趋势图合集,4标签页趋势图合集,5标签页趋势图合集,6标签页趋势图合集" >> ./${filename}_${download_time}.csv
dashboard_id_array=$($request -H "$auth" "${url}${api}/dashboards/?size=1000&fields=id&sort=-id" 2>/dev/null \
| jq '.objects[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
dashboard_id_array=(${dashboard_id_array[@]})
for (( i=0;i<${#dashboard_id_array[@]};i++ ));do
	dashboard_json=`$request -H "$auth" "${url}${api}/dashboards/${dashboard_id_array[$i]}/" 2>/dev/null`
	id_name=`echo "$dashboard_json" | jq -rc '[.object|.id,.name]' | sed -e 's/^\[//g' -e 's/\]$//g'`	
	rt_list=`$request -H "$auth" "${url}${api}/dashboards/?size=1000&fields=id&sort=-id" 2>/dev/null \
	| jq -rc '.objects' | jq -rc ".|map(select(.id==${dashboard_id_array[$i]}))|.[].rt_list[].name" | sed '/\r$/d' | tr '\n' ',' | sed 's/\,$//g'`
	tabs_count=`echo "$dashboard_json" | jq '.object.tabs|length'`
	if [ 0 -lt $tabs_count ];then
	tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[0].content" | jq -rc .info.title`
	tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[0].content" | jq -rc \
	'[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
	tabs_1_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
        if [ 1 -lt $tabs_count ];then
        tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[1].content" | jq -rc .info.title`
        tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[1].content" | jq -rc \
        '[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
        tabs_2_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
        if [ 2 -lt $tabs_count ];then
        tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[2].content" | jq -rc .info.title`
        tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[2].content" | jq -rc \
        '[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
        tabs_3_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
        if [ 3 -lt $tabs_count ];then
        tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[3].content" | jq -rc .info.title`
        tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[3].content" | jq -rc \
        '[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
        tabs_4_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
        if [ 4 -lt $tabs_count ];then
        tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[4].content" | jq -rc .info.title`
        tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[4].content" | jq -rc \
        '[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
        tabs_5_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
        if [ 5 -lt $tabs_count ];then
        tabs_name=`echo "$dashboard_json" | jq -rc ".object|.tabs[5].content" | jq -rc .info.title`
        tabs_content=`echo "$dashboard_json" | jq -rc ".object|.tabs[5].content" | jq -rc \
        '[.widgets[].searchData|{trendName:.trendName,query:.query,time_range:.time_range,sourcegroup:.sourcegroup,size:.size}]'`
        tabs_6_json=`jq -Mcn --argjson content "${tabs_content}" '{"title":"'$tabs_name'",$content}' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	fi
	echo "$id_name",\"$rt_list\","\"${tabs_1_json:-""}\"","\"${tabs_2_json:-""}\"","\"${tabs_3_json:-""}\"","\"${tabs_4_json:-""}\"","\"${tabs_5_json:-""}\"","\"${tabs_6_json:-""}\"" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#dashboard_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

report_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出报表清单"
echo "报表ID,名称,运行用户,启用状态,报表类型,邮件主题,触发周期,触发时间,crontab,资源标签,接收邮箱,趋势图集合" >> ./${filename}_${download_time}.csv
report_id_array=$($request -H "$auth" "${url}${api}/reports/?size=1000&fields=id&sort=-id" 2>/dev/null | jq '.objects[]|.id' | tr '\n' ' ' | sed 's/\s$//g')
report_id_array=(${report_id_array[@]})
for (( i=0;i<${#report_id_array[@]};i++ ));do
	report_json=`$request -H "$auth" "${url}${api}/reports/${report_id_array[$i]}/" 2>/dev/null`
	report_info=`echo "$report_json" | jq -rc '.object|[.id,.name,.executor_name,.enabled,.report_type,.subject,.frequency,.triggertime,.crontab]' | sed -e 's/^\[//g' -e 's/\]$//g'`
	rt_list=`echo "$report_json" | jq -rc '.object|.rt_list[].name' | sed '/\r$/d' | tr '\n' ',' | sed 's/\,$//g'`
	email=`echo "$report_json" |  jq -rc '.object|.email' | jq -rc '.email[]' 2>/dev/null | sed '/\r$/d' | tr '\n' ',' | sed 's/\,$//g'`
	if [[ x$email == x ]];then
		email=`echo "$report_json" |  jq -rc '.object|.email'`
	fi
	trend=`echo "$report_json" | jq -rc '.object|.content' | jq -rc .\
	 | jq -rc '[.[]|{time_range:.data.time_range,query:.data.query,trendName:.data.trendName,sourcegroup:.data.sourcegroup}]' | sed -e 's/\\\n//g' -e 's/\\\t//g' | sed 's/"/""/g'`
	#3.8版本是.data.sourcegroup,3.7版本是.datasetInfo
	echo "$report_info","\"$rt_list\"","\"$email\"","\"$trend\"" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#report_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

alert_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出监控清单"
echo "告警ID,名称,运行用户,启用状态,crontab,执行周期(秒),资源标签,监控类型,统计时段,触发条件,搜索内容,短信告警联系人,短信告警发送条件,邮件告警联系人,邮件告警发送条件,业务网管平台告警联系人,业务网管平台告警发送条件" >> ./"${filename}"_${download_time}.csv
alert_id_array=$($request -H "$auth" "${url}${api3}/alerts/?size=1000&fields=id&sort=-id" 2>/dev/null | jq '.objects[]|.id' | tr '\n' ' ' | sed 's/\s$//g')
alert_id_array=(${alert_id_array[@]})
for (( a=0;a<${#alert_id_array[@]};a++ ));do
	alert_json=`$request -H "$auth" "${url}${api3}/alerts/${alert_id_array[$a]}/" 2>/dev/null`
	alert_info=`echo "$alert_json" | jq -rc '.object|[.id,.name,.executor_name,.enabled,.crontab,.check_interval]' | sed -e 's/^\[//g' -e 's/\]$//g'`
	category=`echo "$alert_json" | jq -rc '.object.category'`
	timerange=`echo "$alert_json" | jq -rc '.object.check_condition' | jq -rc .timerange`
	if [[ $category == "0" ]];then
		check_condition=`echo "$alert_json" | jq -rc '.object.check_condition' | jq -rc '[.function,.operator,.threshold]' | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"/""/g'`
		category_type="事件数监控"
        elif [[ $category == "2" ]];then
                check_condition=`echo "$alert_json" | jq -rc '.object.check_condition' | jq -rc '[.field,.operator,.threshold]' | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"/""/g'`
                category_type="连续统计监控"
	elif [[ $category == "4" ]];then
		check_condition=`echo "$alert_json" | jq -rc '.object.check_condition' | jq -rc '[.field,.operator,.threshold]' | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"/""/g'`
		category_type="SPL统计监控"
	fi	
	rt_list=`echo "$alert_json" | jq -rc '.object|.rt_list[].name' | sed '/\r$/d' | tr '\n' ',' | sed 's/,$//g'`
	query=`echo "$alert_json" | jq -rc '.object.query' | sed 's/"/""/g' | tr -d '[\n\t]'`	
	alert_metas_len=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc '.|length'`
        if [[ $alert_metas_len != 0 ]];then
        for (( i=0;i<$alert_metas_len;i++ ));do
		name=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].name"`
		levels=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].levels" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"//g'`
		if [[ $name == "migu_sms" ]];then
			sms_levels=$levels
			sms_phone=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].configs[0].value" | sed 's/,/\//g'`
                elif [[ $name == "hubei_bank_sms" ]];then
                        sms_levels=$levels
                        sms_phone=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].configs[0].value" | sed 's/,/\//g'`
                elif [[ $name == "hubei_bank_monitor" ]];then
                        sms_levels=$levels
                        sms_phone=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].configs[0].value" | sed 's/,/\//g'`
		elif [[ $name == "email_V2" ]] || [[ $name == "email" ]];then
			email_levels=$levels
			email_receiver=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].configs[1].value"`
		elif [[ $name == "migu_zabbix" ]];then
			zabbix_levels=$levels
			zabbix_receiver=`echo "$alert_json" | jq -rc '.object.alert_metas' | jq -rc ".[$i].configs[2].value"`
		fi
	done
        fi	
	echo "$alert_info","\"$rt_list\"","\"$category_type\"","\"$timerange\"","\"$check_condition\"","\"$query\"","\"$sms_phone\"","\"$sms_levels\"","\"$email_receiver\"","\"$email_levels\"","\"$zabbix_receiver\"","\"$zabbix_levels\"" >> ./${filename}_${download_time}.csv
        unset sms_levels sms_phone email_levels email_receiver zabbix_levels zabbix_receiver
        start=`expr $a + 1`
        progress_bar $start ${#alert_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出Agent清单"
echo "Agent-id,IP,端口,主机名,操作系统,平台,版本,启动状态,Agent分组,资源标签" >> ./${filename}_${download_time}.csv
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null \
| jq -rc '[.objects[]|{id:.id,name:.name,rt_list:.rt_list}]'`
default_agent_group_id=`echo "$agentgroup_json" | jq ".|map(select(.name=="\"__default_agent_group__\""))|.[].id" | sed 's/\"//g'`
agent_id_group_ids_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_id_group_ids_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g' )
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
	groups_ids_array=`echo "$agent_id_group_ids_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].group_ids" | tr ',' ' '`
	groups_ids_array=(${groups_ids_array[@]/$default_agent_group_id})
	if [[ -n "$groups_ids_array" ]];then
	for group_id in ${groups_ids_array[@]};do
                group_name=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].name" | sed 's/\"//g'`
		groups_name[${#groups_name[@]}]=${group_name}
		group_array=`echo \"${groups_name[@]}\" | sed 's/\s/,/g'`
		resource_tag=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].rt_list[].name" | sed 's/\"//g'`
		resource_tags[${#resource_tags[@]}]=${resource_tag}
		resource_tags_array=`echo \"${resource_tags[@]}\" | sed 's/\s/,/g'`
	done
	else 
		group_array="\"__default_agent_group__\""
	fi
	unset groups_ids_array groups_name resource_tags
	agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
	| jq -rc "[.object|.id,.ip,.port,.hostname,.os,.platform,.cur_version,.status]" | sed -e 's/^\[//g' -e 's/\]$//g'`
	echo "$agent_info","$group_array","$resource_tags_array" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agentgroup_download() {
download_time=`date '+%Y%m%d%H%M'`	#导出Agent分组、描述、组织标签、分配角色
filename="导出Agent分组清单"
echo "Agent分组,描述,组织标签,分配角色" >> ./${filename}_${download_time}.csv
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&sort=-id" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name,memo:.memo,rt_list:.rt_list}]'`
agentgroup_array=`echo "$agentgroup_json" | jq -rc ".[].name" | grep -Ev '(__default_agent_group__)' | tr ',' ' ' | sed -e 's/\"//g' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
agentgroup_array=(${agentgroup_array[@]})
role_json=`$request -H "$auth" "${url}${api}/roles/?&size=1000" 2>/dev/null | jq -rc '[.objects[]|{name:.name,id:.id}]'`
role_array=`echo "$role_json" | jq -rc ".[].name" | grep -Ev '(admin|General_User|general_user|^__)' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
role_array=(${role_array[@]})
Role_AgentGroupId_Json="{\"data\":[]}"
for ((x=0; x<${#role_array[@]}; x++ ));do
	role_id=`echo "$role_json" | jq -rc ".|map(select(.name=="\"${role_array[$x]}\""))|.[].id"`
	role_agentgroup=`$request -H "$auth" "${url}${api}/permissions/role/$role_id/meta/?resource_type=AgentGroup" 2>/dev/null \
	| jq '.object.role_permissions|map(select(.action=="Read"))|[.[]|.resource_id]'`
	Role_AgentGroupId_Json=`echo "$Role_AgentGroupId_Json" | jq --argjson v "{\"role\":\"${role_array[$x]}\",\"agentgroup_ids\":$role_agentgroup}" '.data['$x'] += $v'`
done
###获取角色所拥有的agent分组ID，组合为JSON数据，样例:{"data":[{"role":"角色1",agentgroup_ids:[]},{"role":"角色2",agentgroup_ids:[11,32]}]}
###提供给每个agent分组遍历这个JSON数据中的每个角色授权的agent分组ID是否匹配，匹配则赋予给对应角色的列表变量值
for (( i=0; i<${#agentgroup_array[@]}; i++ ));do
	ag_id=`echo "$agentgroup_json" | jq -rc ".|map(select(.name=="\"${agentgroup_array[$i]}\""))|.[].id"`
	match_roles=(__user_admin__)
	for (( y=0;y<${#role_array[@]}; y++ ));do
		return_ag_id=`echo "$Role_AgentGroupId_Json" | jq ".data|map(select(.role==\"${role_array[$y]}\"))|.[].agentgroup_ids|.[]" | grep -w "$ag_id"`
		if [[ -n "$return_ag_id" ]] ;then
			match_roles[${#match_roles[@]}]=${role_array[$y]}
		fi
	done
	agentgroup=`echo "$agentgroup_json" | jq -rc "[.[$i]]"`
	memo=`echo "$agentgroup" | jq -rc ".[].memo"`
	rt_len=`echo "$agentgroup" | jq ".[].rt_list|length"`
	if [[ $rt_len == "1" ]];then
		orgtag=`echo "$agentgroup" | jq -rc ".[].rt_list[].name"`
	else
		orgtag=""
	fi
	echo "${agentgroup_array[$i]}","$memo","$orgtag","${match_roles[@]}" >> ./${filename}_${download_time}.csv 
	unset match_roles
	start=`expr $i + 1`
        progress_bar $start ${#agentgroup_array[@]}	
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

upgrading_agent_download() {              #导出启动状态一直停留在正在升级中的agent
download_time=`date '+%Y%m%d%H%M'`
filename="导出升级中的Agent清单"
echo "Agent-id,IP,端口,主机名,操作系统,平台,当前版本,预期版本,启动状态,Agent分组,资源标签" >> ./${filename}_${download_time}.csv
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name,rt_list:.rt_list}]'`
default_agent_group_id=`echo "$agentgroup_json" | jq ".|map(select(.name=="\"__default_agent_group__\""))|.[].id" | sed 's/\"//g'`
agent_id_group_ids_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&sort=-id" 2>/dev/null \
| jq "[.objects|map(select(.cur_version!=.expected_version and .expected_version!=null and .expected_version!=\"\"))|.[]|{id:.id,group_ids:.group_ids}]" | jq -rc .)
agent_id_array=$(echo "$agent_id_group_ids_json" | jq -rc '[.[]|.id]' | sed 's/^\[//g;s/\]$//g;s/,/ /g')
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
	groups_ids_array=`echo "$agent_id_group_ids_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].group_ids" | tr ',' ' '`
	groups_ids_array=(${groups_ids_array[@]/$default_agent_group_id})
	if [[ -n "$groups_ids_array" ]];then
	for group_id in ${groups_ids_array[@]};do
                group_name=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].name" | sed 's/\"//g'`
		groups_name[${#groups_name[@]}]=${group_name}
		group_array=`echo \"${groups_name[@]}\" | sed 's/\s/,/g'`
		resource_tag=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].rt_list[].name" | sed 's/\"//g'`
		resource_tags[${#resource_tags[@]}]=${resource_tag}
		resource_tags_array=`echo \"${resource_tags[@]}\" | sed 's/\s/,/g'`
	done
	else 
		group_array="\"__default_agent_group__\""
	fi
	unset groups_ids_array groups_name resource_tags
	agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
	| jq -rc "[.object|.id,.ip,.port,.hostname,.os,.platform,.cur_version,.expected_version,.status]" | sed -e 's/^\[//g' -e 's/\]$//g'`
	echo "$agent_info","$group_array","$resource_tags_array" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

parserrule_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出字段提取清单"
echo "字段提取ID,名称,Logtype,是否启用,创建者,最近修改时间,已关联日志,正则解析,时间戳识别,json解析,CSV解析,字段重命名,数值型字段转换,KeyValue分解,\
geo解析,内容替换,删除字段,自定义字典,格式化处理,syslog_pri解析,metadata自定义解析,script自定义解析,dissect自定义解析" >> ./${filename}_${download_time}.csv
parserrule_id=`$request -H "$auth" "${url}${api}/parserrules/?&size=1000&sort=-id" 2>/dev/null | jq -rc '[.objects[]|.id]' | sed 's/,/ /g;s/\]$//g;s/^\[//g'`
parserrule_id=(${parserrule_id[@]})

for (( i=0; i<${#parserrule_id[@]}; i++ ));do
        parser_info=`$request -H "$auth" "${url}${api}/parserrules/${parserrule_id[$i]}/" 2>/dev/null \
        | jq -rc '.object|[.id,.name,.logtype,.enable,.creator_name,.last_modified_time]' | sed -e 's/^\[//g' -e 's/\]$//g'`
        data_source=`$request -H "$auth" "${url}${api}/parserrules/?&size=1000&sort=-id" 2>/dev/null \
        | jq -rc ".objects|map(select(.id==${parserrule_id[$i]}))|.[].data_source" | sed 's/,/ /g'`
        conf_json=`$request -H "$auth" "${url}${api}/parserrules/${parserrule_id[$i]}/" 2>/dev/null | jq -rc '.object.conf'`
        conf_len=`echo "$conf_json" | jq '.|length'`
        for (( x=0; x<$conf_len; x++ ));do
                if [[ $(echo "$conf_json" | jq ".[$x].grok") != null ]];then      #正则解析
                        grok=`echo "$conf_json" | jq -rc '[.[].grok]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].json") != null ]];then     #json解析
                        json=`echo "$conf_json" | jq -rc '[.[].json]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].date") != null ]];then    #时间戳识别
                        date=`echo "$conf_json" | jq -rc '[.[].date]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].split") != null ]];then   #CSV解析
                        split=`echo "$conf_json" | jq -rc '[.[].split]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].rename") != null ]];then  #字段重命名
                        rename=`echo "$conf_json" | jq -rc '[.[].rename]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].numeric") != null ]];then #数值型字段转换
                        numeric=`echo "$conf_json" | jq -rc '[.[].numeric]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].kv") != null ]];then      #KeyValue分解
                        kv=`echo "$conf_json" | jq -rc '[.[].kv]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].geo") != null ]];then     #geo解析
                        geo=`echo "$conf_json" | jq -rc '[.[].geo]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].replacer") != null ]];then     #内容替换
                        replacer=`echo "$conf_json" | jq -rc '[.[].replacer]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].remove") != null ]];then     #删除字段
                        remove=`echo "$conf_json" | jq -rc '[.[].remove]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].dict") != null ]];then     #自定义字典
                        dict=`echo "$conf_json" | jq -rc '[.[].dict]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].format") != null ]];then     #格式化处理
                        format=`echo "$conf_json" | jq -rc '[.[].format]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].metadata") != null ]];then        #自定义解析
                        metadata=`echo "$conf_json" | jq -rc '[.[].metadata]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].dissect") != null ]];then        #自定义解析
                        disset=`echo "$conf_json" | jq -rc '[.[].disset]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].script") != null ]];then     #自定义解析
                        script=`echo "$conf_json" | jq -rc '[.[].script]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                elif [[ $(echo "$conf_json" | jq ".[$x].syslog_priority") != null ]];then        #syslog_pri解析
                        syslog_pri=`echo "$conf_json" | jq -rc '[.[].syslog_priority]' | sed 's/null,//g;s/,null//g;s/\<null\>//g;s/"/""/g;/^$/d'`
                else
                        echo "没有匹配到对应的解析规则."
                fi
        done
        echo "$parser_info","$data_source","\"$grok\"","\"$date\"","\"$json\"","\"$split\"","\"$rename\"","\"$numeric\"","\"$kv\"","\"$geo\"","\"$replacer\"",\
"\"$remove\"","\"$dict\"","\"$format\"","\"$syslog_pri\"","\"$metadata\"","\"$script\"","\"$disset\"" >> ./${filename}_${download_time}.csv
        unset parser_info data_source date grok json split rename numeric kv geo replacer remove dict format syslog_pri metadata script dissect
        start=`expr $i + 1`
        progress_bar $start ${#parserrule_id[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}


agent_logstream_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出全量Agent文件采集清单"
echo "Agent-Id,Agent-IP,端口,启动状态,操作系统,平台,版本,Agent分组,资源标签,采集类型,source,采集是否禁用,appname,tag,路径,文件路径白名单,文件路径黑名单,换行正则,最后修改时间,字符集编码,日志内容白名单,日志内容黑名单,时间戳格式,时区,分流字段,排序字段" >> ./${filename}_${download_time}.csv
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null \
| jq -rc '[.objects[]|{id:.id,name:.name,rt_list:.rt_list}]'`
default_agent_group_id=`echo "$agentgroup_json" | jq ".|map(select(.name=="\"__default_agent_group__\""))|.[].id" | sed 's/\"//g'`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_info_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
	agent_ip_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].ip,.[].port" | sed '/\r$/d' | tr '\n' ':' | sed 's/:$//g'`
        proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_ip"`
	proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_port"`
	groups_ids_array=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].group_ids" | tr ',' ' '`
        groups_ids_array=(${groups_ids_array[@]/$default_agent_group_id})
        if [[ -n "$groups_ids_array" ]];then
        for group_id in ${groups_ids_array[@]};do
                group_name=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].name" | sed 's/\"//g'`
                groups_name[${#groups_name[@]}]=${group_name}
                group_array=`echo \"${groups_name[@]}\" | sed 's/\s/,/g'`
                resource_tag=`echo "$agentgroup_json" | jq ".|map(select(.id==$group_id))|.[].rt_list[].name" | sed 's/\"//g'`
                if [[ x$resource_tag != x ]];then
			resource_tags[${#resource_tags[@]}]=${resource_tag}
                	resource_tags_array=`echo \"${resource_tags[@]}\" | sed 's/\s/,/g'`
		fi
        done
        else
                group_array="\"__default_agent_group__\""
        fi
	unset groups_ids_array groups_name resource_tags
	agent_last_update_timestamp=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null | jq -rc ".object.last_update_timestamp"`
	agent_last_update_timestamp=`date -d "$agent_last_update_timestamp" +%s`
	health_time_lag=`expr $(date +%s) - $agent_last_update_timestamp`	
	if [[ $health_time_lag -lt 900 ]];then
		agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
		| jq -rc "[.object|.id,.ip,.port,.status,.os,.platform,.cur_version]" | sed -e 's/^\[//g' -e 's/\]$//g'`
	if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
	    agent_logstream_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&type=LogstreamerInput" 2>/dev/null`
	else
	    agent_logstream_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&proxy=$proxy_ip:$proxy_port&type=LogstreamerInput" 2>/dev/null`
	fi
	agent_logstream_count=`echo "$agent_logstream_json" | jq '.objects|length'`
	agent_logstream_result=`echo "$agent_logstream_json" | jq '.result'`
	if [[ $agent_logstream_count != 0 ]] && [[ $agent_logstream_result != false ]];then
		for (( x=0; x<$agent_logstream_count; x++ ));do
		    logstream_info=`echo "$agent_logstream_json" | jq -rc \
		    ".objects[$x]|[.type,.source,.disabled,.appname,.tag,.log_directory,.file_match,.exclude,.splitter_regex,.oldest_duration,.charset,.include_line,.exclude_line]" \
		    | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
		    time_format=`echo "$agent_logstream_json" | jq -rc ".objects[$x]|.timestamp_configs[0].time_format"`
                    timezone=`echo "$agent_logstream_json" | jq -rc ".objects[$x]|.timestamp_configs[0].timezone"`
		    differentiator=`echo "$agent_logstream_json" | jq -rc ".objects[$x]|.differentiator" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"//g'`
		    priority=`echo "$agent_logstream_json" | jq -rc ".objects[$x]|.priority" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/"//g'`
		    echo "$agent_info","$group_array","$resource_tags_array","$logstream_info","\"$time_format\"","\"$timezone\"","\"$differentiator\"","\"$priority\"" >> ./${filename}_${download_time}.csv
	    	done
	else
		echo "$agent_info","$group_array","$resource_tags_array" >> ./${filename}_${download_time}.csv
	fi
	fi
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_processinput_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出Agent脚本数据采集清单"
echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag,可执行文件,执行参数,换行规则,间隔时间(秒),crontab,字符集编码" >> ./${filename}_${download_time}.csv
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_info_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
        agent_ip_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].ip,.[].port" | sed '/\r$/d' | tr '\n' ':' | sed 's/:$//g'`
        proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_ip"`
        proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_port"`
        agent_last_update_timestamp=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null | jq -rc ".object.last_update_timestamp"`
        agent_last_update_timestamp=`date -d "$agent_last_update_timestamp" +%s`
        health_time_lag=`expr $(date +%s) - $agent_last_update_timestamp`
        if [[ $health_time_lag -lt 900 ]];then
        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
            agent_processinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&type=ProcessInput" 2>/dev/null`
        else
            agent_processinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&proxy=$proxy_ip:$proxy_port&type=ProcessInput" 2>/dev/null`
        fi
        agent_processinput_count=`echo "$agent_processinput_json" | jq '.objects|length'`
        agent_processinput_result=`echo "$agent_processinput_json" | jq '.result'`
        if [[ $agent_processinput_count != 0 ]] && [[ $agent_processinput_result != false ]];then
                for (( x=0; x<$agent_processinput_count; x++ ));do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
                        | jq -rc "[.object|.ip,.port]" | sed -e 's/^\[//g' -e 's/\]$//g'`
                        process_info=`echo "$agent_processinput_json" | jq -rc \
                        ".objects[$x]|[.type,.source,.disabled,.appname,.tag]" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        bin=`echo "$agent_processinput_json" | jq -rc ".objects[$x]|.bin"`
			args=`echo "$agent_processinput_json" | jq -rc ".objects[$x]|.args|.[]" | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
			process_info2=`echo "$agent_processinput_json" | jq -rc ".objects[$x]|[.splitter_regex,.ticker_interval,.interval,.charset]" \
			| sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        echo "$agent_info","$process_info","$bin","$args","$process_info2" >> ./${filename}_${download_time}.csv
		done
	fi
	fi
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_topinput_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出Agent性能数据采集清单"
echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag" >> ./${filename}_${download_time}.csv
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_info_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
        agent_ip_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].ip,.[].port" | sed '/\r$/d' | tr '\n' ':' | sed 's/:$//g'`
        proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_ip"`
        proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_port"`
        agent_last_update_timestamp=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null | jq -rc ".object.last_update_timestamp"`
        agent_last_update_timestamp=`date -d "$agent_last_update_timestamp" +%s`
        health_time_lag=`expr $(date +%s) - $agent_last_update_timestamp`
        if [[ $health_time_lag -lt 900 ]];then
        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
            agent_topinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&type=TopInput" 2>/dev/null`
        else
            agent_topinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&proxy=$proxy_ip:$proxy_port&type=TopInput" 2>/dev/null`
        fi
        agent_topinput_count=`echo "$agent_topinput_json" | jq '.objects|length'`
        agent_topinput_result=`echo "$agent_topinput_json" | jq '.result'`
        if [[ $agent_topinput_count != 0 ]] && [[ $agent_topinput_result != false ]];then
                for (( x=0; x<$agent_topinput_count; x++ ));do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
                        | jq -rc "[.object|.ip,.port]" | sed -e 's/^\[//g' -e 's/\]$//g'`
                        topinput_info=`echo "$agent_topinput_json" | jq -rc \
                        ".objects[$x]|[.type,.source,.disabled,.appname,.tag]" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        echo "$agent_info","$topinput_info" >> ./${filename}_${download_time}.csv
                done
        fi
        fi
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_topinput_delete() {               #清理导出的agent性能数据采集配置
source_columns=`awk -F',' 'END{print NF}' $source`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')

if [[ $source_columns == 7 ]];then
        sed -e 1d $source | shuf | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ip port type source_id disabled appname tag;do
                ip=`echo "$ip" | sed 's/^\"//g;s/\"$//g'`
                proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==\"$ip\" and .port==$port))|.[].proxy_ip"`
                proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==\"$ip\" and .port==$port))|.[].proxy_port"`
                if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                        return=`$request -H "$auth" -X DELETE \
                        "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=&type=TopInput&source=TopInput" 2>/dev/null`
                else
                        return=`$request -H "$auth" -X DELETE \
                        "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=$proxy_ip:$proxy_port&type=TopInput&source=TopInput" 2>/dev/null`
                fi
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo "Agent $ip:$port TopInput $source_id is deleted."
                else
                        echo "Agent $ip:$port TopInput $source_id delete failure,error message: $(echo "$return" | jq -rc .error.message)"
                fi
        done
else
        echo "待删除的Agent日志采集配置CSV文件不是7个字段,请检查是否存在含有逗号的字段列."
fi
}

agent_dbinput_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出Agent数据库数据采集清单"
echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag,采集方式,数据库连接名,采集频率,SQL语句,增量字段,增量操作符,每轮采集记录条数" >> ./${filename}_${download_time}.csv
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_info_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
agent_id_array=(${agent_id_array[@]})
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
        agent_ip_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].ip,.[].port" | sed '/\r$/d' | tr '\n' ':' | sed 's/:$//g'`
        proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_ip"`
        proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_port"`
        agent_last_update_timestamp=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null | jq -rc ".object.last_update_timestamp"`
        agent_last_update_timestamp=`date -d "$agent_last_update_timestamp" +%s`
        health_time_lag=`expr $(date +%s) - $agent_last_update_timestamp`
        if [[ $health_time_lag -lt 900 ]];then
        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
            agent_dbinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&type=DBInput" 2>/dev/null`
        else
            agent_dbinput_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&proxy=$proxy_ip:$proxy_port&type=DBInput" 2>/dev/null`
        fi
        agent_dbinput_count=`echo "$agent_dbinput_json" | jq '.objects|length'`
        agent_dbinput_result=`echo "$agent_dbinput_json" | jq '.result'`
        if [[ $agent_dbinput_count != 0 ]] && [[ $agent_dbinput_result != false ]];then
                for (( x=0; x<$agent_dbinput_count; x++ ));do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
                        | jq -rc "[.object|.ip,.port]" | sed -e 's/^\[//g' -e 's/\]$//g'`
			dbinput_mode=`echo "$agent_dbinput_json" | jq -rc ".objects[$x]|.order_by_field"`
			if [[ $dbinput_mode == "null"  ]];then
				access_mode="全量采集"
                        	dbinput_info=`echo "$agent_dbinput_json" | jq -rc \
                        	".objects[$x]|[.type,.source,.disabled,.appname,.tag]" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
				dbinput_info2=`echo "$agent_dbinput_json" | jq -rc ".objects[$x]|[.connection_name,.cron,.sql_stmt]" \
				| sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        	echo "$agent_info","$dbinput_info",$access_mode,"$dbinput_info2" >> ./${filename}_${download_time}.csv	
			else
				access_mode="增量采集"	
				dbinput_info=`echo "$agent_dbinput_json" | jq -rc \
                        	".objects[$x]|[.type,.source,.disabled,.appname,.tag]" | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        	dbinput_info2=`echo "$agent_dbinput_json" | jq -rc ".objects[$x]|[.connection_name,.cron,.sql_stmt,.order_by_field,.operator,.fetch_rows]" \
                        	| sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
                        	echo "$agent_info","$dbinput_info",$access_mode,"$dbinput_info2" >> ./${filename}_${download_time}.csv 
			fi
		done
	fi
	fi
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_logstream_filter_download() {             #指定appname/tag导出日志采集配置CSV文件清单
download_time=`date '+%Y%m%d%H%M'`
filename="导出Agent文件采集清单"
echo "Agent-IP,Agent端口,采集类型,source,采集是否禁用,appname,tag,路径,文件路径白名单,文件路径黑名单,换行正则,最后修改时间,字符集编码,日志内容白名单,日志内容黑名单,时间戳格式,时区,分流字段,排序字段" >> ./${filename}_${download_time}.csv
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')
agent_id_array=$(echo "$agent_info_json" | jq -rc '.[]|.id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
agent_id_array=(${agent_id_array[@]})
filter_condition=`echo "$appname_tag" | sed -e 's/\"//g;s/,/ /g'`
filter_condition=(${filter_condition[@]})
for (( i=0; i<${#filter_condition[@]}; i++ ));do
        appname_match=`echo "${filter_condition[$i]}" |  grep -Eo '/'`
        if [[ $appname_match == "/" ]];then
                appname=`echo -n "${filter_condition[$i]}" | cut -d / -f 1`
                tag=`echo -n "${filter_condition[$i]}" | cut -d / -f 2`
        else
                appname=`echo -n "${filter_condition[$i]}"`
                tag="*"
        fi
        appnames[${#appnames[@]}]=$appname
        tags[${#tags[@]}]=$tag
done
unset appname tag
for (( i=0; i<${#agent_id_array[@]}; i++ ));do
        agent_ip_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].ip,.[].port" | sed '/\r$/d' | tr '\n' ':' | sed 's/:$//g'`
        proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_ip"`
        proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.id==${agent_id_array[$i]}))|.[].proxy_port"`
        agent_last_update_timestamp=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null | jq -rc ".object.last_update_timestamp"`
        agent_last_update_timestamp=`date -d "$agent_last_update_timestamp" +%s`
        health_time_lag=`expr $(date +%s) - $agent_last_update_timestamp`
        if [[ $health_time_lag -lt 900 ]];then        
	if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
            agent_logstream_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&type=LogstreamerInput" 2>/dev/null`
        else
            agent_logstream_json=`$request -H "$auth" "${url}${api}/agent/config/?ip_port=$agent_ip_port&proxy=$proxy_ip:$proxy_port&type=LogstreamerInput" 2>/dev/null`
        fi
        agent_logstream_count=`echo "$agent_logstream_json" | jq '.objects|length'`
	agent_logstream_result=`echo "$agent_logstream_json" | jq '.result'`
        if [[ $agent_logstream_count != 0 ]] && [[ $agent_logstream_result != false ]];then
        	appname_match_cnt=`echo "$agent_logstream_json" | jq '.objects[].appname' | grep -Ewo "($(echo "${appnames[@]}" | sed 's/ /|/g'))" | wc -l`
	if [[ $appname_match_cnt != 0 ]];then
                agent_tag_json=`echo "$agent_logstream_json" | jq -rc "[.objects[]|{appname:.appname,tag:.tag}]"`
                for (( x=0; x<$agent_logstream_count; x++ ));do
                        logstream_array_id=$x
                        appname=`echo "$agent_tag_json"| jq -rc ".[$x]|.appname"`
                        tag=`echo "$agent_tag_json"| jq -rc ".[$x]|.tag"`
                        for (( app_id=0,tag_id=0; app_id<${#appnames[@]} && tag_id<${#tags[@]}; app_id++,tag_id++ ));do
                                if [[ "${tags[$tag_id]}" != "*" ]];then
                                        if [[ $appname == "${appnames[$app_id]}" && $tag == "${tags[$tag_id]}" ]];then
                                                logstream_array[${#logstream_array[@]}]=$logstream_array_id
                                        fi
                                elif [[ "${tags[$tag_id]}" == "*" ]];then
                                        if [[ $appname == "${appnames[$app_id]}" ]];then
                                                logstream_array[${#logstream_array[@]}]=$logstream_array_id
                                        fi
                                fi
                        done
                        unset logstream_array_id
                done
                if [[ ${#logstream_array[@]} != 0 ]];then
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/" 2>/dev/null \
                        | jq -rc "[.object|.ip,.port]" | sed -e 's/^\[//g' -e 's/\]$//g'`
                        for y in ${logstream_array[@]};do
                                logstream_info=`echo "$agent_logstream_json" | jq -rc \
                                ".objects[$y]|[.type,.source,.disabled,.appname,.tag,.log_directory,.file_match,.exclude,.splitter_regex,.oldest_duration,.charset,.include_line,.exclude_line]" \
                                | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\\\\\\\\/\\\\/g'`
		    		time_format=`echo "$agent_logstream_json" | jq -rc ".objects[$y]|.timestamp_configs[0].time_format" | sed 's%ss,SSS%ss SSS%g'`
		    		timezone=`echo "$agent_logstream_json" | jq -rc ".objects[$y]|.timestamp_configs[0].timezone"`
                                differentiator=`echo "$agent_logstream_json" | jq -rc ".objects[$y]|.differentiator" | sed 's/^\[//g;s/\]$//g;s/"//g;s/,/ /g'`
                                priority=`echo "$agent_logstream_json" | jq -rc ".objects[$y]|.priority" | sed -e 's/^\[//g;s/\]$//g;s/"//g;s/,/ /g'`
                                echo "$agent_info","$logstream_info","\"$time_format\"","\"$timezone\"","\"$differentiator\"","\"$priority\"" >> ./${filename}_${download_time}.csv
                        done
                fi
                unset logstream_array
        fi
	fi
        fi
        start=`expr $i + 1`
        progress_bar $start ${#agent_id_array[@]}
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

agent_logstream_filter_delete() {               #从指定appname/tag导出的日志采集配置CSV文件清单中清理该日志采集配置
source_columns=`awk -F',' 'END{print NF}' $source`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')

if [[ $source_columns == 19 ]];then
        sed -e 1d $source | shuf | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ip port type source_id disabled appname tag log_directory \
        file_match exclude splitter_regex oldest_duration time_format charset differentiator priority;do
		ip=`echo "$ip" | sed 's/^\"//g;s/\"$//g'`
		source_id=`echo "$source_id" | sed 's/^\"//g;s/\"$//g'`
                proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==\"$ip\" and .port==$port))|.[].proxy_ip"`
                proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==\"$ip\" and .port==$port))|.[].proxy_port"`
                if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                        return=`$request -H "$auth" -X DELETE \
                        "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=&type=LogstreamerInput&source=$source_id" 2>/dev/null`
                else
                        return=`$request -H "$auth" -X DELETE \
                        "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=$proxy_ip:$proxy_port&type=LogstreamerInput&source=$source_id" 2>/dev/null`
                fi
                if [[ $(echo "$return" | jq .result) == "true" ]];then
                        echo "Agent $ip:$port LogstreamerInput $source_id is deleted."
                else
                        echo "Agent $ip:$port LogstreamerInput $source_id delete failure,error message: $(echo "$return" | jq -rc .error.message)"
                fi
        done
else
        echo "待删除的Agent日志采集配置CSV文件不是19个字段,请检查是否存在含有逗号的字段列."
fi
}

agent_logstream_filter_renew() {                #从指定appname/tag导出的日志采集配置CSV文件清单中更新该日志采集配置
source_columns=`awk -F',' 'END{print NF}' $source`
agent_info_json=$($request -H "$auth" "${url}${api}/agent/?group_ids=all&size=10000&fields=id,ip,port,proxy_ip,proxy_port&sort=-id" 2>/dev/null | jq -rc '.objects')

if [[ $source_columns == 19 ]];then
        sed -e 1d $source | shuf | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ip port type source_id disabled appname tag log_directory \
        file_match exclude splitter_regex oldest_duration charset include_line exclude_line time_format timezone differentiator priority;do
                proxy_ip=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==$ip and .port==$port))|.[].proxy_ip"`
                proxy_port=`echo "$agent_info_json" | jq -rc ".|map(select(.ip==$ip and .port==$port))|.[].proxy_port"`
		log_directory=`echo "$log_directory" | sed 's/\\\\/\\\\\\\\/g'`
                file_match=`echo "$file_match" | sed 's/\\\\/\\\\\\\\/g'`
                tag=`echo "$tag" | sed 's/ /,/g'`
		ip=`echo "$ip" | sed 's/"//g'`	
		source_id=`echo "$source_id" | sed 's/"//g'`
                time_format=`echo "$time_format" | sed "s#ss SSS#ss,SSS#"`
                splitter_regex=`echo "$splitter_regex" | sed 's/\\\\/\\\\\\\\/g'`
                if [[ $exclude == "null" ]];then exclude=\"\";fi
                if [[ $include_line == "null" ]];then include_line=\"\";fi
                if [[ $exclude_line == "null" ]];then exclude_line=\"\";fi
                if [[ $time_format == '"null"' ]];then time_format=\"\";fi
                if [[ $timezone == '"null"' ]];then timezone=\"\";fi
                if [[ $differentiator == \"null\" ]];then differentiator="[]";else differentiator=$(echo "$differentiator" | sed 's/^/[/g;s/$/]/g;s/ /","/g');fi
                if [[ $priority == \"null\" ]];then priority="[]";else priority=$(echo "$priority" | sed 's/^/[/g;s/$/]/g;s/ /","/g');fi
		if [[ x$time_format != x\"\" ]];then
		request_json=`jq -Mnr --argjson v "{\"appname\":$appname,\"tag\":$tag,\"disabled\":${disabled,,},\"type\":$type,\"log_directory\":$log_directory,\"file_match\":$file_match,\"exclude\":$exclude,\
                \"splitter_regex\":$splitter_regex,\"oldest_duration\":$oldest_duration,\"timestamp_configs\":[{\"locale\":\"en\",\
                \"max_timestamp_lookahead\":128,\"time_prefix\":\"\",\"timezone\":$timezone,\"time_format\":$time_format}],\
                \"charset\":$charset,\"include_line\":$include_line,\"exclude_line\":$exclude_line,\"differentiator\":$differentiator,\"priority\":$priority}" '$v'`
                else
                request_json=`jq -Mnr --argjson v "{\"appname\":$appname,\"tag\":$tag,\"disabled\":${disabled,,},\"type\":$type,\"log_directory\":$log_directory,\"file_match\":$file_match,\"exclude\":$exclude,\
                \"splitter_regex\":$splitter_regex,\"oldest_duration\":$oldest_duration,\"timestamp_configs\":[],\
                \"charset\":$charset,\"include_line\":$include_line,\"exclude_line\":$exclude_line,\"differentiator\":$differentiator,\"priority\":$priority}" '$v'`
		fi
		if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                return=`$request -H "$auth" -H "$header" -X PUT -d "$request_json" \
                "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=&type=LogstreamerInput&source=$source_id" 2>/dev/null`
                else
                return=`$request -H "$auth" -H "$header" -X PUT -d "$request_json" \
                "${url}${api}/agent/config/?ip_port=$ip:$port&proxy=$proxy_ip:$proxy_port&type=LogstreamerInput&source=$source_id" 2>/dev/null`
                fi
                if [[ $(echo "$return" | jq -rc .result) == "true" ]];then
                        echo "$ip:$port appname:$appname tag:$tag `echo "$log_directory/$file_match" | sed 's/\"//g;s/\\\\\\\\/\\\\/g;s%//%/%g'` LogstreamerInput renew success."
                        echo "+--------------------------------------------------------------------------------------------------------------+"

                else
                        echo "$ip:$port appname:$appname tag:$tag `echo "$log_directory/$file_match" | sed 's/\"//g;s/\\\\\\\\/\\\\/g;s%//%/%g'` LogstreamerInput renew failure,error message: $(echo "$return" | jq -rc .error.message)"
                        echo "+--------------------------------------------------------------------------------------------------------------+"

                fi
        done
else
        echo "待更新的Agent日志采集配置CSV文件不是19个字段,请检查是否存在含有逗号的字段列."
fi
}

agent_manage() {                #指定agent分组对组内agent执行启动、停止、重启、升级操作
local agent_method=$1
agentgroup_array=`echo "$agent_group" | sed -e 's/\"//g;s/,/ /g'`
agentgroup_json=`$request -H "$auth" "${url}${api}/agentgroup/?&size=1000&fields=id,name" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]'`
for agentgroup in ${agentgroup_array[@]};do
        agentgroup_check=`echo "$agentgroup_json" | jq -rc ".|map(select(.name==\"$agentgroup\"))|length"`
        if [[ $agentgroup_check == 0 ]];then
                echo "Agent分组【$agentgroup】不存在,已忽略."
                agentgroup_array=(${agentgroup_array[@]/$agentgroup})
        fi
done
case "${agent_method}" in
        start)
        for agentgroup in ${agentgroup_array[@]};do
                agent_id_array=`$request -H "$auth" "${url}${api}/agentgroup/assign/" 2>/dev/null | \
                jq -rc '[.objects[]|{id:.id,name:.name,resource_ids:.resource_ids[]}]' \
                | jq -rc "[.|map(select(.name==\"$agentgroup\"))|.[].resource_ids]" | sed 's/\[//g;s/\]//g;s/,/ /g'`
                agent_id_array=(${agent_id_array[@]})
                if [[ ${#agent_id_array[@]} != 0 ]];then
                for i in ${!agent_id_array[@]};do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/?group_ids=all&fields=ip,port,platform,proxy_ip,proxy_port" 2>/dev/null | jq -rc '.object'`
                        ip_port=$(echo "$agent_info" | jq -rc '.|[.ip,.port]' | sed 's/^\[//g;s/\]$//g;s/"//g;s/,/:/g')
		        proxy_ip=$(echo "$agent_info" | jq -rc '.|.proxy_ip')
		        proxy_port=$(echo "$agent_info" | jq -rc '.|.proxy_port')
                        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=&cmd=start" 2>/dev/null)
                        else
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=$proxy_ip:$proxy_port&cmd=start" 2>/dev/null)
                        fi
                        return_stats=$(echo "$return_json" | jq -rc .result)
                        start=`expr $i + 1`
                        if [[ $return_stats == "true" ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】已启动."
                        else
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】启动失败,错误信息:$(echo "$return_json" | jq -rc .error.message)"
                        fi
                        progress_bar $start ${#agent_id_array[@]}
                done
                agent_id_array=()
                printf '\nFinished!\n'
                else
                        echo -e "Agent分组【$agentgroup】为空."
                fi
        done
        ;;
        stop)
        for agentgroup in ${agentgroup_array[@]};do
                agent_id_array=`$request -H "$auth" "${url}${api}/agentgroup/assign/" 2>/dev/null | \
                jq -rc '[.objects[]|{id:.id,name:.name,resource_ids:.resource_ids[]}]' \
                | jq -rc "[.|map(select(.name==\"$agentgroup\"))|.[].resource_ids]" | sed 's/\[//g;s/\]//g;s/,/ /g'`
                agent_id_array=(${agent_id_array[@]})
                if [[ ${#agent_id_array[@]} != 0 ]];then
                for i in ${!agent_id_array[@]};do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/?group_ids=all&fields=ip,port,platform,proxy_ip,proxy_port" 2>/dev/null | jq -rc '.object'`
                        ip_port=$(echo "$agent_info" | jq -rc '.|[.ip,.port]' | sed 's/^\[//g;s/\]$//g;s/"//g;s/,/:/g')
		        proxy_ip=$(echo "$agent_info" | jq -rc '.|.proxy_ip')
		        proxy_port=$(echo "$agent_info" | jq -rc '.|.proxy_port')
                        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=&cmd=stop" 2>/dev/null)
                        else
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=$proxy_ip:$proxy_port&cmd=stop" 2>/dev/null)
                        fi
                        return_stats=$(echo "$return_json" | jq -rc .result)
                        start=`expr $i + 1`
                        if [[ $return_stats == "true" ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】已停止."
                        else
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】停止失败,错误信息:$(echo "$return_json" | jq -rc .error.message)"
                        fi
                        progress_bar $start ${#agent_id_array[@]}
                done
                agent_id_array=()
                printf '\nFinished!\n'
                else
                        echo -e "Agent分组【$agentgroup】为空."
                fi
        done
        ;;
        restart)
        for agentgroup in ${agentgroup_array[@]};do
                agent_id_array=`$request -H "$auth" "${url}${api}/agentgroup/assign/" 2>/dev/null | \
                jq -rc '[.objects[]|{id:.id,name:.name,resource_ids:.resource_ids[]}]' \
                | jq -rc "[.|map(select(.name==\"$agentgroup\"))|.[].resource_ids]" | sed 's/\[//g;s/\]//g;s/,/ /g'`
                agent_id_array=(${agent_id_array[@]})
                if [[ ${#agent_id_array[@]} != 0 ]];then
                for i in ${!agent_id_array[@]};do
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/?group_ids=all&fields=ip,port,platform,proxy_ip,proxy_port" 2>/dev/null | jq -rc '.object'`
                        ip_port=$(echo "$agent_info" | jq -rc '.|[.ip,.port]' | sed 's/^\[//g;s/\]$//g;s/"//g;s/,/:/g')
		        proxy_ip=$(echo "$agent_info" | jq -rc '.|.proxy_ip')
		        proxy_port=$(echo "$agent_info" | jq -rc '.|.proxy_port')
                        if [[ x$proxy_ip == x ]] || [[ x$proxy_ip == x"null" ]];then
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=&cmd=restart" 2>/dev/null)
                        else
                                return_json=$($request -H "$header" -H "$auth" -X POST -d "{}" \
                                "${url}${api}/agent/status/?ip_port=$ip_port&proxy=$proxy_ip:$proxy_port&cmd=restart" 2>/dev/null)
                        fi
                        return_stats=$(echo "$return_json" | jq -rc .result)
                        start=`expr $i + 1`
                        if [[ $return_stats == "true" ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】已重启."
                        else
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】重启失败,错误信息:$(echo "$return_json" | jq -rc .error.message)"
                        fi
                        progress_bar $start ${#agent_id_array[@]}
                done
                agent_id_array=()
                printf '\nFinished!\n'
                else
                        echo -e "Agent分组【$agentgroup】为空."
                fi
        done
        ;;
        upgrade)
        for agentgroup in ${agentgroup_array[@]};do
                agent_id_array=`$request -H "$auth" "${url}${api}/agentgroup/assign/" 2>/dev/null | \
                jq -rc '[.objects[]|{id:.id,name:.name,resource_ids:.resource_ids[]}]' \
                | jq -rc "[.|map(select(.name==\"$agentgroup\"))|.[].resource_ids]" | sed 's/\[//g;s/\]//g;s/,/ /g'`
                agent_id_array=(${agent_id_array[@]})
                agentpackage_info=`$request -H "$auth" "${url}${api}/agentpackage/" 2>/dev/null | jq -rc '[.objects|.[]|{version:.version,platform:.platform}]'`
                if [[ ${#agent_id_array[@]} != 0 ]];then
                cur_unixtime=`date '+%s'`
                for i in ${!agent_id_array[@]};do
                        start=`expr $i + 1`
                        agent_info=`$request -H "$auth" "${url}${api}/agent/${agent_id_array[$i]}/?group_ids=all&fields=ip,port,platform,cur_version,last_update_timestamp" 2>/dev/null | jq -rc '.object'`
                        ip_port=$(echo "$agent_info" | jq -rc '.|[.ip,.port]' | sed 's/^\[//g;s/\]$//g;s/"//g;s/,/:/g')
                        platform=`echo "$agent_info" | jq -rc '.|.platform'`
                        last_update_timestamp=`echo "$agent_info" | jq -rc '.|.last_update_timestamp'`
                        last_update_unixtime=`date -d "$last_update_timestamp" +%s`
                        cur_version=`echo "$agent_info" | jq -rc '.|.cur_version'`
                        expected_version=`echo "$agentpackage_info" | jq ".|map(select(.platform==\"$platform\"))" | jq -rc '.[-1].version'`
                        if [[ $(expr $cur_unixtime - $last_update_unixtime) -gt 900 ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】已过期."
                        elif [[ $expected_version != null && $cur_version == $expected_version ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】$expected_version-$platform已是可更新的最高版本."
                        elif [[ $expected_version == null ]];then
                                echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】$platform平台没有可更新的升级包，已忽略."
                        elif [[ $expected_version != null && $cur_version != $expected_version ]];then
                                request_data="{\"expected_version\":\"$expected_version\"}"
                                return_json=$($request -H "$header" -H "$auth" -X PUT -d "$request_data" \
                                "${url}${api}/agent/${agent_id_array[$i]}/?group_ids=all" 2>/dev/null)
                                return_stats=$(echo "$return_json" | jq -rc .result)
                                if [[ $return_stats == "true" ]];then
                                        echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】正在升级到$expected_version."
                                else
                                        echo -e "\nAgent分组【$agentgroup】的Agent_$start【$ip_port】升级提交失败,错误信息:$(echo "$return_json" | jq -rc .error.message)"
                                fi
                        fi
                        progress_bar $start ${#agent_id_array[@]}
                done
                agent_id_array=()
                printf '\nFinished!\n'
                else
                        echo -e "Agent分组【$agentgroup】为空."
                fi
        done
        ;;
        *)
                :
        ;;
esac
}

usergroup_download() {
download_time=`date '+%Y%m%d%H%M'`
filename="导出用户分组清单"
echo "用户分组ID,用户分组名称,角色" >> ./${filename}_${download_time}.csv
usergroups_len=`$request -H "$auth" "${url}${api}/usergroups/?fields=roles" 2>/dev/null | jq ".objects|length"`
for (( i=0; i<$usergroups_len; i++ ));do
	roles_array=`$request -H "$auth" "${url}${api}/usergroups/?fields=roles" 2>/dev/null \
        | jq -c "[.objects[$i].roles[].name]" | tr ',' ' ' | sed -e 's/\"//g' -e 's/^\[//g' -e 's/\]$//g'`
	roles_array=($roles_array)
	for (( n=0; n<${#roles_array[@]};n++ ));do
		role_name=`echo "${roles_array[$n]}" | grep -Evw '__group_default_.*__'`
		if [[ x$role_name != x ]];then
			roles_name[${#roles_name[@]}]=${role_name}
			role_names=`echo \"${roles_name[@]}\" | sed 's/\s/,/g'`
		fi
	done
	unset roles_array roles_name
	usergroups=`$request -H "$auth" "${url}${api}/usergroups/?fields=roles" 2>/dev/null|jq -c "[.objects[$i]|.id,.name]"\
	| sed -e 's/^\[//g' -e 's/\]$//g'`
	echo "$usergroups","$role_names" >> ./${filename}_${download_time}.csv
        start=`expr $i + 1`
        progress_bar $start $usergroups_len
done
printf '\nFinished!\n'
echo "file ${filename}_${download_time}.csv Export success"
}

app_download() {
resourcetags_json=`$request -H "$auth" "${url}${api}/resourcetags/" 2>/dev/null | jq -rc "[.objects[]|{id:.id,name:.name}]"`
resourcetags_len=`echo $resourcetags_json | jq '.|length'`
category_array=(DashBoardGroup ParserRule Alert Report SavedSchedule SavedSearch DataSet) 
#导出资源类型：仪表盘、字段提取、监控、报表、定时任务、已存搜索、数据集
for (( i=0;i<$resourcetags_len;i++ ));do
	resourcetags=`echo $resourcetags_json | jq -rc ".[$i]"`
	resourcetag_id=`echo "$resourcetags" | jq -rc .id`
	resourcetag_name=`echo "$resourcetags" | jq -rc .name | tr ',' ' '`
	resource_post_data="{\"name\":\"$resourcetag_name\",\"alert_type\":2,\"parserrule_type\":0,\"resources\":[]}"	    
### alert_type
# 0 完整导出
# 1 只导出插件名称，不导出插件 meta 信息
# 2 删除所有插件信息
### parserrule_type
# 0 完整导出
# 1 删除所有字典信息
	for r in ${!category_array[@]};do
	    resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
	    if [[ ${category_array[$r]} == "DashBoardGroup" ]];then	
		DashBoardGroup_ids=`$request -H "$auth" "${url}${api}/dashboards/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
		if [[ x$DashBoardGroup_ids != x ]];then
			DashBoardGroup_json="{\"category\":\"DashBoardGroup\",\"ids\":\"$DashBoardGroup_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$DashBoardGroup_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
	    	fi
	    elif [[ ${category_array[$r]} == "ParserRule" ]];then
		ParserRule_ids=`$request -H "$auth" "${url}${api}/parserrules/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
		if [[ x$ParserRule_ids != x ]];then
                        ParserRule_json="{\"category\":\"ParserRule\",\"ids\":\"$ParserRule_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$ParserRule_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
		fi
	    elif [[ ${category_array[$r]} == "Alert" ]];then
		Alert_ids=`$request -H "$auth" "${url}${api}/alerts/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
		if [[ x$Alert_ids != x ]];then
                        Alert_json="{\"category\":\"Alert\",\"ids\":\"$Alert_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$Alert_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
            	fi
	    elif [[ ${category_array[$r]} == "Report" ]];then
                Report_ids=`$request -H "$auth" "${url}${api}/reports/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
                if [[ x$Report_ids != x ]];then
                        Report_json="{\"category\":\"Report\",\"ids\":\"$Report_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$Report_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
            	fi
	    elif [[ ${category_array[$r]} == "SavedSchedule" ]];then
                SavedSchedule_ids=`$request -H "$auth" "${url}${api}/schedules/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
                if [[ x$SavedSchedule_ids != x ]];then
                        SavedSchedule_json="{\"category\":\"SavedSchedule\",\"ids\":\"$SavedSchedule_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$SavedSchedule_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
                fi
            elif [[ ${category_array[$r]} == "SavedSearch" ]];then
                SavedSearch_ids=`$request -H "$auth" "${url}${api}/savedsearches/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
                if [[ x$SavedSearch_ids != x ]];then
                        SavedSearch_json="{\"category\":\"SavedSearch\",\"ids\":\"$SavedSearch_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$SavedSearch_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
            	fi
	    elif [[ ${category_array[$r]} == "DataSet" ]];then
                DataSet_ids=`$request -H "$auth" "${url}${api}/dataset/?sort=id&fields=id,name&rt_ids=$resourcetag_id" 2>/dev/null | jq -rc "[.objects[].id]" | sed "s/\[//g;s/\]//g"`
                if [[ x$DataSet_ids != x ]];then
                        DataSet_json="{\"category\":\"DataSet\",\"ids\":\"$DataSet_ids\"}"
			resource_post_data=`echo "$resource_post_data" | jq --argjson v "$DataSet_json" '.resources['$resources_len'] += $v' | jq -rc .`
	    		resources_len=`echo "$resource_post_data" | jq -rc ".resources|length"`
	    	fi
	    fi
	done
	if [[ $resources_len != 0 ]];then
		resource_post_return=`$request -H "$header" -H "$auth" -H "Content-Encoding: gzip" -X POST -d "$resource_post_data" \
			"${url}${api}/resources/export/?traceid=&should_trace=false&parent_spanid=&spanid=&lang=zh_CN" 2>/dev/null`
		if [[ $(echo $resource_post_return | jq -rc .result) == "true" ]];then
			if [[ -x /opt/rizhiyi/parcels/mongodb/bin/mongofiles ]];then
        			mongofiles_bin="/opt/rizhiyi/parcels/mongodb/bin/mongofiles"
			elif [[ -x ./mongofiles ]];then
        			mongofiles_bin="./mongofiles"
			else
				echo "mongofiles二进制可执行文件不存在."
				exit 1
			fi
			#echo "app资源包${resourcetag_name}.tar已导出到MongoDB."
			app_download_return=`$mongofiles_bin -u "rizhiyi" -p "rizhiyi&2018" --authenticationDatabase=admin \
			--host $(echo $url | awk -F "//" '{print $2}'):27017 -d share --prefix 'resource_package' get "$resourcetag_name.tar" &>/dev/null`
			if [[ $? == 0 ]];then
				echo "app资源包已下载到当前目录:`pwd`/$resourcetag_name.tar"
				$mongofiles_bin -u "rizhiyi" -p "rizhiyi&2018" --authenticationDatabase=admin \
                               	--host $(echo $url | awk -F "//" '{print $2}'):27017 -d share --prefix 'resource_package' delete "$resourcetag_name.tar" &>/dev/null
			else
				echo "app资源包$resourcetag_name.tar下载失败."
			fi
		else
			echo "app资源包${resourcetag_name}.tar导出失败,错误信息: $(echo "$resource_post_return" | jq -rc .error.message)"
		fi
	else
		echo "资源标签$resourcetag_name无匹配的资源."
	fi
        start=`expr $i + 1`
        progress_bar $start $resourcetags_len
	if [[ $start == $resourcetags_len ]];then
		printf '\nFinished!\n'
	else
		printf '\n'
	fi
done
}

role_permission() {
#将各类资源的资源标签x与角色x同名或为org.x的资源添加到对应角色的资源权限，赋予读取和编辑的权限
#资源类型包括：dataset、alerts、reports、trends、queryscopes、schedules、parserrules、dashboards、savedsearches、dictionaries、queryscopes
#授权资源类型：DataSet、Alert、Report、Trend、QueryScope、SavedSchedule、ParserRule、DashBoardGroup、SavedSearch、Dictionary、QueryScope
roles_json=`$request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null | jq -rc "[.objects[]|{name:.name,id:.id}]"`
roles_array=$($request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null | jq -rc ".objects[].name" | tr ',' ' ' | sed -e 's/\"//g' \
| grep -Ev '(admin|General_User|general_user|__)' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g')
roles_array=(${roles_array[@]})
#permission_resource_type=`$request -H "$auth" "${url}${api}/permissions/meta/" 2>/dev/null | jq -rc "[.objects|map(select(.resource_type!=\"\"))|.[]|{id:.id,action:.action,resource_type:.resource_type}]" \
#| jq -rc '.[].resource_type' | uniq | grep -Evw \
#'(Url|AlertPlugin|Role|AgentGroupMember|App|Knowledge|Macro|Topology|Account|AccountGroup|AgentGroup|IndexSetting|KVStore|Fulllink|DBConnection|CustomCommandScript)' \
#| sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
#permission_resource_type=(${resource_type[@]})
resource_type=(dataset alerts reports trends schedules parserrules dashboards savedsearches dictionaries queryscopes)
permission_resource_type=(DataSet Alert Report Trend SavedSchedule ParserRule DashBoardGroup SavedSearch Dictionary QueryScope)
permission_resource_name=(数据集 监控 报表 趋势图 定时任务 字段提取 仪表盘 已存搜索 字典 搜索权限)
permission_meta=`$request -H "$auth" "${url}${api}/permissions/meta/" 2>/dev/null \
| jq -rc "[.objects|map(select(.resource_type!=\"\"))|.[]|{id:.id,action:.action,resource_type:.resource_type}]"`

for (( i=0;i<${#roles_array[@]};i++));do
        role_id=`echo "$roles_json" | jq -rc ".|map(select(.name==\"${roles_array[$i]}\"))|.[].id"`
        role_name=`echo "$roles_json" | jq -rc ".|map(select(.name==\"${roles_array[$i]}\"))|.[].name"`
        for ((x=0;x<${#permission_resource_type[@]};x++));do
            if [[ ${permission_resource_type[$x]} != "QueryScope" ]];then
                read_meta_id=`echo "$permission_meta" | jq ".|map(select(.resource_type==\"${permission_resource_type[$x]}\" and .action==\"Read\"))|.[].id"`
                update_meta_id=`echo "$permission_meta" | jq ".|map(select(.resource_type==\"${permission_resource_type[$x]}\" and .action==\"Update\"))|.[].id"`
                match_resource_json=`$request -H "$auth" "${url}${api}/${resource_type[$x]}/?size=5000&sort=-id" 2>/dev/null \
                | jq -rc "[.objects|map(select(.rt_list[].name==\"$role_name\" or .rt_list[].name==\"org.$role_name\"))|.[]|{id:.id}]"`
                match_resource_len=`echo "$match_resource_json" | jq -rc '.|length'`
                if [[ $match_resource_len != '' ]] && [[ $match_resource_len != 0 ]];then
                        permission_read_data="{\"resource_type\": \"${permission_resource_type[$x]}\",\"update_permissions\": [],\"resource_ids\": \"\"}"
                        permission_update_data="{\"resource_type\": \"${permission_resource_type[$x]}\",\"update_permissions\": [],\"resource_ids\": \"\"}"
                        for (( y=0;y<$match_resource_len;y++ ));do
                                match_resource_id=`echo "$match_resource_json" | jq -rc ".[$y].id"`
                                v="{\"meta_id\":$read_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}"
                                t="{\"meta_id\":$update_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}"
                                permission_read_data=`echo "$permission_read_data" | jq --argjson v "{\"meta_id\":$read_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}" '.update_permissions['$y'] += '$v'' | jq -rc .`
                                permission_update_data=`echo "$permission_update_data" | jq --argjson t "{\"meta_id\":$update_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}" '.update_permissions['$y'] += '$t'' | jq -rc .`
                        done
                        return_1=$($request -H "$header" -H "$auth" -X PUT -d "${permission_read_data}" "${url}${api}/permissions/role/$role_id/" 2>/dev/null)
                        return_2=$($request -H "$header" -H "$auth" -X PUT -d "${permission_update_data}" "${url}${api}/permissions/role/$role_id/" 2>/dev/null)
                        if [[ $(echo "$return_1" | jq -rc .result) == "true" ]] && [[ $(echo "$return_2" | jq -rc .result) == "true" ]];then
                                echo "角色【$role_name】的${permission_resource_name[$x]}已添加关联资源的读取和编辑权限."
                        else
                                echo "角色【$role_name】的${permission_resource_name[$x]}关联资源的读取和编辑权限添加失败,错误信息: $(echo "$return_1" | jq -rc .error.message),错误信息: $(echo "$return_2" | jq -rc .error.message)"
                        fi
                else
                       :
			 #echo "角色【$role_name】的${permission_resource_name[$x]}没有关联资源需要授权."
                fi
            elif [[ ${permission_resource_type[$x]} == "QueryScope" ]];then             #搜索权限只有Read权限，没有Updata和Delete的权限
                read_meta_id=`echo "$permission_meta" | jq ".|map(select(.resource_type==\"${permission_resource_type[$x]}\" and .action==\"Read\"))|.[].id"`
                match_resource_json=`$request -H "$auth" "${url}${api}/${resource_type[$x]}/?size=5000&sort=-id" 2>/dev/null \
                | jq -rc "[.objects|map(select(.rt_list[].name==\"$role_name\" or .rt_list[].name==\"org.$role_name\"))|.[]|{id:.id}]"`
                match_resource_len=`echo "$match_resource_json" | jq -rc '.|length'`
                if [[ $match_resource_len != '' ]] && [[ $match_resource_len != 0 ]];then
                        permission_read_data="{\"resource_type\": \"${permission_resource_type[$x]}\",\"update_permissions\": [],\"resource_ids\": \"\"}"
                        for (( y=0;y<$match_resource_len;y++ ));do
                                match_resource_id=`echo "$match_resource_json" | jq -rc ".[$y].id"`
                                v="{\"meta_id\":$read_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}"
                                permission_read_data=`echo "$permission_read_data" | jq --argjson v "{\"meta_id\":$read_meta_id,\"resource_id\":$match_resource_id,\"grant\":false}" '.update_permissions['$y'] += '$v'' | jq -rc .`
                        done
                        return=$($request -H "$header" -H "$auth" -X PUT -d "${permission_read_data}" "${url}${api}/permissions/role/$role_id/" 2>/dev/null)
                        if [[ $(echo "$return" | jq -rc .result) == "true" ]];then
                                echo "角色【$role_name】的${permission_resource_name[$x]}已添加关联资源的读取权限."
                        else
                                echo "角色【$role_name】的${permission_resource_name[$x]}关联资源的读取权限添加失败,错误信息: $(echo "$return" | jq -rc .error.message)"
                        fi
                else
                       :
			 #echo "角色【$role_name】的${permission_resource_name[$x]}没有关联资源需要授权."
                fi
            fi
            roles_n=$i                  #检查最后一个角色的各类资源的资源标签是否为空
            if [[ $(expr ${#roles_array[@]} - 1) == $roles_n ]];then
                if [[ "${resource_type[$x]}" == "dictionaries" ]];then          #字典没有name字段，而是file_name
                        notag_resource_json=`$request -H "$auth" "${url}${api}/${resource_type[$x]}/?size=10000&sort=-id" 2>/dev/null \
                        | jq -rc "objects[]|map(select(.rt_list==[]))" 2>/dev/null | jq -rc "[.[]|{id:.id,name:.file_name}]"`
                else
                        notag_resource_json=`$request -H "$auth" "${url}${api}/${resource_type[$x]}/?size=10000&sort=-id" 2>/dev/null \
                        | jq -rc "objects[]|map(select(.rt_list==[]))" 2>/dev/null | jq -rc "[.[]|{id:.id,name:.name}]"`
                fi
                notag_resource_len=`echo "$notag_resource_json" | jq -rc '.|length'`
                if [[ $notag_resource_len != '' ]] && [[ $notag_resource_len != 0 ]];then
                        for (( z=0;z<$notag_resource_len;z++ ));do
                                notag_resource_name=`echo "$notag_resource_json" | jq -rc ".[$z].name"`
                                echo "${permission_resource_name[$x]}【$notag_resource_name】资源标签为空."
                        done
                fi
            fi
        done
        start=`expr $i + 1`
        progress_bar $start ${#roles_array[@]}
        printf '\nFinished!\n'
done
}

basic_resource_add() {          #新接入业务系统添加同名的基本资源，包括角色、用户分组、数据集、org.资源标签，功能角色需要手动添加，名称为General_User或general_user均可，会自动关联用户分组
general_role_id=`$request -H "$auth" "${url}${api}/roles/?size=1000&sort=-id" 2>/dev/null | jq -rc ".objects|map(select(.name==\"General_User\" or .name==\"general_user\"))|.[].id"`
system_name=`echo "$system_name" | sed 's/\"//g;s/,/ /g'`
system_name=(${system_name[@]})
for (( i=0; i<${#system_name[@]}; i++ ));do
        role_request_data="{\"name\":"\"${system_name[$i]}\"",\"memo\":\"\"}"
        role_return=$($request -H "$header" -H "$auth" -X POST -d "$role_request_data" "${url}${api}/roles/" 2>/dev/null)
        if [[ $(echo "$role_return" | jq -rc .result) == "true" ]];then
                echo "角色【${system_name[$i]}】已添加."
                role_id=`echo "$role_return" | jq -rc .object`
                if [[ $general_role_id != "" ]];then
                        role_id="$role_id,$general_role_id"
                fi
                usergroup_request_json=`jq -Mnr --argjson v "{\"name\":\"${system_name[$i]}\",\"memo\":\"\",\"administrator_ids\":\"\",\"role_ids\":\"$role_id\"}" '$v'`
                usergroup_return=$($request -H "$header" -H "$auth" -X POST -d "${usergroup_request_json}" "${url}${api}/usergroups/" 2>/dev/null)
                if [[ $(echo "$usergroup_return" | jq .result) == "true" ]];then
                        echo "用户分组【${system_name[$i]}】已添加."
                else
                        echo "用户分组【${system_name[$i]}】添加失败,错误信息: $(echo "$usergroup_return" | jq -rc .error.message)"
                fi
        else
                echo "角色【${system_name[$i]}】添加失败,错误信息: $(echo "$role_return" | jq -rc .error.message)"
        fi
        dataset_request_json=`jq -Mnr --argjson v \
        "{\"name\":\"${system_name[$i]}\",\"alias\":\"${system_name[$i]}\",\"action\":1,\"queryfilter\":\"*\",\"rt_names\":\"org.${system_name[$i]}\",\"fields\":\"[]\",\"app_ids\":1}" '$v'`
        dataset_return=$($request -H "$header" -H "$auth" -X POST -d "${dataset_request_json}" "${url}${api3}/datasets/" 2>/dev/null)
        if [[ $(echo "$dataset_return" | jq .result) == "true" ]];then
                echo "数据集【${system_name[$i]}】已添加,关联资源标签:【org.${system_name[$i]}】"
        else
                echo "数据集【${system_name[$i]}】添加失败,错误信息: $(echo "$dataset_return" | jq -rc .error.message)"
        fi
        start=`expr $i + 1`
        progress_bar $start ${#system_name[@]}
        printf '\nFinished!\n'
done
}

report_alert_filter_delete() {
report_json=$($request -H "$auth" "${url}${api}/reports/?size=1000&sort=-id" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name,email:.email}]')
alert_json=$($request -H "$auth" "${url}${api}/alerts/?size=1000&sort=-id" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name}]')
report_id_array=`echo "$report_json" | jq '.[].id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
report_id_array=(${report_id_array[@]})
alert_id_array=`echo "$alert_json" | jq '.[].id' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
alert_id_array=(${alert_id_array[@]})
info=`echo "$phone_email" | sed -e 's/\"//g;s/,/ /g'`
info=(${info[@]})
for (( i=0; i<${#info[@]}; i++ ));do
        phone=`echo -n "${info[$i]}" | grep -Ewo "^1[0-9]{10}$"`
        email=`echo -n "${info[$i]}" | grep -Ewo "^[A-Za-z0-9._]+@[A-Za-z0-9.]+\.[a-zA-Z]{2,4}+(\.[a-zA-Z]{2,4})*?$"`
        if [[ x$phone != x ]];then
                phones[${#phones[@]}]=$phone
        elif [[ x$email != x ]];then
                emails[${#emails[@]}]=$email
        else
                echo "${info[$i]}格式不正确,已忽略."
        fi
done
unset phone email

if [[ -n "$emails" ]];then
for (( x=0; x<${#emails[@]}; x++ ));do
        for (( y=0; y<${#report_id_array[@]}; y++ ));do
                start=`expr $x + 1`
                progress_bar $start ${#emails[@]}
                report_name=`echo "$report_json" | jq -rc ".|map(select(.id==${report_id_array[$y]}))" | jq -rc .[].name`
                report_email_json=`echo "$report_json" | jq -rc ".|map(select(.id==${report_id_array[$y]}))" | jq .[].email | sed 's/\\\\//g;s/^\"//g;s/\"$//g' | jq -rc '.email' 2>/dev/null`
                if [[ x$report_email_json == x ]];then          #报表的email字段有两种格式
                        report_email_json=`echo "$report_json" | jq -rc ".|map(select(.id==${report_id_array[$y]}))" | jq -rc .[].email | sed 's/,/","/g;s/^/\["/g;s/$/"]/g'`
                        if [[ x$report_email_json != x ]];then
                                report_email_cnt=`echo "$report_email_json" | tr ',' '\n' | wc -l`
                        else
                                report_email_cnt='0'
                        fi
                else
                        report_email_cnt=`echo "$report_email_json" | jq '.|length'`
                fi
                if [[ $report_email_cnt != 0 ]];then
                        report_email_check=`echo "$report_email_json" | grep -Ewo ${emails[$x]}`
                        if [[ x$report_email_check != x ]] && [[ $report_email_cnt == 1 ]];then
                                return=$($request -H "$auth" -H "$header" -X PUT -d "{\"email\":\"\"}" \
                                "${url}${api}/reports/${report_id_array[$y]}/" 2>/dev/null)
                                echo -e "\n报表【$report_name】接收邮箱${emails[$x]}已删除,当前报表接收邮箱为空."
                        elif [[ x$report_email_check != x ]] && [[ $report_email_cnt != 1 ]];then
                                email_list=`echo "$report_email_json" | jq .[] | grep -vw ${emails[$x]} | sed '/\r$/d' | tr '\n' ' ' | sed 's/\"\s\"/,/g'`
                                return=$($request -H "$auth" -H "$header" -X PUT -d "{\"email\":$email_list}" \
                                "${url}${api}/reports/${report_id_array[$y]}/" 2>/dev/null)
                                if [[ $(echo "$return" | jq -rc .result) == "true" ]];then
                                        echo -e "\n报表【$report_name】接收邮箱${emails[$x]}已删除."
                                else
                                        echo -e "\n报表【$report_name】接收邮箱${emails[$x]}删除失败,错误信息: $(echo "$return" | jq -rc .error.message)"
                                fi
                        fi
                else
                        echo -e "\n报表【$report_name】接收邮箱为空."
                fi
        done
done
        printf '\nFinished!\n'
fi

if [[ -n "$emails" ]] || [[ -n "$phones" ]];then
for (( x=0; x<${#alert_id_array[@]}; x++ ));do
        start=`expr $x + 1`
        progress_bar $start ${#alert_id_array[@]}
        alert_name=`echo "$alert_json" | jq -rc ".|map(select(.id==${alert_id_array[$x]}))" | jq -rc .[].name`
        alert_metas_raw=`$request -H "$auth" "${url}${api}/alerts/${alert_id_array[$x]}/" 2>/dev/null | jq -rc '.object.alert_metas'`
        alert_metas_json=$($request -H "$auth" "${url}${api}/alerts/${alert_id_array[$x]}/" 2>/dev/null | jq -rc '.object.alert_metas')
        alert_metas_cnt=$(echo "$alert_metas_json" | jq '.|length')
        for (( y=0; y<${alert_metas_cnt}; y++ ));do
                if [[ -n "$emails" ]] && [[ $(echo "${alert_metas_json}" | jq -rc ".[$y].name") =~ "email" ]];then
                        alert_metas_mail_json=`echo "$alert_metas_json" | jq -rc ".[$y]|{name:.name,alias:.alias,value:.configs[1].value}"`
                        alert_email_alias=`echo "$alert_metas_mail_json" | jq -rc .alias`
                        alert_email_array=(`echo $(echo "$alert_metas_mail_json" | jq -rc .value) | tr ',' ' '`)
                        alert_email_cnt=$(echo ${#alert_email_array[@]})
                        for email in "${emails[@]}";do
                                alert_email_check=`echo "${alert_email_array[@]}" | grep -Ewo $email`
                                if [[ x$alert_email_check != x && $alert_email_cnt == 1 ]];then
                                        echo -e "\n监控【$alert_name】的【$alert_email_alias】存在接收邮箱$email,但接收者数量仅为1,已忽略."
                                elif [[ x$alert_email_check != x && $alert_email_cnt != 1 ]];then
                                        alert_metas_raw=`echo "$alert_metas_raw" | sed "s/$email,//g;s/,$email//g"`
                                        echo -e "\n监控【$alert_name】的【$alert_email_alias】接收邮箱$email已删除."
                                 fi
                        done
                elif [[ -n "$phones" ]] && [[ $(echo "${alert_metas_json}" | jq -rc ".[$y].name") =~ "sms" ]];then
                        alert_metas_sms_json=`echo "$alert_metas_json" | jq -rc ".[$y]|{name:.name,alias:.alias,value:.configs[0].value}"`
                        alert_sms_alias=`echo "$alert_metas_sms_json" | jq -rc .alias`
                        alert_sms_array=(`echo $(echo "$alert_metas_sms_json" | jq -rc .value) | tr ',' ' '`)
                        alert_sms_cnt=$(echo ${#alert_sms_array[@]})
                        for phone in "${phones[@]}";do
                                alert_sms_check=`echo "${alert_sms_array[@]}" | grep -Ewo $phone`
                                if [[ x$alert_sms_check != x && $alert_sms_cnt == 1 ]];then
                                        echo -e "\n监控【$alert_name】的【$alert_sms_alias】存在手机号码$phone,但接收者数量仅为1,已忽略."
                                elif [[ x$alert_sms_check != x && $alert_sms_cnt != 1 ]];then
                                        alert_metas_raw=`echo "$alert_metas_raw" | sed "s/$phone,1/1/g;s/,$phone//g"`
                                        echo -e "\n监控【$alert_name】的【$alert_sms_alias】手机号码$phone已删除."
                                fi
                        done
                elif [[ -n "$phones" ]] && [[ $(echo "${alert_metas_json}" | jq -rc ".[$y].name") == "migu_zabbix" ]];then
                        alert_metas_zabbix_json=`echo "$alert_metas_json" | jq -rc ".[$y]|{name:.name,alias:.alias,value:.configs[2].value}"`
                        alert_zabbix_alias=`echo "$alert_metas_zabbix_json" | jq -rc .alias`
                        alert_zabbix_value=`echo "$alert_metas_zabbix_json" | jq -rc .value`
                        alert_zabbix_array=(`echo "$alert_zabbix_value" | tr ',' ' '`)
                        alert_zabbix_cnt=$(echo ${#alert_zabbix_array[@]})
                        for phone in "${phones[@]}";do
                                alert_zabbix_check=`echo -n $(echo "$alert_zabbix_value" | tr ',' '\n' | grep -Ew $phone)`
                                if [[ x$alert_zabbix_check != x && $alert_zabbix_cnt == 1 ]];then
                                        echo -e "\n监控【$alert_name】的【$alert_zabbix_alias】存在联系人【$alert_zabbix_check】,但接收者数量仅为1,已忽略."
                                elif [[ x$alert_zabbix_check != x && $alert_zabbix_cnt != 1 ]];then
                                        alert_metas_raw=`echo "$alert_metas_raw" | perl -pe 's|[^"]*?:'$phone',|\1|'`
                                        alert_metas_raw=`echo "$alert_metas_raw" | perl -pe 's|,[^,]*?:'$phone'|\1|'`
                                        echo -e "\n监控【$alert_name】的【$alert_zabbix_alias】联系人【$alert_zabbix_check】已删除."
                                fi
                        done
                fi
        done
        alert_metas_raw=`echo "$alert_metas_raw" | sed 's/\\\\/\\\\\\\\/g;s/"/\\\\"/g'`
        return=$($request -H "$auth" -H "$header" -X PUT -d "{\"alert_metas\":\"$alert_metas_raw\"}" \
        "${url}${api}/alerts/${alert_id_array[$x]}/" 2>/dev/null)
        if [[ $(echo "$return" | jq -rc .result) == "false" ]];then
                echo -e "\n监控【$alert_name】删除邮箱或手机号码失败,error message:$(echo "$return" | jq -rc .error.message)"
        fi
done
        printf '\nFinished!\n'
fi
}

proxy_batch_deploy() {				#批量部署proxy
if [[ $(test `which expect 2>/dev/null` && echo "yes" || echo "no") == "no" ]];then
        echo "当前服务器缺少expect依赖包."
        exit 1
fi
result=(安装完成 连接超时 密码错误 进程启动失败 目录已存在 进程已存在)
start=0
lines=`sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | wc -l`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read ip port ssh_port ssh_user ssh_passwd manager_ip proxy_version web_proxy_port auth_proxy_port collector_proxy_port yottaweb_ip auth_ip collector_ip;do
/bin/expect <<-!
        set timeout 30
        spawn /bin/ssh -p $ssh_port $ssh_user@$ip
        expect {
        default { send_error "\r";exit 1}
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect {
        "assword:" { send "\r";exit 2}
        "~" { send "ls /opt/proxy/\r"}
        }
        expect {
        "conf" { send "\r";exit 4}
        "~" { send "ps -cef | grep proxy | grep -v grep\r"}
        }
        expect {
        "toml" { send "\r";exit 5}
        "~" { send "exit\r"}

        }
        expect eof
!
i=$?
if [[ $i == 0 ]];then
curl -k -s -L -o /tmp/proxy-${proxy_version}.tar.gz http://$manager_ip:8180/downloads/proxy-${proxy_version}.tar.gz && tar -zxf /tmp/proxy-${proxy_version}.tar.gz -C /tmp/
sed -i "s/192.168.1.31:10002/$ip:$port/;s/192.168.1.31:8081/$ip:$web_proxy_port/;s/192.168.1.31:8082/$ip:$auth_proxy_port/;s/192.168.1.31:5180/$ip:$collector_proxy_port/" /tmp/proxy/conf/proxy.toml
sed -i "2a\addr_in_heartbeat = \"$ip:$port\"" /tmp/proxy/conf/proxy.toml
yottaweb_ip=`echo "$yottaweb_ip" | sed 's/^/"/;s/ /:80","/g;s/$/:80"/'`
auth_ip=`echo "$auth_ip" | sed 's/^/"/;s/ /:8080","/g;s/$/:8080"/'`
collector_ip=`echo "$collector_ip" | sed 's/^/"/;s/ /:5180","/g;s/$/:5180"/'`
sed -i "s/\"192.168.1.54:5180\"/$collector_ip/" /tmp/proxy/conf/proxy.toml
sed -i "s/\"192.168.1.54:8080\"/$auth_ip/" /tmp/proxy/conf/proxy.toml
sed -i "s/\"192.168.1.54\"/$yottaweb_ip/" /tmp/proxy/conf/proxy.toml
cat << EOF >> /tmp/proxy_monitor.sh
#!/bin/bash
num=\`netstat -lnp | grep -ow proxy | wc -l\`
if [ \$num != 4 ];then
   cd /opt/proxy/bin && nohup ./proxy -config=../conf/proxy.toml &
   echo "\`date +"%F %X"\`" >> /opt/proxy_monitor.log
   exit 0
fi
EOF
/bin/expect <<-!
        spawn /bin/scp -P $ssh_port -r /tmp/proxy_monitor.sh /tmp/proxy $ssh_user@$ip:/opt/
        expect {
        default { send_error "\r";exit 1}
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect eof
!
/bin/expect <<-!
        set timeout 30
        spawn /bin/ssh -p $ssh_port $ssh_user@$ip
        expect {
        default { send_error "\r";exit 1}
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect {
        "assword:" { send "\r";exit 2}
        "~" { send "crontab -l > /tmp/crontab.tmp && echo '*/5 * * * * /bin/sh /opt/proxy_monitor.sh > /dev/null 2>&1' >> /tmp/crontab.tmp && crontab /tmp/crontab.tmp && rm -f /tmp/crontab.tmp\r"}
        }
        expect "~"
        send "cd /opt/proxy/bin/ && nohup ./proxy -config=../conf/proxy.toml &\r"
        expect "~]"
        send "ps -cef | grep proxy | grep -v grep\r"
        expect {
        "toml" { send "\r";exit 0}
        "~" { send "\r";exit 3}
        }
        expect eof
!
        i=$?;echo "Proxy $ip ${result[$i]}"
        start=`expr $start + 1`
        progress_bar $start $lines
        rm -rf /tmp/proxy-${proxy_version}.tar.gz /tmp/proxy/ /tmp/proxy_monitor.sh
        printf '\n'
else
        echo "Proxy $ip ${result[$i]}"
        start=`expr $start + 1`
        progress_bar $start $lines
        printf '\n'
fi
done
        printf 'Finished!\n'
}

agent_batch_deploy() {				#批量部署agent
if [[ $(test `which expect 2>/dev/null` && echo "yes" || echo "no") == "no" ]];then
        echo "当前服务器缺少expect依赖包."
        exit 1
fi
result=(安装完成 连接超时 密码错误 目录已存在 进程已存在)
start=0
lines=`sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | wc -l`
sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read ip port platform agent_version agent_script_id ssh_port ssh_user ssh_passwd nginx_ip input_proxy proxy_ip web_port auth_port collector_port proxy_ssh_user proxy_ssh_passwd;do
if [[ $(test "$input_proxy" == "否" && test -n "$input_proxy" && echo "yes" || echo "no") == 'yes' ]];then
        agent_script_url=`echo "$nginx_ip:80/api/v0/agent/shell/download/$platform/$agent_version/$agent_script_id"`
/bin/expect <<-!
        set timeout 30
        set port $port
        set agent_script_url $agent_script_url
        spawn /bin/ssh -p $ssh_port $ssh_user@$ip
        expect {
        default { send_error "\r";exit 1}
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect {
        "assword:" { send_error "\r";exit 2}
        "~" { send "ls $HOME/heka\r"}
        }
        expect {
        default { send_error "\r";exit 3}
        "directory" { send "ps -cef | grep $HOME/heka | wc -l\r"}
        }
        expect {
        default { send_error "\r";exit 4}
        "1" { send "curl -k -s -L -O '$agent_script_url'\r"}
        }
        expect "~"
        send "sed -i 's/10001/$port/' ${agent_script_url##*/}\r"
        expect "~"
        send "sh ${agent_script_url##*/} 2>/dev/null\r"
        expect {
        "~" { send "rm -f ${agent_script_url##*/} package.tar.gz crontab.tmp\r"}
        }
        expect "~"
        send "exit\r"
        expect eof
!
        i=$?;echo "Agent $ip ${result[$i]}"
elif [[ $(test "$input_proxy" == "是" && test -n "$input_proxy" && echo "yes" || echo "no") == 'yes' ]];then
        agent_script_url=`echo "$proxy_ip:$web_port/api/v0/agent/shell/download/$platform/$agent_version/$agent_script_id"`
        curl -k -s -L -O $agent_script_url
        heka_download_addr=`grep -E '^HEKA_DOWNLOAD_URL' ${agent_script_url##*/} | awk -F '/' '{print $3}'`
        hb_collector_addr=`grep -E '^HB_COLLECTOR_ADDR' ${agent_script_url##*/} | awk -F '=' '{print $2}' | sed 's/"//g'`
        collector_addr=`grep -E '^COLLECTOR_ADDR' ${agent_script_url##*/} | awk -F '=' '{print $2}' | sed 's/"//g'`
/bin/expect <<-!
        set timeout 30
        set ip $ip
        set port $port
        set ssh_user $ssh_user
        set ssh_port $ssh_port
        set ssh_passwd $ssh_passwd
        set agent_script_url $agent_script_url
        set proxy_ip $proxy_ip
        set web_port $web_port
        set auth_port $auth_port
        set collector_port $collector_port
        set heka_download_addr $heka_download_addr
        set hb_collector_addr $hb_collector_addr
        set collector_addr $collector_addr
        spawn /bin/ssh $proxy_ssh_user@$proxy_ip
        expect {
        default { send_error "\r";exit 1}
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$proxy_ssh_passwd\r";}
        }
        expect {
        "assword:" { send_error "\r";exit 2}
        "~" { send "curl -k -s -L -O '$agent_script_url'\r"}
        }
        expect "~"
        send "sed -i 's/10001/$port/;s/$collector_addr/$proxy_ip:$collector_port/;s/$hb_collector_addr/$proxy_ip:$auth_port/;s/$heka_download_addr/$proxy_ip:$web_port/' ${agent_script_url##*/}\r"
        expect "~"
        send "scp -P $ssh_port -r ${agent_script_url##*/} $ssh_user@$ip:~/\r"
        expect {
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect {
        "assword:" { send_error "\r";exit 2}
        "~" { send "ssh -p $ssh_port $ssh_user@$ip\r"}
        }
        expect {
        "yes/no" { send "yes\r";exp_continue}
        "assword:" { send "$ssh_passwd\r";}
        }
        expect "~"
        send "sh ${agent_script_url##*/} 2>/dev/null\r"
        expect "~"
        send "rm -f ${agent_script_url##*/} package.tar.gz crontab.tmp\r"
        expect "~"
        send "exit\r"
        expect "~"
        send "rm -f ${agent_script_url##*/}\r"
        expect "~"
        send "exit\r"
        expect eof
!
        i=$?;echo "Agent $ip ${result[$i]}"
        rm -f ${agent_script_url##*/}
else
        echo "是否对接Proxy的字段列值不可为空."
        exit 1
fi
        start=`expr $start + 1`
        progress_bar $start $lines
        printf '\n'
done
        printf 'Finished!\n'
}

resource_import() {
if [[ -x /opt/rizhiyi/mysql/bin/mysql ]];then
	mysql_bin="/opt/rizhiyi/mysql/bin/mysql"
elif [[ -x ./mysql ]];then
        mysql_bin="./mysql"
else
        echo "当前主机缺少mysql依赖包."
        exit 1
fi
if [[ -x /opt/rizhiyi/parcels/mongodb/bin/mongo ]];then
	mongo_bin="/opt/rizhiyi/parcels/mongodb/bin/mongo"
elif [[ -x ./mongo ]];then
	mongo_bin="./mongo"
else
        echo "当前主机缺少mongo依赖包."
        exit 1
fi
if [[ -x /opt/rizhiyi/mysql/bin/mysqldump ]];then
	mysqldump_bin="/opt/rizhiyi/mysql/bin/mysqldump"
elif [[ -x ./mysqldump ]];then
	mysqldump_bin="./mysqldump"
else
	echo "当前主机缺少mysqldump依赖包."
        exit 1
fi
if [[ -x /opt/rizhiyi/parcels/mongodb/bin/mongoexport ]];then
	mongoexport_bin="/opt/rizhiyi/parcels/mongodb/bin/mongoexport"
elif [[ -x ./mongoexport ]];then
	mongoexport_bin="./mongoexport"
else
        echo "当前主机缺少mongoexport依赖包."
        exit 1
fi
if [[ -x /opt/rizhiyi/parcels/mongodb/bin/mongoimport ]];then
	mongoimport_bin="/opt/rizhiyi/parcels/mongodb/bin/mongoimport"
elif [[ -x ./mongoimport ]];then
	mongoimport_bin="./mongoimport"
else
        echo "当前主机缺少mongoimport依赖包."
        exit 1
fi
start_a=0
lines=`sed -e 1d $source | sed -e '/^$/d;/^[[:space:]]*$/d' | wc -l`
line_1=`cat $source | head -n 1`
date=`date "+%Y%m%d"`
sed -i '1d' $source
while IFS=',' read -u 3 mysql_export_ip mysql_export_user mysql_export_password mongo_export_ip mongo_export_user mongo_export_password mysql_import_ip mysql_import_user mysql_import_password mongo_import_ip mongo_import_user mongo_import_password;do
	if [[ ! -d mongodb_export ]];then
		mkdir ./mongodb_export
	elif [[ ! -d mysql_export ]];then
		mkdir ./mysql_export
	elif [[ ! -d agentgroup_meta ]];then
		mkdir ./agentgroup_meta
	fi	
        read -t 300 -r -p "确认是否导出备集群节点${mysql_import_ip}的agent分组关联关系元数据到目录`pwd`/agentgroup_meta？[Y/N] " input
        case $input in
        [yY][eE][sS]|[yY])
echo "开始导出备集群的agent分组关联关系元数据到`pwd`/agentgroup_meta目录..."
###备集群默认使用80端口调用API获取agent分组关联关系
filename=`echo "${mysql_import_ip}_agentgroup_meta"`
agentgroup_json=`$request -H "$auth" "http://${mysql_import_ip}${api}/agentgroup/?&size=1000&sort=-id" 2>/dev/null | jq -rc '[.objects[]|{id:.id,name:.name,memo:.memo,rt_list:.rt_list}]'`
agentgroup_array=`echo "$agentgroup_json" | jq -rc ".[].name" | grep -Ev '(__default_agent_group__)' | tr ',' ' ' | sed -e 's/\"//g' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
agentgroup_array=(${agentgroup_array[@]})
role_json=`$request -H "$auth" "http://${mysql_import_ip}${api}/roles/?&size=1000" 2>/dev/null | jq -rc '[.objects[]|{name:.name,id:.id}]'`
role_array=`echo "$role_json" | jq -rc ".[].name" | grep -Ev '(admin|General_User|general_user|^__)' | sed '/\r$/d' | tr '\n' ' ' | sed 's/\s$//g'`
role_array=(${role_array[@]})
Role_AgentGroupId_Json="{\"data\":[]}"
for ((x=0; x<${#role_array[@]}; x++ ));do
        role_id=`echo "$role_json" | jq -rc ".|map(select(.name=="\"${role_array[$x]}\""))|.[].id"`
        role_agentgroup=`$request -H "$auth" "http://${mysql_import_ip}${api}/permissions/role/$role_id/meta/?resource_type=AgentGroup" 2>/dev/null \
        | jq '.object.role_permissions|map(select(.action=="Read"))|[.[]|.resource_id]'`
        Role_AgentGroupId_Json=`echo "$Role_AgentGroupId_Json" | jq --argjson v "{\"role\":\"${role_array[$x]}\",\"agentgroup_ids\":$role_agentgroup}" '.data['$x'] += $v'` 
done
###获取角色所拥有的agent分组ID，组合为JSON数据，样例:{"data":[{"role":"角色1",agentgroup_ids:[]},{"role":"角色2",agentgroup_ids:[11,32]}]}
###提供给每个agent分组遍历这个JSON数据中的每个角色授权的agent分组ID是否匹配，匹配则赋予给对应角色的列表变量值
for (( i=0; i<${#agentgroup_array[@]}; i++ ));do
        ag_id=`echo "$agentgroup_json" | jq -rc ".|map(select(.name=="\"${agentgroup_array[$i]}\""))|.[].id"`
        match_roles=(__user_admin__)
        for (( y=0;y<${#role_array[@]}; y++ ));do
                return_ag_id=`echo "$Role_AgentGroupId_Json" | jq ".data|map(select(.role==\"${role_array[$y]}\"))|.[].agentgroup_ids|.[]" | grep -w "$ag_id"`
                if [[ -n "$return_ag_id" ]] ;then
                        match_roles[${#match_roles[@]}]=${role_array[$y]}
                fi      
        done    
        agentgroup=`echo "$agentgroup_json" | jq -rc "[.[$i]]"`
        memo=`echo "$agentgroup" | jq -rc ".[].memo"`
        rt_len=`echo "$agentgroup" | jq ".[].rt_list|length"`
        if [[ $rt_len == "1" ]];then
                orgtag=`echo "$agentgroup" | jq -rc ".[].rt_list[].name"`
        else    
                orgtag=""
        fi      
        echo $ag_id,"${agentgroup_array[$i]}","$memo","$orgtag","${match_roles[@]}" >> ./agentgroup_meta/${filename}_$date.csv
        unset match_roles
        start=`expr $i + 1`
        progress_bar $start ${#agentgroup_array[@]}
done    
	printf '\nFinished!\n'
	echo "file `pwd`/agentgroup_meta/${filename}_$date.csv Export success"
        ;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
        break
        esac
######
	read -t 300 -r -p "确认是否导出主集群mongodb节点${mongo_export_ip}的字典文件到目录`pwd`/mongodb_export？[Y/N] " input
	case $input in
	[yY][eE][sS]|[yY])
	$mongoexport_bin -u "$mongo_export_user" -p "$mongo_export_password" --authenticationDatabase=admin --host $mongo_export_ip:27017 -d share -c dictionary_files.files -o ./mongodb_export/${mongo_export_ip}_${date}_dictionary_files.files
	$mongoexport_bin -u "$mongo_export_user" -p "$mongo_export_password" --authenticationDatabase=admin --host $mongo_export_ip:27017 -d share -c dictionary_files.chunks -o ./mongodb_export/${mongo_export_ip}_${date}_dictionary_files.chunks
        if [[ $? == 0 ]];then
                echo "主集群mongodb节点的字典文件导出完成."
        else
                echo "主集群mongodb节点的字典文件导出失败,请检查..."
        fi
	;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
        break
        esac
	read -t 300 -r -p "确认是否导出主集群mongodb节点${mongo_export_ip}的告警插件到目录`$pwd`/mysql_export？[Y/N] " input
	case $input in
        [yY][eE][sS]|[yY])
        $mongoexport_bin -u "$mongo_export_user" -p "$mongo_export_password" --authenticationDatabase=admin --host $mongo_export_ip:27017 -d share -c alert_plugin.files -o ./mongodb_export/${mongo_export_ip}_${date}_alert_plugin.files
        $mongoexport_bin -u "$mongo_export_user" -p "$mongo_export_password" --authenticationDatabase=admin --host $mongo_export_ip:27017 -d share -c alert_plugin.chunks -o ./mongodb_export/${mongo_export_ip}_${date}_alert_plugin.chunks
	if [[ $? == 0 ]];then
		echo "主集群mongodb节点的告警插件导出完成."
	else
		echo "主集群mongodb节点的告警插件导出失败,请检查..."
	fi
	;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
        break
        esac
	#read -t 300 -r -p "确认是否导出主集群mysql节点${mysql_export_ip}的角色、用户分组、用户、系统配置、角色授权、搜索权限、索引、资源标签、资源相关表到目录`$pwd`/mysql_export？[Y/N] " input
	read -t 300 -r -p "确认是否导出主集群mysql节点${mysql_export_ip}的rizhiyi_system、rizhiyi_yottaweb数据库的同步所需相关表到目录`$pwd`/mysql_export？[Y/N] " input
	case $input in
        [yY][eE][sS]|[yY])
	$mysqldump_bin -h $mysql_export_ip -u $mysql_export_user -p"$mysql_export_password" -P 3306 rizhiyi_system Admin SystemConf Role AccountGroup AccountRole Account AccountGroup_Account QueryScope DataSet DataSetNode DashBoardGroup DashBoardGroup_DashBoard DashBoard Trend ParserRule ParserRule_DataSource ParserRuleCategory Dictionary SavedSearch ResourceTag ResourceTag_Resource Alert Alert_AlertPlugin AlertPlugin App App_Resource App_ResourceGroup Topology Report SavedSchedule RolePrivilege IndexInfo IndexMatchRule > ./mysql_export/${mysql_export_ip}_${date}_mysql_rizhiyi_system_export.sql
        if [[ $? == 0 ]];then
                echo "主集群mysql节点rizhiyi_system数据库的33个指定表导出完成."
        else
                echo "主集群mysql节点rizhiyi_system数据库的33个指定表导出错误,请检查..."
        fi
        $mysqldump_bin -h $mysql_export_ip -u $mysql_export_user -p"$mysql_export_password" -P 3306 rizhiyi_yottaweb system_shortcut eventaction_actions search_history > ./mysql_export/${mysql_export_ip}_${date}_mysql_rizhiyi_yottaweb_export.sql
        if [[ $? == 0 ]];then
                echo "主集群mysql节点rizhiyi_yottaweb数据库的3个指定表导出完成."
        else
                echo "主集群mysql节点rizhiyi_yottaweb数据库的3个指定表导出错误,请检查..."
        fi
	;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
        break
        esac
	mongo_import_ip=`$mongo_bin -u $mongo_import_user -p "$mongo_import_password" --authenticationDatabase admin $mongo_import_ip:27017 --eval "db.isMaster();" | grep primary | awk -F '\"' '{print $4}' | awk -F ':' '{print $1}'` 
	echo "获取导入集群的mongodb主节点IP：$mongo_import_ip"
	read -t 300 -r -p "确认是否将主集群mongodb节点${mongo_export_ip}的字典和告警插件导入备集群${mongo_import_ip}？[Y/N] " input
	case $input in
	[yY][eE][sS]|[yY])
	$mongoimport_bin -u "$mongo_import_user" -p "$mongo_import_password" --authenticationDatabase=admin --host $mongo_import_ip:27017 -d share -c dictionary_files.chunks --file ./mongodb_export/${mongo_export_ip}_${date}_dictionary_files.chunks --mode=upsert
	$mongoimport_bin -u "$mongo_import_user" -p "$mongo_import_password" --authenticationDatabase=admin --host $mongo_import_ip:27017 -d share -c dictionary_files.files --file ./mongodb_export/${mongo_export_ip}_${date}_dictionary_files.files --mode=upsert
	$mongoimport_bin -u "$mongo_import_user" -p "$mongo_import_password" --authenticationDatabase=admin --host $mongo_import_ip:27017 -d share -c alert_plugin.chunks --file ./mongodb_export/${mongo_export_ip}_${date}_alert_plugin.chunks --mode=upsert
	$mongoimport_bin -u "$mongo_import_user" -p "$mongo_import_password" --authenticationDatabase=admin --host $mongo_import_ip:27017 -d share -c alert_plugin.files --file ./mongodb_export/${mongo_export_ip}_${date}_alert_plugin.files --mode=upsert
	;;
	[nN][oO]|[nN])	
	echo "跳过..."
	;;
	*)
	echo "invalid option $REPLY"
	break
	esac
	read -t 300 -r -p "确认是否将备集群mysql节点${mysql_import_ip}的rizhiyi_system数据库备份到目录`pwd`/mysql_export？[Y/N]？" input
	case $input in
        [yY][eE][sS]|[yY])
        echo "开始备份备集群mysql节点${mysql_import_ip}的rizhiyi_system数据库..."
        $mysqldump_bin -h $mysql_import_ip -u $mysql_import_user -p"$mysql_import_password" -P 3306 rizhiyi_system > ./mysql_export/${mysql_import_ip}_${date}_rizhiyi_system.sql	
        echo "开始备份备集群mysql节点${mysql_import_ip}的rizhiyi_yottaweb数据库..."
	$mysqldump_bin -h $mysql_import_ip -u $mysql_import_user -p"$mysql_import_password" -P 3306 rizhiyi_yottaweb > ./mysql_export/${mysql_import_ip}_${date}_rizhiyi_yottaweb.sql	
	if [[ $? == 0 ]];then 
		echo "备集群mysql节点rizhiyi_system、rizhiyi_yottaweb数据库备份已完成."
	else
		echo "备集群mysql节点rizhiyi_system、rizhiyi_yottaweb数据库备份错误,请检查..."
	fi
	;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
	break
	esac
	read -t 300 -r -p "确认是否将主集群mysql节点${mysql_export_ip}的相关表导入备集群$mysql_import_ip？[Y/N] " input
	case $input in
        [yY][eE][sS]|[yY])
	echo "开始导入主集群mysql节点${mysql_export_ip}的相关表到备集群${mysql_import_ip}..."
	$mysql_bin -h $mysql_import_ip -u $mysql_import_user -p"$mysql_import_password" -P 3306 rizhiyi_system <./mysql_export/${mysql_export_ip}_${date}_mysql_rizhiyi_system_export.sql
        $mysql_bin -h $mysql_import_ip -u $mysql_import_user -p"$mysql_import_password" -P 3306 rizhiyi_yottaweb <./mysql_export/${mysql_export_ip}_${date}_mysql_rizhiyi_yottaweb_export.sql
        if [[ $? == 0 ]];then
                echo "主集群mysql节点数据库表导入备集群rizhiyi_system、rizhiyi_yottaweb数据库完成."
        else
                echo "主集群mysql节点数据库表导入备集群rizhiyi_system、rizhiyi_yottaweb数据库出错,请检查..."
		return 1
        fi
        ;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
        *)
        echo "invalid option $REPLY"
        break
        esac
        read -t 300 -r -p "确认是否将备集群${mysql_import_ip}的监控、定时任务、报表全部禁用？[Y/N] " input
        case $input in
	[yY][eE][sS]|[yY])
	enable_alert_json=`$request -H "$auth" "${mysql_import_ip}${api}/alerts/?fields=id,name,enabled" 2>/dev/null | jq -rc '.objects|map(select(.enabled==true))' 2>/dev/null`
	enable_schedule_json=`$request -H "$auth" "${mysql_import_ip}${api}/schedules/?fields=id,name,enabled" 2>/dev/null | jq -rc '.objects|map(select(.enabled==1))' 2>/dev/null`
	enable_report_json=`$request -H "$auth" "${mysql_import_ip}${api}/reports/?fields=id,name,enabled" 2>/dev/null | jq -rc '.objects|map(select(.enabled==1))' 2>/dev/null`
	echo "开始将备集群${mysql_import_ip}的监控、定时任务、报表全部禁用..."
	if [[ $(echo "$enable_alert_json" | jq -rc ".|length") != 0 ]];then
		enable_alert_len=`echo "$enable_alert_json" | jq -rc ".|length"`
		for (( i=0; i<$enable_alert_len;i++ ));do
			alert_id=`echo "$enable_alert_json" | jq -rc .[$i].id`
			alert_name=`echo "$enable_alert_json" | jq -rc .[$i].name`
			alert_return=$($request -H "$auth" -H "$header" -X PUT -d "{\"enabled\": false}" "http://${mysql_import_ip}${api}/alerts/$alert_id/" 2>/dev/null) 
        		if [[ $(echo "$alert_return" | jq '.result') == "true" ]];then
               			echo "Alert $alert_name is disabled."
        		else
               			echo "Alert $alert_name disable failure,error message: $(echo "$alert_return" | jq -rc '.error.message')"
        		fi
		done
	fi
        if [[ $(echo "$enable_schedule_json" | jq -rc ".|length") != 0 ]];then
		enable_schedule_len=`echo "$enable_schedule_json" | jq -rc ".|length"`
                for (( i=0;i<$enable_schedule_len;i++ ));do
                	schedule_id=`echo "$enable_schedule_json" | jq -rc .[$i].id`
                        schedule_name=`echo "$enable_schedule_json" | jq -rc .[$i].name`
                        schedule_return=$($request -H "$auth" -H "$header" -X PUT -d "{\"enabled\": 0}" "http://${mysql_import_ip}${api}/schedules/$schedule_id/" 2>/dev/null)
                        if [[ $(echo "$schedule_return" | jq '.result') == "true" ]];then
                        	echo "Schedule $schedule_name is disabled."
                        else
                                echo "Schedule $schedule_name disable failure,error message: $(echo "$schedule_return" | jq -rc '.error.message')"
                        fi
                done    
	fi
        if [[ $(echo "$enable_report_json" | jq -rc ".|length") != 0 ]];then
                        enable_report_len=`echo "$enable_report_json" | jq -rc ".|length"`
                        for (( i=0;i<$enable_report_len;i++ ));do
                                report_id=`echo "$enable_report_json" | jq -rc .[$i].id`
                                report_name=`echo "$enable_report_json" | jq -rc .[$i].name`
                                report_return=$($request -H "$auth" -H "$header" -X PUT -d "{\"enabled\": 0}" "http://${mysql_import_ip}${api}/reports/$report_id/" 2>/dev/null)
                                if [[ $(echo "$report_return" | jq '.result') == "true" ]];then
                                        echo "Report $report_name is disabled."
                                else
                                        echo "Report $report_name disable failure,error message: $(echo "$report_return" | jq -rc '.error.message')"
                                fi
                        done    
        fi
	;;
        [nN][oO]|[nN])
        echo "跳过..."
        ;;
	*)
	echo "invalid option $REPLY"
	break
	esac
        read -t 300 -r -p "确认是否执行备集群$mysql_import_ip的Agent分组差异化同步还原？[Y/N] " input
        case $input in
        [yY][eE][sS]|[yY])
#echo "开始执行备集群Agent分组差异化同步，步骤1:还原Agent分组的组织标签..."
	echo "开始执行备集群Agent分组差异化同步还原(组织标签、分配角色)..."
###备集群还原agent分组的组织标签
	source_agentgroup_meta=`echo $(pwd)/agentgroup_meta/${mysql_import_ip}_agentgroup_meta_$date.csv`
	cat $source_agentgroup_meta | sed -e '/^$/d;/^[[:space:]]*$/d' | while IFS=',' read -r ag_id ag_name memo orgtag roles;do
        agentgroup_return=`$request -H "$auth" -H "$header" -X PUT -d "{\"name\":\"$ag_name\",\"memo\":\"$memo\",\"rt_names\":\"$orgtag\"}" "http://${mysql_import_ip}${api}/agentgroup/$ag_id/" 2>/dev/null`
	if [[ $(echo "$agentgroup_return" | jq '.result') == "true" ]];then
        	echo "AgentGroup $ag_name resource_tag is renew success."
	else
		echo "AgentGroup $ag_name resource_tag renew failure,error message: $(echo "$agentgroup_return" | jq -rc '.error.message')"
	fi
###备集群清空所有角色的agent分组授权AgentGroup、AgentGroupMember
#echo "开始执行备集群Agent分组差异化同步，步骤2:清空所有角色的Agent分组授权..."
###备集群还原agent分组的分配角色
#echo "开始执行备集群Agent分组差异化同步，步骤3:还原Agent分组的分配角色..."
	done
	;;
        [nN][oO]|[nN])
        echo "跳过..."
	;;
	*)
	echo "invalid option $REPLY"
	break
	esac
        start_a=`expr $start_a + 1`
        progress_bar $start_a $lines
        printf '\n'
done 3< $source 
	sed -i "1i $line_1" $source
        printf 'Finished!\n'
}

main() {
if [[ $(test "$#" == "1" && test "$1" == "-h" && echo 1) == 1 ]]; then
    help
elif [[ "$#" == "4" && $1 == "-r" && $2 == "template" && $3 == "-m" && $4 == "download" ]]; then
    template_download
elif [[ "$#" == "4" && $1 == "-r" && $2 == "template" && $3 == "-m" && $4 == "review" ]]; then
    template_review
elif [[ "$#" == "6" && $1 == "-r" && $2 == "agent" && $3 == "-m" && $4 == "install" && $5 == "-s" && x$6 != x ]]; then
    params_check
    agent_batch_deploy
elif [[ "$#" == "6" && $1 == "-r" && $2 == "proxy" && $3 == "-m" && $4 == "install" && $5 == "-s" && x$6 != x ]]; then
    params_check
    proxy_batch_deploy
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
	$8 == "account" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    account_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "add_agentgroup" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agent_agentgroup_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_logstream" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agent_logstream_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "dataset" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    dataset_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "queryscope" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    queryscope_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "dataset" && $9 == "-m" && ${10} == "sync" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    dataset_sync
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agentgroup" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agentgroup_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "usergroup" && $9 == "-m" && ${10} == "add" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    usergroup_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
	$8 == "account" && $9 == "-m" && ${10} == "delete" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    account_delete
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
	$8 == "account" && $9 == "-m" && ${10} == "enable" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    account_enable
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
	$8 == "account" && $9 == "-m" && ${10} == "disable" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    account_disable
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
	$8 == "account" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    account_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "dataset" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    dataset_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "schedule" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    schedule_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "usergroup" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    usergroup_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "alert" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    alert_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agentgroup" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agentgroup_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "dashboard" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    dashboard_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "dashboard2" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    dashboard2_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agent_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "upgrading_agent" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    upgrading_agent_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "report" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    report_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_logstream" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agent_logstream_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_dbinput" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agent_dbinput_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_processinput" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agent_processinput_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_topinput" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    agent_topinput_download
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_topinput" && $9 == "-m" && ${10} == "delete" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agent_topinput_delete
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "parserrule" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    parserrule_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "app" && $9 == "-m" && ${10} == "download" ]]; then
    params_check
    app_download
elif [[ "$#" == "10" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "role" && $9 == "-m" && ${10} == "permission" ]]; then
    params_check
    role_permission
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "basic" && $9 == "-m" && ${10} == "add" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    basic_resource_add
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_logstream" && $9 == "-m" && ${10} == "download" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    agent_logstream_filter_download
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "start" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    agent_manage start
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "upgrade" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    agent_manage upgrade
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "stop" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    agent_manage stop
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent" && $9 == "-m" && ${10} == "restart" && ${11} == "-f" && x${12} != x ]]; then
    params_check
    agent_manage restart
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_logstream" && $9 == "-m" && ${10} == "delete" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agent_logstream_filter_delete
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "agent_logstream" && $9 == "-m" && ${10} == "renew" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    agent_logstream_filter_renew
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "resource" && $9 == "-m" && ${10} == "import" && ${11} == "-s" && x${12} != x ]]; then
    params_check
    resource_import
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "report_alert" && $9 == "-m" && ${10} == "delete" && ${11} == "-f" && x${12} != x ]];then
    params_check
    report_alert_filter_delete
elif [[ "$#" == "12" && $1 == "-i" && x$2 != x && $3 == "-u" && x$4 != x && $5 == "-p" && x$6 != x && $7 == "-r" && \
        $8 == "account" && $9 == "-m" && ${10} == "enable" && ${11} == "-f" && x${12} != x ]];then
    params_check
    account_filter_enable
else
    echo "Required parameter error"
fi
}
main $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}
