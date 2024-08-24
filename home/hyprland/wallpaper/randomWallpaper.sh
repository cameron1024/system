# $ALL_WALLPAPERS injected in by nix

CURRENT_WALLPAPER=$(swww query | awk '{print $NF}')
ALL_WALLPAPERS=${ALL_WALLPAPERS//"$CURRENT_WALLPAPER"/}
RANDOM_WALLPAPER=$(shuf -n1 -e $ALL_WALLPAPERS)
RANDOM_WALLPAPER=$(echo "$RANDOM_WALLPAPER" | awk '{$1=$1;print}')

swww img "$RANDOM_WALLPAPER" \
  --resize crop \
  --transition-fps 120 \
  --transition-pos top-left \
  --transition-duration 1 \
  --transition-type grow

rm ~/.wallpaper
ln -s "$RANDOM_WALLPAPER" ~/.wallpaper
echo "done"




