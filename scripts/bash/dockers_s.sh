#! /bin/bash

cd ~/docker_configs || exit 1

# Define Docker ps ouput
docker_ps () {
docker ps -a --format "{{.Names}}\t{{.Status}}"
}

# seperate ps to seperate lines 
mapfile -t lines < <(docker_ps)

# for loop to create valid input for whiptail
array=()
for line in "${lines[@]}"; do
	read name status <<< "$line"
	array+=("$name" "$status" "OFF")
done

# compose down only 
comp_down () {
	for d in "$@"; do
	cd "$d" && docker compose down && cd ..
done
echo "containers composed down"
}

# compose up only 
comp_up () {
	for d in "$@"; do
	cd "$d" && docker compose up -d && cd ..
done 
echo "containers composed up (detached)"
}

# compose down and back up
comp_both () {
	for d in "$@"; do
	cd "$d" && docker compose down && docker compose up -d && cd ..
done
echo "containers composed down & back up (detached)"
}

# whiptail function
selected=$(whiptail --title "Docker Helper V1" --checklist "Which Docker container do you want to change?" 20 78 10 \
	"${array[@]}" 3>&1 1>&2 2>&3)

# selection array
clean_str=$(echo "$selected" | tr -d '"')
selec_arr=($clean_str)

# whiptail function menu 
comp_choice=$(whiptail --title "Compose Menu" --menu "What would you like to do to the selected container?" 20 78 10 \
	"Down" "Compose Down" \
	"Up" "Compose Up" \
	"Both" "Compose Down & Back Up -d" 3>&1 1>&2 2>&3)

# case function 
case $comp_choice in 
	Down) comp_down "${selec_arr[@]}" ;;
	Up) comp_up "${selec_arr[@]}" ;;
	Both) comp_both "${selec_arr[@]}" ;;
esac