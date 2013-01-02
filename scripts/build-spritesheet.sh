

ASSETS_DIR=${PROJECT_DIR}/assets
sprites_dir=${PROJECT_DIR}/sprites
battle_sprites_dir=${PROJECT_DIR}/battle-sprites
shop_sprites_dir=${PROJECT_DIR}/shop-sprites
spell_sprites_dir=${PROJECT_DIR}/spell-sprites
effect_sprites_dir=${PROJECT_DIR}/effect-sprites
divinity_spires_dir=${PROJECT_DIR}/divinity-sprites
shop_flavor_1_dir=${PROJECT_DIR}/shop-flavor-1
shop_flavor_2_dir=${PROJECT_DIR}/shop-flavor-2

asset=`basename $sprites_dir`
mkdir -p $ASSETS_DIR
plist=$ASSETS_DIR/sprites-ipad-hd.plist
sheet=$ASSETS_DIR/sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet --auto-sd $sprites_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet $sprites_dir/*.png

battle_plist=$ASSETS_DIR/battle-sprites-ipad-hd.plist
battle_sheet=$ASSETS_DIR/battle-sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $battle_plist --format cocos2d --sheet $battle_sheet --auto-sd $battle_sprites_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $battle_plist --format cocos2d --sheet $battle_sheet $battle_sprites_dir/*.png

shop_plist=$ASSETS_DIR/shop-sprites-ipad-hd.plist
shop_sheet=$ASSETS_DIR/shop-sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_plist --format cocos2d --sheet $shop_sheet --auto-sd $shop_sprites_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_plist --format cocos2d --sheet $shop_sheet $shop_sprites_dir/*.png

spell_plist=$ASSETS_DIR/spell-sprites-ipad-hd.plist
spell_sheet=$ASSETS_DIR/spell-sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $spell_plist --format cocos2d --sheet $spell_sheet --auto-sd $spell_sprites_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $spell_plist --format cocos2d --sheet $spell_sheet $spell_sprites_dir/*.png

effect_plist=$ASSETS_DIR/effect-sprites-ipad-hd.plist
effect_sheet=$ASSETS_DIR/effect-sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $effect_plist --format cocos2d --sheet $effect_sheet --auto-sd $effect_sprites_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $effect_plist --format cocos2d --sheet $effect_sheet $effect_sprites_dir/*.png

divinity_plist=$ASSETS_DIR/divinity-sprites-ipad-hd.plist
divinity_sheet=$ASSETS_DIR/divinity-sprites-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $divinity_plist --format cocos2d --sheet $divinity_sheet --auto-sd $divinity_spires_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $divinity_plist --format cocos2d --sheet $divinity_sheet $divinity_spires_dir/*.png

shop_flavor_1_plist=$ASSETS_DIR/shop-flavor-1-ipad-hd.plist
shop_flavor_1_sheet=$ASSETS_DIR/shop-flavor-1-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_flavor_1_plist --format cocos2d --sheet $shop_flavor_1_sheet --auto-sd $shop_flavor_1_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_flavor_1_plist --format cocos2d --sheet $shop_flavor_1_sheet $shop_flavor_1_dir/*.png

shop_flavor_2_plist=$ASSETS_DIR/shop-flavor-2-ipad-hd.plist
shop_flavor_2_sheet=$ASSETS_DIR/shop-flavor-2-ipad-hd.pvr.ccz
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_flavor_2_plist --format cocos2d --sheet $shop_flavor_2_sheet --auto-sd $shop_flavor_2_dir/*.png
/usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $shop_flavor_2_plist --format cocos2d --sheet $shop_flavor_2_sheet $shop_flavor_2_dir/*.png

sh ${PROJECT_DIR}/scripts/build-boss-assets.sh
