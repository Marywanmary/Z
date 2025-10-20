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

# 图标定义
INFO="📋"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
CONFIG="⚙️"
MERGE="🔀"

# 日志函数
log_info() {
    echo -e "${BLUE}${INFO} [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}${SUCCESS} [SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}${WARNING} [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}${ERROR} [ERROR]${NC} $1"
}

log_config() {
    echo -e "${PURPLE}${CONFIG} [CONFIG]${NC} $1"
}

log_merge() {
    echo -e "${CYAN}${MERGE} [MERGE]${NC} $1"
}

# 验证配置文件
validate_config() {
    local config_file=$1
    
    if [ ! -f "$config_file" ]; then
        log_error "配置文件 $config_file 不存在"
        return 1
    fi
    
    # 检查配置文件格式
    if ! grep -q "CONFIG_" "$config_file"; then
        log_error "配置文件 $config_file 格式无效"
        return 1
    fi
    
    log_success "配置文件 $config_file 验证通过"
    return 0
}

# 合并配置文件
merge_configs() {
    local repo_short=$1
    local soc_name=$2
    local config_profile=$3
    
    log_info "开始合并配置文件..."
    log_info "分支: $repo_short, 芯片: $soc_name, 配置: $config_profile"
    
    # 创建临时目录
    mkdir -p tmp_config logs
    
    # 定义配置文件列表
    local base_config="configs/base_${soc_name}.config"
    local branch_config="configs/base_${repo_short}.config"
    local profile_config="configs/${config_profile}.config"
    
    # 验证配置文件
    for config in "$base_config" "$branch_config" "$profile_config"; do
        validate_config "$config"
    done
    
    # 创建合并报告
    local merge_report="logs/config_merge_report.md"
    cat > "$merge_report" << EOF
# 配置文件合并报告

## 合并时间
 $(date '+%Y-%m-%d %H:%M:%S')

## 配置文件
- 基础配置: $base_config
- 分支配置: $branch_config
- 包配置: $profile_config

## 合并顺序
1. $base_config (基础配置)
2. $branch_config (分支配置)
3. $profile_config (包配置)

EOF
    
    # 按优先级合并配置
    log_merge "步骤1: 合并基础配置 $base_config"
    cat "$base_config" > tmp_config/merged.config
    log_config "基础配置行数: $(wc -l < tmp_config/merged.config)"
    
    log_merge "步骤2: 合并分支配置 $branch_config"
    cat "$branch_config" >> tmp_config/merged.config
    log_config "合并后行数: $(wc -l < tmp_config/merged.config)"
    
    log_merge "步骤3: 合并包配置 $profile_config"
    cat "$profile_config" >> tmp_config/merged.config
    log_config "最终行数: $(wc -l < tmp_config/merged.config)"
    
    # 去重并排序
    log_merge "步骤4: 去重和排序"
    awk '!seen[$0]++' tmp_config/merged.config | sort > tmp_config/final.config
    
    # 统计配置项
    local total_configs=$(grep -c "^CONFIG_" tmp_config/final.config)
    local enabled_configs=$(grep -c "=y$" tmp_config/final.config)
    local disabled_configs=$(grep -c "=n$" tmp_config/final.config)
    
    log_config "配置统计:"
    log_config "  总配置项: $total_configs"
    log_config "  启用配置: $enabled_configs"
    log_config "  禁用配置: $disabled_configs"
    
    # 提取设备名称
    log_merge "步骤5: 提取设备名称"
    grep -oE "CONFIG_TARGET_DEVICE_.*_DEVICE_[^=]+=y" tmp_config/final.config | \
    sed -E 's/CONFIG_TARGET_DEVICE_.*_DEVICE_([^=]+)=y/\1/' | \
    sort -u > tmp_config/devices.list
    
    local device_count=$(wc -l < tmp_config/devices.list)
    log_config "检测到设备 ($device_count): $(cat tmp_config/devices.list | tr '\n' ' ')"
    
    # 提取LUCI包
    log_merge "步骤6: 提取LUCI包"
    grep "CONFIG_PACKAGE_luci-app-.*=y" tmp_config/final.config | \
    sed 's/CONFIG_PACKAGE_\(.*\)=y/\1/' | \
    sort > tmp_config/luci_packages.txt
    
    local luci_count=$(wc -l < tmp_config/luci_packages.txt)
    log_config "检测到LUCI包 ($luci_count):"
    cat tmp_config/luci_packages.txt | head -10 | while read pkg; do
        log_config "  - $pkg"
    done
    if [ $luci_count -gt 10 ]; then
        log_config "  ... 还有 $((luci_count - 10)) 个包"
    fi
    
    # 更新合并报告
    cat >> "$merge_report" << EOF

## 配置统计
- 总配置项: $total_configs
- 启用配置: $enabled_configs
- 禁用配置: $disabled_configs

## 设备列表
 $(cat tmp_config/devices.list | sed 's/^/- /')

## LUCI包列表
 $(cat tmp_config/luci_packages.txt | sed 's/^/- /')

EOF
    
    # 复制到OpenWrt目录
    cp tmp_config/final.config openwrt/.config
    
    # 保存中间文件
    cp tmp_config/final.config logs/final_merged.config
    cp tmp_config/devices.list logs/device_list.txt
    cp tmp_config/luci_packages.txt logs/luci_packages_merged.txt
    
    log_success "配置文件合并完成"
    log_info "合并报告: $merge_report"
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    local config_profile=${3:-Ultra}
    
    merge_configs "$repo_short" "$soc_name" "$config_profile"
}

main "$@"
