#!/bin/bash
set -euo pipefail

# 输出带颜色的日志
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

# 收集编译产物
collect_artifacts() {
    local repo_short=$1
    local soc_name=$2
    local config_profile=$3
    
    log_info "开始收集编译产物..."
    
    # 创建目录
    mkdir -p artifacts/{configs,packages,logs}
    
    # 收集固件
    find openwrt/bin/targets/ -name "*${soc_name}*" -type f | while read file; do
        # 提取设备名称
        local device=$(echo "$file" | grep -oE "${soc_name}-[^-]+" | sed "s/${soc_name}-//")
        
        # 判断固件类型
        if [[ "$file" == *"factory"* ]]; then
            local type="factory"
        elif [[ "$file" == *"sysupgrade"* ]]; then
            local type="sysupgrade"
        else
            continue
        fi
        
        # 重命名
        local new_name="${repo_short}-${device}-${type}-${config_profile}.bin"
        cp "$file" "artifacts/${new_name}"
        log_info "收集固件: $new_name"
    done
    
    # 收集配置文件
    cp openwrt/.config "artifacts/configs/${repo_short}-${soc_name}-${config_profile}.config"
    cp openwrt/bin/targets/*/manifest "artifacts/configs/${repo_short}-${soc_name}-${config_profile}.manifest"
    cp openwrt/bin/targets/*/config.buildinfo "artifacts/configs/${repo_short}-${soc_name}-${config_profile}.config.buildinfo"
    
    # 收集软件包
    find openwrt/bin/packages/ -name "*.ipk" -exec cp {} artifacts/packages/ \;
    
    # 收集日志
    cp -r logs/ artifacts/
    
    log_info "编译产物收集完成"
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    local config_profile=${3:-Ultra}
    
    collect_artifacts "$repo_short" "$soc_name" "$config_profile"
}

main "$@"
