#!/bin/bash
# 优化后的DIY脚本
set -euo pipefail

# 输出带颜色的日志
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

# 主函数
main() {
    local repo_short=${1:-openwrt}
    local soc_name=${2:-ipq60xx}
    
    log_info "开始执行DIY脚本..."
    log_info "分支: ${repo_short}, SoC: ${soc_name}"
    
    # 步骤1: 修改默认设置
    log_info "步骤1: 修改默认设置..."
    sed -i 's/192.168.1.1/192.168.111.1/g' package/base-files/files/bin/config_generate
    sed -i "s/hostname='.*'/hostname='WRT'/g" package/base-files/files/bin/config_generate
    sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Built by Mary')/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
    log_info "✅ 默认设置修改完成"
    
    # 步骤2: 删除官方缓存包
    log_info "步骤2: 删除官方缓存包..."
    local official_cache=(
        "package/feeds/packages/golang"
        "package/feeds/packages/ariang"
        "package/feeds/packages/frp"
        "package/feeds/packages/adguardhome"
        "package/feeds/packages/wolplus"
        "package/feeds/packages/lucky"
        "package/feeds/packages/wechatpush"
        "package/feeds/packages/open-app-filter"
        "package/feeds/packages/gecoosac"
        "package/feeds/luci/luci-app-frpc"
        "package/feeds/luci/luci-app-frps"
        "package/feeds/luci/luci-app-adguardhome"
        "package/feeds/luci/luci-app-wolplus"
        "package/feeds/luci/luci-app-lucky"
        "package/feeds/luci/luci-app-wechatpush"
        "package/feeds/luci/luci-app-athena-led"
        "package/feeds/packages/netspeedtest"
        "package/feeds/packages/partexp"
        "package/feeds/packages/taskplan"
        "package/feeds/packages/tailscale"
        "package/feeds/packages/momo"
        "package/feeds/packages/nikki"
        "package/feeds/luci/luci-app-netspeedtest"
        "package/feeds/luci/luci-app-partexp"
        "package/feeds/luci/luci-app-taskplan"
        "package/feeds/luci/luci-app-tailscale"
        "package/feeds/luci/luci-app-momo"
        "package/feeds/luci/luci-app-nikki"
        "package/feeds/luci/luci-app-openclash"
    )
    
    for pkg in "${official_cache[@]}"; do
        if [ -d "$pkg" ]; then
            rm -rf "$pkg"
            log_info "已删除缓存包: $pkg"
        fi
    done
    
    # 步骤3: 删除feeds工作目录
    log_info "步骤3: 删除feeds工作目录..."
    local feeds_work=(
        "feeds/packages/lang/golang"
        "feeds/packages/net/ariang"
        "feeds/packages/net/frp"
        "feeds/packages/net/adguardhome"
        "feeds/packages/net/wolplus"
        "feeds/packages/net/lucky"
        "feeds/packages/net/wechatpush"
        "feeds/packages/net/open-app-filter"
        "feeds/packages/net/gecoosac"
        "feeds/luci/applications/luci-app-frpc"
        "feeds/luci/applications/luci-app-frps"
        "feeds/luci/applications/luci-app-adguardhome"
        "feeds/luci/applications/luci-app-wolplus"
        "feeds/luci/applications/luci-app-lucky"
        "feeds/luci/applications/luci-app-wechatpush"
        "feeds/luci/applications/luci-app-athena-led"
        "feeds/packages/net/netspeedtest"
        "feeds/packages/utils/partexp"
        "feeds/packages/utils/taskplan"
        "feeds/packages/net/tailscale"
        "feeds/packages/net/momo"
        "feeds/packages/net/nikki"
        "feeds/luci/applications/luci-app-netspeedtest"
        "feeds/luci/applications/luci-app-partexp"
        "feeds/luci/applications/luci-app-taskplan"
        "feeds/luci/applications/luci-app-tailscale"
        "feeds/luci/applications/luci-app-momo"
        "feeds/luci/applications/luci-app-nikki"
        "feeds/luci/applications/luci-app-openclash"
    )
    
    for pkg in "${feeds_work[@]}"; do
        if [ -d "$pkg" ]; then
            rm -rf "$pkg"
            log_info "已删除工作目录包: $pkg"
        fi
    done
    
    # 步骤4: 克隆定制化软件包
    log_info "步骤4: 克隆定制化软件包..."
    
    # laipeng668定制包
    git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
    git clone --depth=1 https://github.com/sbwml/luci-app-openlist2 package/openlist
    git clone --depth=1 https://github.com/laipeng668/packages.git feeds/packages/net/ariang
    git clone --depth=1 https://github.com/laipeng668/packages.git feeds/packages/net/frp
    git clone --depth=1 https://github.com/laipeng668/luci.git feeds/luci/applications/luci-app-frpc
    git clone --depth=1 https://github.com/laipeng668/luci.git feeds/luci/applications/luci-app-frps
    git clone --depth=1 https://github.com/kenzok8/openwrt-packages.git package/adguardhome
    git clone --depth=1 https://github.com/kenzok8/openwrt-packages.git package/luci-app-adguardhome
    git clone --depth=1 https://github.com/VIKINGYFY/packages.git feeds/luci/applications/luci-app-wolplus
    git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/luci-app-wechatpush
    git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter
    git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac.git package/openwrt-gecoosac
    git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led.git package/luci-app-athena-led
    
    # Mary定制包
    git clone --depth=1 https://github.com/sirpdboy/luci-app-netspeedtest.git package/netspeedtest
    git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp.git package/partexp
    git clone --depth=1 https://github.com/sirpdboy/luci-app-taskplan.git package/taskplan
    git clone --depth=1 https://github.com/tailscale/tailscale.git package/tailscale
    git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git package/momo
    git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki
    git clone --depth=1 https://github.com/vernesong/OpenClash.git package/openclash
    
    # kenzok8软件源
    git clone --depth=1 https://github.com/kenzok8/small-package smpackage
    
    # 设置权限
    chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led
    
    log_info "✅ 定制化软件包克隆完成"
    log_info "DIY脚本执行完成"
}

main "$@"
