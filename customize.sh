# Automatically get module name and path
MODNAME="$(basename "$MODPATH")"
OLD_MODPATH="/data/adb/modules/$MODNAME"

# Current and old module ZRAM paths
ZRAM_DIR="$MODPATH/zram"
OLD_ZRAM_DIR="$OLD_MODPATH/zram"

ui_print "-------------"
ui_print "  _____           _     ____ "
ui_print " |  ___|   _ _ __| |   / ___|"
ui_print " | |_ | | | | '__| |  | |    "
ui_print " |  _|| |_| | |  | |__| |___ "
ui_print " |_|   \__,_|_|  |_____\____|"
ui_print "      FurLC ZRAM Module      "
ui_print "-------------"

ui_print ">> Checking if the installed module's zram folder exists..."

if [ -d "$OLD_ZRAM_DIR" ]; then
  ui_print ">> Detected old module zram folder, copying retained files..."
  mkdir -p "$ZRAM_DIR"
  cp -af "$OLD_ZRAM_DIR/." "$ZRAM_DIR/"
  ui_print ">> File copy completed ✅"
else
  ui_print ">> No old module zram folder detected, skipping copy"
fi
