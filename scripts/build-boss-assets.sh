

ASSETS_DIR=${PROJECT_DIR}/assets
BOSSES_DIR=${PROJECT_DIR}/bosses

if [ -d "$ASSETS_DIR" ]; then
    I=0 #find returns the parent directory that we dont care about, so skip it
    for D in `find $BOSSES_DIR -type d`
    do
        if [ $I -gt 0 ]; then
            BOSS_KEY=`basename $D`
            plist=$ASSETS_DIR/$BOSS_KEY-ipad-hd.plist
            sheet=$ASSETS_DIR/$BOSS_KEY-ipad-hd.pvr.ccz
            /usr/local/bin/TexturePacker --smart-update --premultiply-alpha --opt RGBA8888 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet --variant .5: $D/*.png
            /usr/local/bin/TexturePacker --smart-update --premultiply-alpha --dither-atkinson --opt RGBA4444 --disable-rotation --max-size 2048 --shape-padding 2 --data $plist --format cocos2d --sheet $sheet $D/*.png
        fi
        let I+=1
    done

fi
