

ASSETS_DIR=${PROJECT_DIR}/assets
sprites_dir=${PROJECT_DIR}/sprites
battle_sprites_dir=${PROJECT_DIR}/battle-sprites
shop_sprites_dir=${PROJECT_DIR}/shop-sprites

asset=`basename $sprites_dir`
mkdir -p $ASSETS_DIR
plist=$ASSETS_DIR/sprites-ipad-hd.plist
sheet=$ASSETS_DIR/sprites-ipad-hd.pvr.ccz
TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet --auto-sd $sprites_dir/*.png
TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet $sprites_dir/*.png

battle_plist=$ASSETS_DIR/battle-sprites-ipad-hd.plist
battle_sheet=$ASSETS_DIR/battle-sprites-ipad-hd.pvr.ccz
TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $battle_plist --format cocos2d --sheet $battle_sheet --auto-sd $battle_sprites_dir/*.png
TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $battle_plist --format cocos2d --sheet $battle_sheet $battle_sprites_dir/*.png

shop_plist=$ASSETS_DIR/shop-sprites-ipad-hd.plist
shop_sheet=$ASSETS_DIR/shop-sprites-ipad-hd.pvr.ccz
TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_plist --format cocos2d --sheet $shop_sheet --auto-sd $shop_sprites_dir/*.png
TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_plist --format cocos2d --sheet $shop_sheet $shop_sprites_dir/*.png

