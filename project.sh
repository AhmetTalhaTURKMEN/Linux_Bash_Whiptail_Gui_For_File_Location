#!/bin/bash

col=$(tput cols) #genislik

row=$(tput lines) #yukseklik

LOCATION=$(whiptail --fb --menu "" --title "Dosya adini nerede arayacaksiniz?" $(($row * 30 / 100)) $(($col * 90 / 100)) 0 \
	"home" "|Aramayi tum kullanicilarin klasorlerinde yapacagim !Dikkat! sudo sifresi gerekir!" \
	"$USER" "|Aramayi $USER klasorunde yapacagim" 3>&1 1>&2 2>&3)
if [ -z "$LOCATION" ]; then #LOCATION degiskeni bos mu? 
	whiptail --fb --title "Cancel" --msgbox "" $(($row * 40 / 100)) $(($col * 40 / 100))
else
	until [[ ${#NAME} -gt '2' ]]; do #burada kullanicidan alinan NAME girdisinin 2 harften fazla ise dongu kirilir
		NAME=$(whiptail --fb --inputbox "" --title "Aramak istediginiz dosya adini giriniz" $(($row * 30 / 100)) $(($col * 90 / 100)) 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			echo "" >/dev/null
		else
			whiptail --fb --title "Cancel" --msgbox "" $(($row * 40 / 100)) $(($col * 40 / 100))
			break
		fi
	done
	if [ ${#NAME} -ne '0' ]; then #girdi bos degil mi?
		 SEARCHOPTION=$(whiptail --fb --menu "$NAME dosyasini ne sekilde arayacaksiniz? " $(($row * 80 / 100)) $(($col * 90 / 100)) 0 \
			"1" "$NAME ile baslayanlari yazdir" \
			"2" "$NAME ile bitenleri yazdir" \
			"3" "Iceriginde $NAME bulunduranlari yazdir" \
			"4" "Adi sadece $NAME olanlari yazdir" 3>&1 1>&2 2>&3)

		if [ -z "$SEARCHOPTION" ]; then  #bos olmasi demek cancel butonuna basilmis demektir
			whiptail --fb --title "Cancel" --msgbox "" $(($row * 40 / 100)) $(($col * 40 / 100))
		else
			SEARCHOPTION2=$(whiptail --fb --menu "$NAME dosyasini ne sekilde arayacaksiniz? " $(($row * 80 / 100)) $(($col * 90 / 100)) 0 \
				"name" "buyuk kucuk harf algisi olsun" \
				"iname" "buyuk kucuk harf algisi olmasin" 3>&1 1>&2 2>&3)
			if [ -z "$SEARCHOPTION2" ]; then
				whiptail --fb --title "Cancel" --msgbox "" $(($row * 40 / 100)) $(($col * 40 / 100))
			else
				if [ $SEARCHOPTION -eq '1' ]; then
					FINDNAME="$NAME*"
				elif [ $SEARCHOPTION -eq '2' ]; then
					FINDNAME="*$NAME"
				elif [ $SEARCHOPTION -eq '3' ]; then
					FINDNAME="*$NAME*"
				elif [ $SEARCHOPTION -eq '4' ]; then
					FINDNAME="$NAME"
				fi
				if [ $LOCATION == $USER ]; then #eger arama user altinda yapilacaksa
					cd $pwd                        #kullanici secildigine gore islem kullanicinin klasoru icinde yapilacak
					permissionerr=$(find . -type f -$SEARCHOPTION2 "$FINDNAME" 2>&1 >/dev/null)
					if [ ${#permissionerr} -ne '0' ]; then #erisilemeyen dosyalari yazdiran if dongusu #kullanici hangi dosyalarda arama yapilamadigini bilmesini saglar
						whiptail --fb --title "Alttaki dosyalarda erisim izni olmadigi icin bu dosya iceriklerine bakilamadi" --msgbox --scrolltext "$permissionerr" $(($row * 80 / 100)) $(($col * 90 / 100))
					fi
					result=$(find . -type f -$SEARCHOPTION2 "$FINDNAME" 2> >(grep -v 'Permission denied' >&2)) #erisim izni olmayan dosyalarda arama yaparken permission denied hatasini gizler
				else  #LOCATION $USER degilse geriye tek secenek kaldi o da LOCATION'UN home olmasi
					cd $HOME/..             #kullanici secilmedi geriye home kaldi o zaman home altinda yap
					prompt=$(sudo -nv 2>&1) #sudo sifresi daha once girilmis mi ? sudo sifresi girildi ise sudo -nv 0 dondurur sudo sifresi girilmemisse bir string dondurur
					if [ $? -eq 0 ]; then
						whiptail --fb --msgbox "Zaten sudo sifresini daha onceki kullanimda girdiniz" 10 60
					elif echo $prompt | grep -q '^sudo:'; then
						psw=$(whiptail --fb --title "Sudo Password Box" --passwordbox "Sudo sifresini giriniz." 10 60 3>&1 1>&2 2>&3)
					fi
					exitstatus2=$?
					if [ $exitstatus2 = 0 ]; then
						result=$(sudo -S find . -type f -$SEARCHOPTION2 "$FINDNAME" <<<$psw)
					else
						whiptail --fb --title "Cancel" --msgbox "" $(($row * 40 / 100)) $(($col * 40 / 100)) #islevi yok
					fi
				fi
				resultlength=${#result}                  #result'un karakter sayisini tutuyor
				if [ $resultlength -ne '0' ]; then       # boyle bir dosya bulundu mu?
					if [ $resultlength -lt '120000' ]; then #karakter sayisi 120000'den kucuk ise #bu sinirlamayi koyma sebebim msgbox 120000 karakterden fazlasinda hata veriyor
						#hem kullanilan *** gibi operatorlerde sikinti yaratmasini engellemek
						whiptail --fb --msgbox --scrolltext "$result" $(($row * 80 / 100)) $(($col * 90 / 100))
					else
						whiptail --fb --msgbox "cok fazla arguman var ($resultlength char) Lutfen daha net bir ifade girin" 10 100
					fi
				else
					whiptail --fb --msgbox "Boyle bir dosya yok veya sudo sifresini yanlis girdiniz" 10 100
				fi
			fi
		fi
	fi
fi