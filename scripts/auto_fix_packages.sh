#!/bin/bash
# DIY脚本：配置第三方源及设备初始管理IP/密码

# 启用严格模式：遇到错误立即退出，未定义的变量视为错误
set -euo pipefail

# 加载公共库
source "$(dirname "$0")/lib/logger.sh"
source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/error-handler.sh"
source "$(dirname "$0")/lib/utils.sh"

# --- 主逻辑 ---
main() {
    # 接收从 workflow 传入的参数
    local branch_name="${1:-openwrt}"
    local soc_name="${2:-ipq60xx}"

    echo "=========================================="
    echo " DIY Script for OpenWrt"
    echo " Branch: ${branch_name}"
    echo " SoC:     ${soc_name}"
    echo "=========================================="

    # 步骤 1: 修改默认IP & 固件名称 & 编译署名
    echo "==> Step 1: Modifying default settings..."
    sed -i 's/192.168.1.1/192.168.111.1/g' package/base-files/files/bin/config_generate
    sed -i "s/hostname='.*'/hostname='WRT'/g" package/base-files/files/bin/config_generate
    sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Built by Mary')/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
    echo "✅ Default settings modified."

    # 步骤 2: 预删除官方软件源缓存
    echo "==> Step 2: Pre-deleting official package caches..."
    OFFICIAL_CACHE_PACKAGES=(
        # laipeng668定制包相关的官方缓存包
        "package/feeds/packages/golang"
        "package/feeds/packages/ariang"
        "package/feeds/packages/frp"
        "package/feeds/packages/adguardhome"
        "package/feeds/packages/wolplus"
        "package/feeds/packages/lucky"
        "package/feeds/packages/wechatpush"
        "package/feeds/packages/open-app-filter"
        "package/feeds/packages/gecoosac"
        "package/feeds/luci/luci-app-frpc
        "package/feeds/luci-app-frps"
        "package/feeds/luci-app-adguardhome"
        "package/feeds/luci-app-wolplus
        "package/feeds/luci-app-lucky"
        "package/feeds/luci-app-wechatpush"
        "package/feeds/luci-app-athena-led"
        
        # Mary定制包相关的官方缓存包
        "package/feeds/packages/netspeedtest"
        "package/feeds/packages/partexp"
        "package/feeds/packages/taskplan"
        "package/feeds/packages/tailscale"
        "package/feeds/packages/momo"
        "package/feeds/packages/nikki"
        "package/feeds/luci/luci-app-netspeedtest"
        "package/feeds/luci-app-partexp"
        "package/feeds/luci-app-taskplan"
        "package/feeds/luci-app-tailscale"
        "package/feeds/luci-app-momo"
        "package/feeds/luci-app-nikki"
        "package/feeds/luci-app-openclash"
        
        "package/feeds/luci-app-athena-led"
    )

    OFFICIAL_WORK_PACKAGES=(
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
        "package/feeds/luci-app-frps"
        "package/feeds/luci-app-adguardhome"
        "package/feeds/luci-app-wolplus"
        "package/feeds/luci-app-lucky"
        "package/feeds/luci-app-wechatpush"
        "package/feeds/luci-app-athena-led"
        
        # Mary定制包相关的官方缓存包
        "package/feeds/packages/netspeedtest"
        "package/feeds/utils/partexp"
        "package/feeds/utils/taskplan"
        "package/feeds/net/tailscale"
        "package/feeds/net/momo"
        "package/feeds/net/nikki"
        "package/feeds/luci/luci-app-netspeedtest"
        "package/feeds/luci-app-partexp"
        "package/feeds/luci-app-taskplan"
        "package/feeds/luci-app-tailscale"
        "package/feeds/luci-app-momo"
        "package/feeds/luci-app-nikki"
        "package/feeds/luci-app-openclash"
    )

    for package in "${OFFICIAL_CACHE_PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            rm -rf "$package"
            echo "已删除缓存包: $package"
        fi
    done

    # 步骤 3: 预删除feeds工作目录
    echo "==> Step 3: Pre-deleting feeds working directories..."
    FEEDS_WORK_PACKAGES=(
        # laipeng668定制包相关的feeds工作目录
        "feeds/packages/lang/golang"
        "feeds/packages/net/ariang"
        "feeds/packages/net/frp"
        "feeds/packages/net/adguardhome"
        "feeds/packages/net/wolplus"
        "feeds/packages/net/lucky"
        "feeds/packages/wechatpush"
        "feeds/packages/open-app-filter"
        "feeds/packages/gecoosac"
        "feeds/luci/applications/luci-app-frpc
        "feeds/luci/applications/luci-app-frps
        "feeds/luci/applications/luci-app-adguardhome
        "feeds/luci/applications/luci-app-wolplus
        "feeds/luci/applications/luci-app-lucky
        "feeds/luci/applications/luci-app-wechatpush
        "feeds/luci/applications/luci-app-athena-led"
        
        # Mary定制包相关的feeds工作目录
        "feeds/packages/net/netspeedtest"
        "feeds/utils/partexp"
        "feeds/utils/taskplan"
        "feeds/net/tailscale"
        "feeds/net/momo"
        "feeds/net/nikki"
        "feeds/luci/applications/luci-app-netspeedtest"
        "feeds/luci/applications/luci-app-partexp
        "feeds/luci/applications/luci-app-taskplan"
        "feeds/luci/applications/luci-app-tailscale
        "feeds/luci/applications/luci-app-momo"
        "feeds/luci/applications/luci-app-nikki"
        "feeds/luci/applications/luci-app-openclash"
    )

    for package in "${FEEDS_WORK_PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            rm -rf "$package"
            echo "已删除工作目录包: $package"
        fi
    done

    # 步骤 4: 克隆定制化软件包
    echo "==> Step 4: Cloning custom packages..."
    
    # 创建临时目录存储克隆状态
    mkdir -p .clone_status
    
    # 克隆函数，带重试机制
    clone_with_retry() {
        local url="$1"
        local dest="$2"
        local max_attempts=3
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            echo "尝试克隆 $url 到 $dest (尝试 $attempt/$max_attempts)"
            
            if git clone --depth=1 "$url" "$dest"; then
                echo "✅ 成功克隆 $url"
                return 0
            else
                echo "❌ 克隆失败，尝试 $attempt/$max_attempts"
                attempt=$((attempt + 1)
                sleep 5
            fi
        done
        
        echo "❌ 无法克隆 $url，跳过"
        return 1
    }
    
    # laipeng668定制包
    clone_with_retry https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang || echo "跳过 golang"
    clone_with_retry https://github.com/sbwml/luci-app-openlist2 package/openlist || echo "跳过 openlist2"
    clone_with_retry https://github.com/laipeng668/packages.git feeds/packages/net/ariang || echo "跳过 ariang"
    clone_with_retry https://github.com/laipeng668/luci.git feeds/luci/applications/luci-app-frpc || echo "跳过 luci-app-frpc"
    clone_with_retry https://github.com/laipeng668/luci.git feeds/luci/applications/luci-app-frps || echo "跳过 luci-app-frps"
    clone_with_retry https://github.com/kenzok8/openwrt-packages.git package/adguardhome || echo "跳过 adguardhome"
    clone_with_retry https://github.com/kenzok8/openwrt-packages.git package/luci-app-adguardhome || echo "跳过 luci-app-adguardhome"
    clone_with_retry https://github.com/VIKINGYFY/packages.git feeds/luci/applications/luci-app-wolplus || echo "跳过 luci-app-wolplus"
    clone_with_retry https://github.com/tty228/luci-app-wechatpush.git package/luci-app-wechatpush || echo "跳过 luci-app-wechatpush"
    clone_with_retry https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter || echo "跳过 OpenAppFilter"
    clone_with_retry https://github.com/lwb1978/openwrt-gecoosac.git package/openwrt-gecoosac || echo "跳过 openwrt-gecoosac"
    clone_with_retry https://github.com/NONGFAH/luci-app-athena-led.git package/luci-app-athena-led || echo "跳过 luci-app-athena-led"
    
    # Mary定制包
    clone_with_retry https://github.com/sirpdboy/luci-app-netspeedtest.git package/netspeedtest || echo "跳过 netspeedtest"
    clone_with_retry https://github.com/sirpdboy/luci-app-partexp.git package/partexp || echo "跳过 partexp"
    clone_with_retry https://github.com/sirpdboy/luci-app-taskplan.git package/taskplan || echo "跳过 taskplan"
    clone_with_retry https://github.com/tailscale/tailscale.git package/tailscale || echo "跳过 tailscale"
    clone_with_retry https://github.com/nikkinikki-org/OpenWrt-momo.git package/momo || echo "跳过 momo"
    clone_with_retry https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki || echo "跳过 nikki"
    clone_with_retry https://github.com/vernesong/OpenClash.git package/openclash || echo "跳过 openclash"

    # kenzok8软件源（该软件源仅作为查漏补缺，优先级最低，仅在上方软件源未命中feeds中软件包时才提供。)
    clone_with_retry https://github.com/kenzok8/small-package smpackage || echo "跳过 small-package"

    # 设置权限
    if [ -d "package/luci-app-athena-led" ]; then
        chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led
        chmod +x package/luci-app-athena-led/root/usr/sbin/athena-led
    fi
    
    echo "✅ Custom packages cloned."

    # 步骤 5: 应用补丁（如果有）
    echo "==> Step 5: Applying patches..."
    if [ -d "../patches/${branch_name}" ]; then
        for patch in ../patches/${branch_name}/*.patch; do
            if [ -f "$patch" ]; then
                echo "应用补丁: $patch"
                patch -p1 < "$patch"
            fi
        done
    fi

    # 步骤 6: 优化编译设置
    echo "==> Step 6: Optimizing build settings..."
    
    # 启用ccache以加速编译
    echo "CONFIG_CCACHE=y" >> .config
    
    # 根据可用内存调整并行编译数
    available_memory=$(free -m | awk '/Mem:/ {print $7}')
    if [ "$available_memory" -lt 4096 ]; then
        echo "检测到内存不足，限制并行编译数"
        sed -i 's/-j[0-9]\+/-1/' Makefile
    fi
    
    echo "✅ Build settings optimized."

    # 注意：feeds update 和 install 已移至 build.yml 中，以便利用缓存
    echo "==> DIY script finished successfully."

    # 注意：feeds update 和 install 已移至 build.yml 中，以便利用缓存
    echo "==> DIY script finished successfully."
}

# 执行主函数，并传入所有参数
main "$@"
