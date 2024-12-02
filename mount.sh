MODDIR=${0%/*}
LOGFILE="$MODDIR/mount.log"
# 写入日志函数
log() {
    local message="$1"
    echo "$(date '+%H:%M:%S') - $message" >> "$LOGFILE"
}
# 创建目录，如果不存在
create_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" && log "创建目录: $dir" || log "创建目录失败: $dir"
    else
        log "目录已存在: $dir"
    fi
}
# 挂载源目录到目标目录
mount_dir() {
    local src="$1"
    local dest="$2"
    if ! mountpoint -q "$dest"; then
        mount --bind "$src" "$dest" && log "挂载 $src 到 $dest" || log "挂载失败: $src -> $dest"
    else
        log "挂载点已存在: $dest"
    fi
}
#設置mnt掛載路徑
SD="/mnt/YAWAsau"
media="/data/media/0/虛擬分區"
Mount_point="/dev/block/by-name/YAWAsau"
Pictures="$SD/Pictures"
Pictures1="/data/media/0/Pictures"
DCIM="$SD/DCIM"
DCIM1="/data/media/0/DCIM"
DCIM="$SD/DCIM"
DCIM1="/data/media/0/DCIM"
TG="/data/media/0/Android/data/tw.nekomimi.nekogram/files/Telegram"
TG1="/data/media/0/Download/Telegram"
QQ="/data/media/0/Android/data/com.tencent.mobileqq/Tencent/QQfile_recv"
QQ1="/data/media/0/Download/QQ"
# 获取 Download 目录的 UID 和 GID
download_uid=$(stat /data/media/0/Download -c '%u' 2>>"$LOGFILE") || { log "获取 Download UID 失败"; exit 1; }
log "获取 Download UID: $download_uid"
create_dir "$SD"
create_dir "$media"
if ! mountpoint -q "$SD"; then
    mount -t ext4 "$Mount_point" "$SD"
    chmod -R 2777 "$SD"
    chown -R media_rw:media_rw "$SD"
    chcon -R "u:object_r:media_rw_data_file:s0" "$SD"
fi
if ! mountpoint -q "$media"; then
    create_dir "$Pictures"
    create_dir "$DCIM"
    create_dir "$TG1"
    create_dir "$QQ1"
    mv "$Pictures1"/* "$Pictures" && log "移動截圖成功"
    mv "$DCIM1"/* "$DCIM" && log "移動照片成功"
    YAWAsau="$SD/備份"
    chown -R "$download_uid:$download_gid" "$YAWAsau"  2>>"$LOGFILE" && log "改变目录所有者成功: $YAWAsau   目录所有者"$download_uid:$download_gid"" || log "改变目录所有者失败: $YAWAsau"    
    mount_dir "$YAWAsau" "$media"
    mount_dir "$Pictures" "$Pictures1"
    mount_dir "$DCIM" "$DCIM1"
    mount_dir "$QQ" "$QQ1"
    mount_dir "$TG" "$TG1"
    chown -R "$download_uid:$download_gid" "$media"  2>>"$LOGFILE" && log "改变目录所有者成功: $media   目录所有者"$download_uid:$download_gid"" || log "改变目录所有者失败: $media"
    chown -R "$download_uid:$download_gid" "$Pictures1"  2>>"$LOGFILE" && log "改变目录所有者成功: $Pictures1   目录所有者"$download_uid:$download_gid"" || log "改变目录所有者失败: $Pictures1"
    chown -R "$download_uid:$download_gid" "$DCIM1"  2>>"$LOGFILE" && log "改变目录所有者成功: $DCIM1   目录所有者"$download_uid:$download_gid"" || log "改变目录所有者失败: $Pictures1"
    chcon -R u:object_r:media_rw_data_file:s0 "$YAWAsau" && log "改变上下文成功: $YAWAsau" || log "改变上下文失败: $YAWAsau"
fi
log "



"
MAX_LOG_SIZE=$((1024 * 100))  

if [[ -f "$LOGFILE" ]] && [[ $(stat -c%s "$LOGFILE") -gt $MAX_LOG_SIZE ]]; then
    rm -f "$LOGFILE"
fi
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard" >/dev/null