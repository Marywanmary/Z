#!/bin/bash

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# 设置错误退出
set -e

log "======= 开始配置第三方源 ======="

# 修改默认IP & 固件名称 & 编译署名
log "配置默认网络设置"
sed -i 's/192.168.1.1/192.168.111.1/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='WRT'/g" package/base-files/files/bin/config_generate

# 移除要替换的包
log "移除要替换的包"
rm -rf feeds/luci/applications/luci-app-appfilter
rm -rf feeds/luci/applications/luci-app-frpc
rm -rf feeds/luci/applications/luci-app-frps
rm -rf feeds/packages/net/open-app-filter
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/packages/net/ariang
rm -rf feeds/packages/net/frp
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
    branch="$1" repourl="$2" && shift 2
    log "稀疏克隆: $repourl (分支: $branch)"
    git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
    repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
    cd $repodir && git sparse-checkout set $@
    mv -f $@ ../package
    cd .. && rm -rf $repodir
    log "完成稀疏克隆: $@"
}

# Go & OpenList & ariang & frp & AdGuardHome & WolPlus & Lucky & OpenAppFilter & 集客无线AC控制器 & 雅典娜LED控制
log "添加Go语言支持"
git clone --depth=1 https://github.com/sbwml/packages_lang_golang   feeds/packages/lang/golang

log "添加OpenList"
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2   package/openlist

log "添加AriaNg"
git_sparse_clone ariang https://github.com/laipeng668/packages   net/ariang

log "添加FRP"
git_sparse_clone frp https://github.com/laipeng668/packages   net/frp
mv -f package/frp feeds/packages/net/frp
git_sparse_clone frp https://github.com/laipeng668/luci   applications/luci-app-frpc applications/luci-app-frps
mv -f package/luci-app-frpc feeds/luci/applications/luci-app-frpc
mv -f package/luci-app-frps feeds/luci/applications/luci-app-frps

log "添加WOL Plus"
git_sparse_clone main https://github.com/VIKINGYFY/packages   luci-app-wolplus

log "添加集客无线AC控制器"
git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac   package/openwrt-gecoosac

log "添加雅典娜LED控制"
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led   package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led

# ====== Mary定制包 ======
log "添加Mary定制包"
log "添加网络速度测试"
git clone --depth=1 https://github.com/sirpdboy/luci-app-netspeedtest   package/netspeedtest

log "添加分区扩展"
git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp   package/luci-app-partexp

log "添加任务计划"
git clone --depth=1 https://github.com/sirpdboy/luci-app-taskplan   package/luci-app-taskplan

log "添加Tailscale"
git clone --depth=1 https://github.com/tailscale/tailscale   package/tailscale

log "添加Lucky"
git clone --depth=1 https://github.com/gdy666/luci-app-lucky   package/luci-app-lucky

log "添加OpenAppFilter"
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git   package/OpenAppFilter

log "添加MoMo"
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo   package/luci-app-momo

log "添加Nikki"
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki   package/nikki

log "添加OpenClash"
git clone --depth=1 https://github.com/vernesong/OpenClash   package/OpenClash

# ====== 添加kenzok8软件源并且让它的优先级最低，也就是如果有软件包冲突，它的软件包会被其它软件源替代。 ======
log "添加kenzok8软件源"
git clone --depth=1 https://github.com/kenzok8/small-package   small8 

log "更新feeds"
./scripts/feeds update -a

log "安装feeds"
./scripts/feeds install -a

log "======= 第三方源配置完成 ======="
