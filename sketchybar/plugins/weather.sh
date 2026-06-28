#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

weather_json=$(curl -s --max-time 5 "wttr.in/?format=j1")
parsed=$(printf '%s' "$weather_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
area = data.get("nearest_area", [{}])[0]
current = data.get("current_condition", [{}])[0]

place = area.get("areaName", [{}])[0].get("value", "")
country = area.get("country", [{}])[0].get("value", "")
region = area.get("region", [{}])[0].get("value", "")
temp = current.get("temp_C", "")
desc = current.get("weatherDesc", [{}])[0].get("value", "")

jp_places = {
    "Tokyo": "東京", "Osaka": "大阪", "Kyoto": "京都", "Yokohama": "横浜",
    "Sapporo": "札幌", "Fukuoka": "福岡", "Nagoya": "名古屋", "Kobe": "神戸",
    "Sendai": "仙台", "Hiroshima": "広島", "Naha": "那覇",
    "Hokkaido": "北海道", "Aomori": "青森", "Iwate": "岩手", "Miyagi": "宮城",
    "Akita": "秋田", "Yamagata": "山形", "Fukushima": "福島", "Ibaraki": "茨城",
    "Tochigi": "栃木", "Gunma": "群馬", "Saitama": "埼玉", "Chiba": "千葉",
    "Kanagawa": "神奈川", "Niigata": "新潟", "Toyama": "富山", "Ishikawa": "石川",
    "Fukui": "福井", "Yamanashi": "山梨", "Nagano": "長野", "Gifu": "岐阜",
    "Shizuoka": "静岡", "Aichi": "愛知", "Mie": "三重", "Shiga": "滋賀",
    "Hyogo": "兵庫", "Nara": "奈良", "Wakayama": "和歌山", "Tottori": "鳥取",
    "Shimane": "島根", "Okayama": "岡山", "Yamaguchi": "山口", "Tokushima": "徳島",
    "Kagawa": "香川", "Ehime": "愛媛", "Kochi": "高知", "Saga": "佐賀",
    "Nagasaki": "長崎", "Kumamoto": "熊本", "Oita": "大分", "Miyazaki": "宮崎",
    "Kagoshima": "鹿児島", "Okinawa": "沖縄",
}

if country == "Japan":
    place = jp_places.get(place) or jp_places.get(region) or place

if temp:
    temp = f"+{temp}°C" if not temp.startswith("-") else f"{temp}°C"

print("|".join([place, temp, desc]))
' 2>/dev/null)

IFS='|' read -r place temp cond <<< "$parsed"

if [ -z "$temp" ]; then
  sketchybar --set "$NAME" icon="󰖐" label="--"
  exit 0
fi

case "$cond" in
  *Sunny* | *Clear*)        icon="󰖙" ;;
  *Partly*)                 icon="󰖕" ;;
  *Cloud* | *Overcast*)     icon="󰖐" ;;
  *Rain* | *Drizzle*)       icon="󰖗" ;;
  *Hail* | *Sleet*)         icon="󰖒" ;;
  *Snow*)                   icon="󰖘" ;;
  *Thunder*)                icon="󰖓" ;;
  *Fog* | *Mist*)           icon="󰖑" ;;
  *)                        icon="󰖐" ;;
esac

sketchybar --set "$NAME" icon="$icon" icon.color="$TEAL" label="$place ${temp// /}"
