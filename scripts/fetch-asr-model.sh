#!/usr/bin/env bash
# 下载中文语音识别模型（vosk-model-small-cn，约 42MB 压缩 / 66MB 解压）
# 用法：bash scripts/fetch-asr-model.sh
set -e
cd "$(dirname "$0")/.."

URL_CN="https://hf-mirror.com/guloooovoooo/vosk-model-small-cn/resolve/main/vosk-model-small-cn.zip"
URL_INTL="https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip"
ZIP="asr/vosk-model-small-cn.zip"

mkdir -p asr

if [ -d asr/vosk-model-small-cn ]; then
  echo "模型已存在：asr/vosk-model-small-cn，无需重复下载"
  exit 0
fi

echo "==> 下载模型（国内镜像，失败再换官方源）"
if ! curl -fL --retry 2 --connect-timeout 20 -o "$ZIP" "$URL_CN"; then
  echo "镜像不可用，改用官方源（可能较慢）"
  curl -fL --retry 2 -o "$ZIP" "$URL_INTL"
fi

echo "==> 解压"
unzip -q -o "$ZIP" -d asr/
# 压缩包里目录名可能是 vosk-model-small-cn-0.22，统一改名
if [ ! -d asr/vosk-model-small-cn ]; then
  for d in asr/vosk-model-small-cn*; do
    [ -d "$d" ] && mv "$d" asr/vosk-model-small-cn && break
  done
fi
rm -f "$ZIP"

echo "==> 完成：$(du -sh asr/vosk-model-small-cn | cut -f1)  $(ls asr/vosk-model-small-cn)"
