MODDIR=${0%/*}
LOG_FILE="$MODDIR/zram_module.log"
CONFIG_FILE="$MODDIR/config.prop"
TEE=/system/bin/tee
[ -x "$TEE" ] || TEE=tee

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | $TEE -a "$LOG_FILE"
}

log "======================================="
log "====== Service Start: $(date '+%Y-%m-%d %H:%M:%S') ======"
log "======================================="

# ---------- Read Configuration ----------
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    ZRAM_ALGO="lz4"
    ZRAM_SIZE="8589934592"
fi

log "Read Configuration: ZRAM_ALGO=$ZRAM_ALGO, ZRAM_SIZE=$ZRAM_SIZE"
log "=== ZRAM-Module Service Start ==="
log "Wait for System Initialization to Complete..."
sleep 30

log "Load zstdn.ko..."
if insmod $MODDIR/zram/zstdn.ko 2>>"$LOG_FILE"; then
  log "zstdn.ko Loaded Successfully"
else
  log "zstdn.ko Load Failed"
fi

log "swapoff /dev/block/zram0"
if swapoff /dev/block/zram0 2>>"$LOG_FILE"; then
  log "swapoff Successful"
else
  log "swapoff Failed or Invalid"
fi

log "rmmod zram"
if rmmod zram 2>>"$LOG_FILE"; then
  log "rmmod zram Successful"
else
  log "rmmod zram Failed or Built-in"
fi

log "Wait 5 Seconds..."
sleep 5

log "insmod zram.ko"
if insmod $MODDIR/zram/zram.ko 2>>"$LOG_FILE"; then
  log "zram.ko Loaded Successfully"
else
  log "zram.ko Load Failed"
fi

log "Wait 5 Seconds..."
sleep 5

log "zram0 reset"
if echo '1' > /sys/block/zram0/reset 2>>"$LOG_FILE"; then
  log "zram0 reset Successful"
else
  log "zram0 reset Failed"
fi

log "zram0 disksize 0"
if echo '0' > /sys/block/zram0/disksize 2>>"$LOG_FILE"; then
  log "zram0 disksize Cleared Successfully"
else
  log "zram0 disksize Clear Failed (Can Be Ignored)"
fi

log "zram0 max_comp_streams 8"
if echo '8' > /sys/block/zram0/max_comp_streams 2>>"$LOG_FILE"; then
  log "zram0 max_comp_streams Set Successfully"
else
  log "zram0 max_comp_streams Set Failed"
fi

log "Set Compression Algorithm $ZRAM_ALGO"
if echo "$ZRAM_ALGO" > /sys/block/zram0/comp_algorithm 2>>"$LOG_FILE"; then
  log "Compression Algorithm Set $(cat /sys/block/zram0/comp_algorithm 2>/dev/null)"
else
  log "Compression Algorithm Set Failed, Current: $(cat /sys/block/zram0/comp_algorithm 2>/dev/null)"
fi

log "zram0 disksize $ZRAM_SIZE"
if echo "$ZRAM_SIZE" > /sys/block/zram0/disksize 2>>"$LOG_FILE"; then
  log "zram0 disksize Set Successfully"
else
  log "zram0 disksize Set Failed"
fi

log "mkswap /dev/block/zram0"
if mkswap /dev/block/zram0 > /dev/null 2>>"$LOG_FILE"; then
  log "mkswap Successful"
else
  log "mkswap Failed"
fi

log "swapon /dev/block/zram0"
if swapon /dev/block/zram0 > /dev/null 2>>"$LOG_FILE"; then
  log "swapon Successful"
else
  log "swapon Failed"
fi

# ------------- Key Optimization: Finally Clean Up Redundant ZRAM Devices -------------
log "=== Finally Clean Up Redundant ZRAM Devices (zram1/zram2…) ==="
for zdev in /dev/block/zram*; do
  [ "$zdev" = "/dev/block/zram0" ] && continue
  [ -b "$zdev" ] || continue
  log "Process $zdev ..."
  i=0
  while grep -qw "$zdev" /proc/swaps && [ $i -lt 5 ]; do
    log "swapoff $zdev (Attempt $((i+1)))"
    swapoff "$zdev"
    sleep 1
    i=$((i+1))
  done
  zname=$(basename "$zdev")
  [ -e "/sys/block/$zname/reset" ] && echo 1 > "/sys/block/$zname/reset" && log "reset $zname"
  [ -e "/sys/block/$zname/hot_remove" ] && echo 1 > "/sys/block/$zname/hot_remove" && log "hot_remove $zname"
done
log "Redundant ZRAM Devices Cleanup Completed"

# --------- ZRAM and Memory Status Log ---------
log "--------- ZRAM and Memory Status ---------"
log "zram0 Currently Supported Algorithms: $(cat /sys/block/zram0/comp_algorithm 2>/dev/null)"

if grep -q zram0 /proc/swaps; then
  awk '/zram0/ {printf "zram0 Swap: Device=%s Type=%s Total=%.2fGiB Used=%.2fMiB Priority=%s", $1, $2, $3/1048576, $4/1024, $5}' /proc/swaps | while read line; do log "$line"; done
else
  log "zram0 Not in /proc/swaps"
fi

MEM_LINE="$(free -h | awk '/^Mem:/ {printf "Mem: Total=%s Used=%s Available=%s", $2, $3, $7}')"
SWAP_LINE="$(free -h | awk '/^Swap:/ {printf "Swap: Total=%s Used=%s Available=%s", $2, $3, $4}')"
log "$MEM_LINE"
log "$SWAP_LINE"
log "----------------------------------"
log "=== ZRAM-Module Service Completed ==="
