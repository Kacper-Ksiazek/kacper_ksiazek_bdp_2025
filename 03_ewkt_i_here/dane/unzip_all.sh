mv ./zips/* .
find *.zip -exec unzip {} \;
mv *.zip ./zips
