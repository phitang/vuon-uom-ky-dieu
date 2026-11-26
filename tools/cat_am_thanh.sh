#!/bin/sh
# Cắt âm thanh hiệu ứng cho mini game Phòng thủ từ 3 tệp gốc (cần ffmpeg).
# Chạy trong thư mục chứa dansao.mp3, gaixuongrong.mp3, tualipbonghong.mp3:
#   sh cat_am_thanh.sh <thư mục dự án>/am_thanh
O=${1:-am_thanh}
mkdir -p "$O"
ff() { ffmpeg -v error -y "$@"; }
# Hoa sao: tiếng "piu" thứ nhất, bắt đầu gần đỉnh để bắn nghe tức thì
ff -i dansao.mp3 -af "atrim=0.15:0.32,asetpts=PTS-STARTPTS,afade=t=in:d=0.01,afade=t=out:st=0.12:d=0.05,loudnorm=I=-16:TP=-2,aresample=24000" -ac 1 -c:a pcm_s16le "$O/dan_sao.wav"
# Hoa sen: tiếng thứ hai, hạ giọng và làm mềm cho giống tia nước
ff -i dansao.mp3 -af "atrim=0.42:0.66,asetpts=PTS-STARTPTS,asetrate=24000*0.72,aresample=24000,lowpass=f=2600,afade=t=in:d=0.01,afade=t=out:st=0.24:d=0.08,loudnorm=I=-17:TP=-2,aresample=24000" -ac 1 -c:a pcm_s16le "$O/tia_nuoc.wav"
# Xương rồng: tiếng gai to nhất
ff -i gaixuongrong.mp3 -af "atrim=0.66:0.82,asetpts=PTS-STARTPTS,afade=t=in:d=0.005,afade=t=out:st=0.11:d=0.05,loudnorm=I=-15:TP=-2,aresample=24000" -ac 1 -c:a pcm_s16le "$O/gai.wav"
# Chuồn chuồn: cùng tiếng gai, cao giọng và nhỏ hơn
ff -i gaixuongrong.mp3 -af "atrim=0.66:0.80,asetpts=PTS-STARTPTS,asetrate=24000*1.3,aresample=24000,afade=t=out:st=0.08:d=0.03,loudnorm=I=-20:TP=-3,aresample=24000" -ac 1 -c:a pcm_s16le "$O/gai_chuon.wav"
# Tulip (địch chạm vùng làm chậm) và dây gai hoa hồng: dùng nguyên tiếng
ff -i tualipbonghong.mp3 -af "afade=t=out:st=0.66:d=0.15,loudnorm=I=-17:TP=-2,aresample=24000" -ac 1 -c:a pcm_s16le "$O/tulip_hong.wav"
