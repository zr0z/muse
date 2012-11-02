TARGET_DIR=$RANDOM;

if [ -d $TARGET_DIR ];
    then echo "Well, that's infortunate. Target directory already exists. Try again?"
    exit 1
fi;

git clone https://github.com/zr0z/muse.git $TARGET_DIR
cd $TARGET_DIR
make && make install
cd ..
rm -Rf $TARGET_DIR

echo "Muse installation complete. Enjoy."