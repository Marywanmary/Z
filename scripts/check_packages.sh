#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 图标定义
INFO="📋"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
FIX="🔧"
SEARCH="🔍"

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

log_fix() {
    echo -e "${PURPLE}${FIX} [FIX]${NC} $1"
}

log_search() {
    echo -e "${BLUE}${SEARCH} [SEARCH]${NC} $1"
}

# 查找包的替代方案
find_alternative() {
    local package=$1
    local alternatives_file="logs/package_alternatives.txt"
    
    log_search "查找包 $package 的替代方案..."
    
    # 定义一些常见的替代方案
    case "$package" in
        "luci-app-passwall")
            echo "luci-app-openclash luci-app-homeproxy" >> "$alternatives_file"
            ;;
        "luci-app-adguardhome")
            echo "luci-app-adblock luci-app-simple-adblock" >> "$alternatives_file"
            ;;
        "luci-app-frpc")
            echo "luci-app-frps" >> "$alternatives_file"
            ;;
        "luci-app-frps")
            echo "luci-app-frpc" >> "$alternatives_file"
            ;;
        "luci-app-momo")
            echo "luci-app-nikki luci-app-passwall" >> "$alternatives_file"
            ;;
        "luci-app-nikki")
            echo "luci-app-momo luci-app-passwall" >> "$alternatives_file"
            ;;
        *)
            # 尝试查找相似名称的包
            find openwrt/ -name "*$(echo $package | sed 's/luci-app-//')*" -type d | \
            head -5 | sed 's|.*/||' | sed 's/^/luci-app-/' >> "$alternatives_file"
            ;;
    esac
    
    if [ -f "$alternatives_file" ] && [ -s "$alternatives_file" ]; then
        log_success "找到替代方案:"
        cat "$alternatives_file" | while read alt; do
            echo -e "  ${GREEN}→ $alt${NC}"
        done
        return 0
    else
        log_warning "未找到替代方案"
        return 1
    fi
}

# 尝试安装缺失的包
try_install_package() {
    local package=$1
    
    log_fix "尝试安装包: $package"
    
    # 尝试从feeds安装
    cd openwrt
    if ./scripts/feeds install "$package" 2>/dev/null; then
        log_success "成功安装包: $package"
        return 0
    fi
    
    # 尝试从kenzok8源安装
    if [ -d "../smpackage" ]; then
        if find ../smpackage -name "${package}*.ipk" | head -1 | xargs -I {} cp {} packages/; then
            log_success "从kenzok8源复制包: $package"
            return 0
        fi
    fi
    
    # 尝试查找替代方案
    if find_alternative "$package"; then
        log_warning "包 $package 无法安装，但找到了替代方案"
        return 2
    fi
    
    log_error "无法安装包: $package"
    return 1
}

# 修复配置文件
fix_config() {
    local config_file=$1
    local missing_packages=$2
    local fixed_config=$3
    
    log_info "开始修复配置文件..."
    
    # 复制原始配置
    cp "$config_file" "$fixed_config"
    
    # 处理每个缺失的包
    while read -r package; do
        if [ -n "$package" ]; then
            # 尝试安装包
            try_install_package "$package"
            local result=$?
            
            case $result in
                0)
                    log_success "包 $package 已修复"
                    ;;
                2)
                    log_warning "包 $package 需要替代方案"
                    # 从配置中注释掉这个包
                    sed -i "s/CONFIG_PACKAGE_${package}=y/# CONFIG_PACKAGE_${package}=y/g" "$fixed_config"
                    ;;
                1)
                    log_error "包 $package 无法修复"
                    # 从配置中注释掉这个包
                    sed -i "s/CONFIG_PACKAGE_${package}=y/# CONFIG_PACKAGE_${package}=y/g" "$fixed_config"
                    ;;
            esac
        fi
    done < "$missing_packages"
    
    # 更新配置文件
    mv "$fixed_config" "$config_file"
    
    log_success "配置文件修复完成"
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    local config_profile=${3:-Ultra}
    
    log_info "开始自动修复包依赖..."
    
    # 检查缺失的包文件
    local missing_deps="logs/missing_dependencies_final.txt"
    
    if [ ! -f "$missing_deps" ] || [ ! -s "$missing_deps" ]; then
        log_info "没有发现缺失的包"
        exit 0
    fi
    
    # 显示缺失的包
    log_error "发现以下缺失的包:"
    cat "$missing_deps" | while read pkg; do
        echo -e "  ${RED}✗ $pkg${NC}"
    done
    
    # 修复配置文件
    local config_file="openwrt/.config"
    local fixed_config="openwrt/.config.fixed"
    
    fix_config "$config_file" "$missing_deps" "$fixed_config"
    
    # 重新生成配置
    cd openwrt
    make defconfig
    
    log_success "自动修复完成"
}

# 执行主函数
main "$@"
