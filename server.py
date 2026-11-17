#!/usr/bin/env python3
"""饮食管家 —— 静态页面 + 本地中文语音识别服务（不依赖任何外部 API）

POST /api/asr   请求体为 WAV（16k / 单声道 / 16bit PCM），返回 {"text": "..."}
GET  /api/health 返回识别服务状态
"""
import io
import json
import os
import threading
import wave
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "asr", "vosk-model-small-cn")

_model = None
_model_error = None
_model_lock = threading.Lock()


def get_model():
    """懒加载识别模型（首次请求时加载，约 1-2 秒）"""
    global _model, _model_error
    if _model is not None:
        return _model
    with _model_lock:
        if _model is not None:
            return _model
        if _model_error:
            raise RuntimeError(_model_error)
        try:
            from vosk import Model, KaldiRecognizer, SetLogLevel  # noqa: F401
            SetLogLevel(-1)
            if not os.path.isdir(MODEL_DIR):
                raise RuntimeError("模型目录不存在: " + MODEL_DIR)
            _model = Model(MODEL_DIR)
        except Exception as exc:  # 模型不可用时也不要拖垮整站
            _model_error = str(exc)
            raise
    return _model


def transcribe(wav_bytes):
    """把 WAV 字节流转成中文文字"""
    from vosk import KaldiRecognizer
    model = get_model()
    wf = wave.open(io.BytesIO(wav_bytes), "rb")
    if wf.getnchannels() != 1 or wf.getsampwidth() != 2:
        raise ValueError("需要单声道 16bit PCM 音频")
    rate = wf.getframerate()
    if rate < 8000 or rate > 48000:
        raise ValueError("采样率不支持")
    rec = KaldiRecognizer(model, rate)
    parts = []
    while True:
        data = wf.readframes(4000)
        if not data:
            break
        if rec.AcceptWaveform(data):
            parts.append(json.loads(rec.Result()).get("text", ""))
    parts.append(json.loads(rec.FinalResult()).get("text", ""))
    # 中文去掉 Vosk 输出的空格
    return "".join(parts).replace(" ", "")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    # ---------- 工具 ----------
    def _json(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        # 精简日志
        if self.path.startswith("/api/"):
            print("[api]", self.path, args[1] if len(args) > 1 else "", flush=True)

    # ---------- 路由 ----------
    def do_GET(self):
        if self.path.split("?")[0] == "/api/health":
            self._json(200, {"ok": _model is not None, "error": _model_error})
            return
        super().do_GET()

    def do_POST(self):
        if self.path.split("?")[0] != "/api/asr":
            self.send_error(404, "not found")
            return
        try:
            length = int(self.headers.get("Content-Length") or 0)
            if length <= 0 or length > 12 * 1024 * 1024:
                self._json(200, {"text": "", "error": "音频大小不合法"})
                return
            audio = self.rfile.read(length)
            text = transcribe(audio)
            self._json(200, {"text": text})
        except Exception as exc:
            self._json(200, {"text": "", "error": str(exc)[:200]})


def main():
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("服务启动于 0.0.0.0:%d" % port, flush=True)
    # 预热模型，避免第一次按住说话等待过久
    def warm():
        try:
            get_model()
            print("语音识别模型已就绪", flush=True)
        except Exception as exc:
            print("语音识别模型加载失败:", exc, flush=True)

    threading.Thread(target=warm, daemon=True).start()
    server.serve_forever()


if __name__ == "__main__":
    main()
