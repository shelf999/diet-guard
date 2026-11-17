# 语音识别模型（不入库）

这个目录用来放 [Vosk](https://alphacephei.com/vosk/) 的中文小模型，约 66MB，
体积太大不适合提交到 Git，请用脚本下载：

```bash
bash scripts/fetch-asr-model.sh
```

下载完成后目录应该是：

```
asr/vosk-model-small-cn/
├── am/
├── conf/
├── graph/
└── ivector/
```

如果脚本在你的网络下拿不到，也可以手动下载
`vosk-model-small-cn-0.22.zip`
（[官方源](https://alphacephei.com/vosk/models) /
[国内镜像](https://hf-mirror.com/guloooovoooo/vosk-model-small-cn)），
解压后把文件夹重命名为 `vosk-model-small-cn` 放到这里。

没有模型时网页仍能正常打开，只是「按住说话」会提示识别服务不可用，
可以直接用键盘输入。
