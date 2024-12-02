    
sda_path="/dev/block/by-name/userdata"
mkdir_block () {
	block="$(ls -l "$1" | awk '{print $10}')"
	block_name="${block##*/}"
	block_num="$(echo "$block" | tr -cd "[0-9]")"
	disk="$(echo "$block_name" | tr -cd "[a-z]")"
	size="$(cat "/proc/partitions" | grep -w "$block_name" | tr -s [:space:] | cut -d ' ' -f 4)"
	guid_code="$(sgdisk /dev/block/$disk --info=$block_num | tr '\n' ' ' | cut -d ' ' -f 4)"
	echo "$block_name $block_num $disk $size $guid_code"
	block_info="$(sgdisk "/dev/block/$disk" --print | grep "${sda_path##*/}" | awk '{print $(NF-6),$(NF-3)$(NF-2),$(NF)}')"
	echo "目前剩余$(echo "$block_info" | awk '{print $2}')未分配"
	echo "開始備份分區表 請妥善保管"
	sgdisk /dev/block/sda --backup=/data/media/0/sda.bin
	[[ $? = 0 ]] && echo "備份成功 路徑:/sdcard/sda.bin 這文件千萬別丟了 將來恢復分區用"
	while true ;do
		if [[ $option != "" ]]; then
			break
		else
			echo "請輸入虛擬SD分區名稱"
			read option
		fi
	done
	echo "請輸入$option需要的分区大小(單位Gib)"
	while true ;do
		if [[ $(echo "$new_size" | sed "s/\..*//g") -gt 0 ]]; then
			percentage="$((new_size * 100 / $(echo "$block_info" | awk '{print $2}' | sed "s/\..*//g")))"
			if [[ $percentage -ge 70 ]]; then
				echo "不能超過總分區大小70% 你目前的選擇達到${percentage}%\n请重新输入您预留给$option的分区大小(單位Gib)"
				read new_size
			else
				echo "你輸入的分區大小為${new_size}Gib\n確認嗎？"
				read yes_info
				if [[ $yes_info == yes ]]; then
					#刪除分區
					echo "/dev/block/$disk" --delete="$block_num"
					#sgdisk "/dev/block/$disk" --delete="$block_num"
					#創建虛擬sd分區
					echo "/dev/block/$disk" --new="$((block_num+1)):0:+${new_size}Gib" --change-name="$((block_num+1)):$option"
					#sgdisk "/dev/block/$disk" --new="$((block_num+1)):0:+${new_size}Gib" --change-name="$((block_num+1)):$option"
					echo "重啟後終端輸入mke2fs -t ext4 /dev/block/$disk$((block_num+1))"
					#創建userdata分區
					echo "/dev/block/$disk" --new="$block_num:0:+0" --change-name="$block_num:${sda_path##*/}"
					#sgdisk "/dev/block/$disk" --new="$block_num:0:+0" --change-name="$block_num:${sda_path##*/}"
					echo "自動填補${sda_path##*/}分區大小為$(($(echo "$block_info" | awk '{print $2}' | sed "s/\..*//g") - new_size))Gib"
					echo "請在twrp格式化data分區後重啟執行上述操作"
					break
				else
					echo "重新輸入"
					read new_size
				fi
			fi
		else
			echo 请输入数字（大于0的纯数字，不可为小数）
			wait ; read new_size
			#clear
		fi
	done
}
echo "輸入1開始分區 並備份分區表 2恢復分區表"
read ABI
case $ABI in
1)
	if [[ $(find "$sda_path") != "" ]]; then
		mkdir_block "$sda_path"
	fi
	;;
2)
	if [[ -f /data/media/0/sda.bin ]]; then
		sgdisk /dev/block/sda --load-backup=/data/media/0/sda.bin
		[[ $? ]] && echo "恢復成功 重啟後使用原始分區表 你的資料將遺失 請做好備份"
	else
		echo "請將分區檔案sda.bin移動到/data/media/0/後再次執行本腳本"
	fi
	;;
esac