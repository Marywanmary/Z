#!/bin/bash
set -e

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# 固件重命名函数（增强版）
rename_firmware() {
    local original_file="$1"
    local device="$2"
    local config_type="$3"
    local repo_short="$4"
    local chipset="$5"
    
    # 验证文件名中是否包含完整的设备名称
    if [[ ! "$original_file" =~ "-${device}-squashfs-" ]]; then
        log "错误: 文件名与设备不匹配: $(basename "$original_file") ≠ $device"
        return 1
    fi
    
    # 提取固件类型（factory或sysupgrade）
    local fw_type=$(echo "$original_file" | grep -oP 'squashfs-\K(factory|sysupgrade)')
    
    # 构建新文件名
    local new_name="${repo_short}-${chipset}-${device}-${fw_type}-${config_type}.bin"
    
    # 检查目标文件是否已存在
    if [ -f "$OUTPUT_DIR/$new_name" ]; then
        log "警告: 目标文件已存在，将被覆盖: $new_name"
    fi
    
    # 复制并重命名
    cp "$original_file" "$OUTPUT_DIR/$new_name"
    log "重命名固件: $(basename "$original_file") -> $new_name"
    
    return 0
}

# 设备名称提取函数（增强版）
extract_devices() {
    local config_file="$1"
    # 使用更精确的正则表达式，确保完整匹配设备名称
    grep -oP 'CONFIG_TARGET_DEVICE_.*?_DEVICE_\K[^=]+' "$config_file" | \
    sort -u | \
    while read -r device; do
        # 验证设备名称格式（可选）
        if [[ "$device" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "$device"
        else
            log "警告: 跳过无效设备名称: $device"
        fi
    done
}

# 初始化变量
WORKSPACE=$(pwd)
OPENWRT_DIR="$WORKSPACE/openwrt"
CONFIG_DIR="$WORKSPACE/config_temp"
OUTPUT_DIR="$WORKSPACE/output"
CHIPSET=${CHIPSET:-ipq60xx}
REPO_SHORT=${REPO_SHORT:-openwrt}
CONFIG_TYPE=${CONFIG_TYPE:-Pro}

# 创建输出目录结构
mkdir -p "$OUTPUT_DIR"/{configs,logs,packages}

log "======= 开始编译流程 ======="

# 1. 准备编译环境
log "步骤1: 准备编译环境"
cd "$OPENWRT_DIR"
cp "$CONFIG_DIR/merged.config" .config

# 2. 配置第三方源
log "步骤2: 配置第三方源"
"$WORKSPACE/scripts/script.sh" || error_exit "第三方源配置失败"

# 3. 更新feeds
log "步骤3: 更新feeds"
./scripts/feeds update -a || error_exit "Feeds更新失败"
./scripts/feeds install -a || error_exit "Feeds安装失败"

# 4. 加载配置
log "步骤4: 加载配置"
make defconfig || error_exit "配置加载失败"

# 5. 下载依赖
log "步骤5: 下载依赖"
make download -j$(nproc) || error_exit "依赖下载失败"

# 6. 编译固件
log "步骤6: 开始编译固件"
make -j$(nproc) || error_exit "编译失败"

# 7. 处理产出物（优化版）
log "步骤7: 处理产出物"
BIN_DIR="$OPENWRT_DIR/bin/targets/*/$CHIPSET"

# 遍历每个设备
for device in $DEVICES; do
    log "处理设备: $device"
    
    # 精确匹配设备名称的固件文件
    # 模式: *-<设备名称>-squashfs-*.bin
    for fw_file in $(find "$BIN_DIR" -name "*-${device}-squashfs-*.bin" 2>/dev/null); do
        # 调用重命名函数
        rename_firmware "$fw_file" "$device" "$CONFIG_TYPE" "$REPO_SHORT" "$CHIPSET"
    done
    
    # 处理配置文件（每个设备单独保存）
    for ext in config manifest config.buildinfo; do
        src_file="$OPENWRT_DIR/.${ext}"
        if [ -f "$src_file" ]; then
            new_name="${REPO_SHORT}-${CHIPSET}-${device}-${CONFIG_TYPE}.${ext}"
            cp "$src_file" "$OUTPUT_DIR/configs/$new_name"
            log "生成配置文件: $new_name"
        fi
    done
done

# 8. 收集软件包
log "步骤8: 收集软件包"
PKG_DIR="$OPENWRT_DIR/bin/packages/*"
if [ -d "$PKG_DIR" ]; then
    cp -r "$PKG_DIR"/* "$OUTPUT_DIR/packages/"
fi

# 9. 生成日志摘要
log "步骤9: 生成日志摘要"
{
    echo "======= 编译摘要 ======="
    echo "分支: $REPO_SHORT"
    echo "配置: $CONFIG_TYPE"
    echo "芯片: $CHIPSET"
    echo "设备: $DEVICES"
    echo "编译时间: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "======================="
} > "$OUTPUT_DIR/logs/summary.txt"

log "======= 编译流程完成 ======="
