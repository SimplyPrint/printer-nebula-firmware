#!/bin/sh

echo -e "${green}Info:Downloading Creality Helper Script...${white}"
git clone https://github.com/Guilouz/Creality-Helper-Script.git /usr/data/helper-script
echo -e "${green}Info:Starting Creality Helper Script...${white}"
sh /usr/data/helper-script/helper.sh
