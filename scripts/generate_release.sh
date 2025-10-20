#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 生成Release内容
generate_release() {
    local repo_short=$1
    local soc_name=$2
    local config_profile=$3
    local kernel_version=$4
    local devices=$5
    local luci_packages=$6
    
    # 转换设备列表
    local device_list=$(echo "$devices" | tr ',' '\n' | sort -u | sed 's/^/- /' | tr '\n' ' ')
    
    # 转换LUCI包列表
    local luci_list=$(echo "$luci_packages" | tr ',' '\n' | sort -u | head -20 | sed 's/^/- /' | tr '\n' ' ')
    local luci_count=$(echo "$luci_packages" | tr ',' '\n' | wc -l)
    
    cat << EOF
# ${repo_short^}-${soc_name}-${config_profile} 固件发布

## 📋 基本信息
- **默认管理地址**: \`192.168.111.1\`
- **默认用户**: \`root\`
- **默认密码**: \`none\`
- **默认WIFI密码**: \`12345678\`

## 🔧 固件信息
- **分支**: ${repo_short^}
- **芯片架构**: ${soc_name}
- **配置类型**: ${config_profile}
- **设备列表**: 
 ${device_list}
- **内核版本**: ${kernel_version}
- **作者**: Mary
- **发布时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 📦 编译的LUCI应用列表 (${luci_count}个)
 ${luci_list}
 $([ $luci_count -gt 20 ] && echo "- ... 还有 $((luci_count - 20)) 个应用")

## 📥 下载说明
- **固件文件**: 对应设备的固件文件
- **${soc_name}-${repo_short}-${config_profile}-config.tar.gz**: 配置文件集合
- **${soc_name}-${repo_short}-${config_profile}-app.tar.gz**: 软件包集合
- **${soc_name}-${repo_short}-${config_profile}-log.tar.gz**: 编译日志

## ⚠️ 注意事项
1. 刷机前请备份原固件
2. 首次刷机建议使用Factory固件
3. 后续升级可使用Sysupgrade固件
4. 刷机后需恢复出厂设置

## 📱 支持的设备
 $(ls artifacts/*.bin 2>/dev/null | grep -E "factory|sysupgrade" | sed 's/.*\///' | sed 's/-.*//' | sort -u | sed 's/^/- /' | tr '\n' '\n')

## 🔄 更新日志
- 更新时间: $(date '+%Y-%m-%d %H:%M:%S')
- 构建环境: Ubuntu $(lsb_release -rs 2>/dev/null || echo "Unknown")
- 编译工具: GCC \$(gcc --version | head -1 | awk '{print \$4}' 2>/dev/null || echo "Unknown")

---
📌 如有问题请提交Issue
EOF
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    local config_profile=${3:-Ultra}
    local kernel_version=${4:-unknown}
    local devices=${5:-unknown}
    local luci_packages=${6:-unknown}
    
    generate_release "$repo_short" "$soc_name" "$config_profile" "$kernel_version" "$devices" "$luci_packages"
}

main "$@"
