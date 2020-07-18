#!/bin/bash
langage=fr
period=week
limit=15
curl -H 'Accept: application/vnd.twitchtv.v5+json' \
        -H 'Client-ID: m1kawn1oluxmhcbt9jgky4gwk8birf' \
        -X GET "https://api.twitch.tv/kraken/clips/top?language=$langage&period=$period&trending=true&limit=$limit&game=League%20of%20Legends" > contain/weekly.json

nbr=0
until [ $nbr -eq $limit ]
do
        if [$(jq .clips[$nbr].created_at contain/weekly.json | cut -c -18) = $(jq .clips[$(($nbr + 1))].created_at contain/weekly.json | cut -c -18)] && [$(jq .clips[$nbr].broadcaster.name contain/weekly.json) = $(jq .clips[$(($nbr + 1))].broadcaster.name contain/weekly.json)]; then
        nbr=$(($nbr + 1))
        else
                wget -O contain/$nbr.mp4 https://clips-media-assets2.twitch.tv/AT-cm%7C$(jq .clips[$nbr].tracking_id contain/weekly.json | cut -c 2- | cut -c -9).mp4 || wget -O contain/$nbr.mp4 https://clips-media-assets2.twitch.tv/$(jq .clips[$nbr].broadcast_id contain/weekly.json | sed 's/"//g')-offset-$(jq .clips[$nbr].thumbnails.tiny contain/weekly.json | sed 's/.*-offset-//' | sed 's/-previe.*//').mp4


                echo "file 'temp$nbr.ts'" >> contain/concat.txt
                name=$(jq .clips[$nbr].broadcaster.display_name contain/weekly.json)
                titleclip=$(jq .clips[$nbr].title contain/weekly.json)
                view=$(jq .clips[$nbr].views contain/weekly.json)
                final="#$(($nbr + 1)) $name - $titleclip - $view vues"
                ffmpeg -i contain/$nbr.mp4 -vf drawtext="fontfile=/path/to/font.ttf: text=$final: fontcolor=white: fontsize=32: box=1: boxcolor=black@0.5: boxborderw=5: x=10:y=10" -codec:a copy contain/edit$nbr.mp4
                ffmpeg -i contain/edit$nbr.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts contain/temp$nbr.ts
                nbr=$(($nbr + 1))
        fi
done
tac contain/concat.txt > contain/contac.txt
ffmpeg -f concat -i contain/contac.txt -c copy /mnt/c/Users/faroke/Desktop/output.mp4
rm contain/*
python upload/upload_video.py --file="/mnt/c/Users/faroke/Desktop/output.mp4" --title="test" --privacyStatus="unlisted" --noauth_local_webserver
exit 0
