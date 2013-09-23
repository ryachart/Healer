

ASSETS_DIR=${PROJECT_DIR}/assets

declare -a sprite_atlas_dirs=(sprites battle-sprites shop-sprites spell-sprites effect-sprites divinity-sprites shop-flavor-1 shop-flavor-2 postbattle map-icons items inventory avatar)

mkdir -p $ASSETS_DIR


for folder_name in ${sprite_atlas_dirs[@]}
do
    folder_dir=${PROJECT_DIR}/$folder_name
    plist=$ASSETS_DIR/${folder_name}-ipad-hd.plist
    sheet=$ASSETS_DIR/${folder_name}-ipad-hd.pvr.ccz
    /usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet --auto-sd $folder_dir/*.png
    /usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet $folder_dir/*.png
done
