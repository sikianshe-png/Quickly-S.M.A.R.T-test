#!/bin/bash
# This shell script is for a simple S.M.A.R.T. test using smartctl.
# Latest version is "v0.3".

# To get real location of the script.
real_Local="$(readlink -f $0)"

# You should be ROOT.
if [[ "$EUID" -ne 0 ]]; then
	echo "Worning, You aren't ROOT, Please use sudo promise."
	read -n 1 -r -p "You can Entry [N] or [n] to keep the promise you own, and you can entry other key to try sudo promise." user_choice

		if [[ "$user_choice" == "n" || "$user_choice" == "N" ]]; then
			echo "---===> Cancel."
    		else
		         echo "---===> Entry sudo password."
	        	exec sudo bash "$real_Local" "$@"
    		fi
fi

terminal_Wid=$(tput cols)
printf "%${terminal_Wid}s\n" | tr " " "="

function list_All_Disk_Func {
	lsblk -d -o NAME | grep -E "sd|nvme"
}

list_by_id=$(list_All_Disk_Func)

if [[ -z "$list_by_id" ]] ; then
	echo "Even one disk wasn't found."
	echo "May be somethings be wrong there?"
	exit 1
else
    echo "You have disk, listing..."
    echo "$list_by_id"
fi

#Print a line on a row of the screen.
printf "%${terminal_Wid}s\n" | tr " " "-"


for dev in $list_by_id; do

	smart_Info="$(smartctl -i "/dev/$dev")"

	if [[ $? -ne 0 ]]; then
		echo "--- W A R N I N G --- ~~~~~~> Can't read /dev/$dev S.M.A.R.T info, skip it."
		printf "%${terminal_Wid}s\n" | tr " " "x"
		continue
	fi

	echo "===>>>    S.M.A.R.T. INFO TAKED.   <<<==="
    echo "===>>>    Processing /dev/$dev.    <<<==="

	if [[ "$dev" == "nvme"* ]]; then
		echo "--- NOTICE --- ~~~~~~> Device /dev/"$dev" try to runtime in long test."
	elif [[ "$dev" == "sd"* ]]; then
		if echo "$smart_Info" | grep -q "SMART support is: Available" ; then
			echo "--- N O T I C E --- ~~~~~~> Device /dev/"$dev" will attempt to run a long test."
		else
			echo "--- W A R N I N G --- ~~~~~~> /dev/$dev unsupported by S.M.A.R.T, skip it."
			continue
		fi
	else
		echo "Have unknown erorr."
		continue
	fi

	smartctl -t long "/dev/$dev" >/dev/null 2>&1

	if [[ $? -eq 0 ]]; then
		echo "--- F I N E --- ~~~~~~> Runtime OK."
	else
		echo "--- W A R N I N G --- ~~~~~~> Runtime Wrong."
	fi

	printf "%${terminal_Wid}s\n" | tr " " "="
	#================================================

done

sudo -k
