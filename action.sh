MODDIR="/data/adb/modules/ZRAM-Module"
CONFIG_FILE="$MODDIR/config.prop"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  echo "config.prop not found, exiting" >&2
  exit 1
fi

# Reload zram
echo "Disabling current zram..."
swapoff /dev/block/zram0

echo "Resetting zram parameters..."
echo 1 > /sys/block/zram0/reset
echo 0 > /sys/block/zram0/disksize
echo 8 > /sys/block/zram0/max_comp_streams
echo "$ZRAM_ALGO" > /sys/block/zram0/comp_algorithm
echo "$ZRAM_SIZE" > /sys/block/zram0/disksize

echo "Creating zram and enabling..."
mkswap /dev/block/zram0
swapon /dev/block/zram0

echo "ZRAM hot reload completed."
