#!/bin/bash
set -euo pipefail

# 生成Release内容
generate_release() {
    local repo_short=$1
    local soc_name=$2
    local kernel_version=$3
    local devices=$4
    
    cat << EOF
# ${repo_short^}-${soc_name} 固件发布

## 基本信息
- **默认管理地址**: 192.168.111.1
- **默认用户**: root
- **默认密码**: none
- **默认WIFI密码**: 12345678

## 固件信息
- **分支**: ${repo_short^}
- **芯片架构**: ${soc_name}
- **设备列表**: ${devices}
- **内核版本**: ${kernel_version}
- **作者**: Mary
- **发布时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 编译的LUCI应用列表
 $(find artifacts/packages/ -name "luci-app-*.ipk" -exec basename {} \; | sort | sed 's/^/- /')

## 下载说明
- **固件文件**: 对应设备的固件文件
- **${soc_name}-config.tar.gz**: 配置文件集合
- **${soc_name}-app.tar.gz**: 软件包集合
- **${soc_name}-log.tar.gz**: 编译日志

## 注意事项
1. 刷机前请备份原固件
2. 首次刷机建议使用Factory固件
3. 后续升级可使用Sysupgrade固件
4. 刷机后需恢复出厂设置

## 支持的设备
 $(ls artifacts/*.bin | grep -E "factory|sysupgrade" | sed 's/.*\///' | sed 's/-.*//' | sort -u | sed 's/^/- /')
EOF
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    local kernel_version=${3:-unknown}
    local devices=${4:-unknown}
    
    generate_release "$repo_short" "$soc_name" "$kernel_version" "$devices"
}

main "$@"
