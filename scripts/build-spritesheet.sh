

ASSETS_DIR=${PROJECT_DIR}/assets

declare -a sprite_atlas_dirs=(sprites battle-sprites shop-sprites spell-sprites effect-sprites divinity-sprites shop-flavor-1 shop-flavor-2 postbattle map-icons items inventory avatar)

mkdir -p $ASSETS_DIR


for folder_name in ${sprite_atlas_dirs[@]}
do
    folder_dir=${PROJECT_DIR}/$folder_name
    /usr/local/bin/TexturePacker --variant 1:-ipad-hd --variant 0.5:-ipad --data ${folder_name}{v}.plist --sheet ${folder_name}{v}.png --format cocos2d $ASSETS_DIR
done
