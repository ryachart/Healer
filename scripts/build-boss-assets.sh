ASSETS_DIR=${PROJECT_DIR}/assets
BOSSES_DIR=${PROJECT_DIR}/bosses

if [ -d "$ASSETS_DIR" ]; then
    I=0 #find returns the parent directory that we dont care about, so skip it
    for D in `find $BOSSES_DIR -type d`
    do
        if [ $I -gt 0 ]; then
            BOSS_KEY=`basename $D`
            plist=$ASSETS_DIR/$BOSS_KEY{v}.plist
            sheet=$ASSETS_DIR/$BOSS_KEY{v}.pvr.ccz
            /usr/local/bin/TexturePacker --variant 1:-ipad-hd --variant 0.5:-ipad --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet  $D/*.png
        fi
        let I+=1
    done

fi