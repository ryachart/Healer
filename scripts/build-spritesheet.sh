

ASSETS_DIR=${PROJECT_DIR}/assets
sprites_dir=${PROJECT_DIR}/sprites

# these are all required
	# make destination
asset=`basename $sprites_dir`
mkdir -p $ASSETS_DIR
plist=$ASSETS_DIR/sprites-ipad-hd.plist
sheet=$ASSETS_DIR/sprites-ipad-hd.pvr.ccz
TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet --auto-sd $sprites_dir/*.png
TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet $sprites_dir/*.png

