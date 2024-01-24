
unzip -d ./ flash.zip

bash ./gen_flasher.sh -o ps006_flasher.img -f Roobi.img -b flash.img

xz -fek9T 0 ps006_flasher.img