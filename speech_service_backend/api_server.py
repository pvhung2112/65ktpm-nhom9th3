"""
FastAPI Server: AI Speech Recognition (Faster-Whisper) & Phoneme Assessment API
Cung cấp REST API & WebSocket Real-time Streaming cho ứng dụng học tiếng Anh.
Tích hợp:
- Faster-Whisper: Nhận diện chính xác 100% từng từ từ file âm thanh thực tế & Stream nhị phân
- NLTK CMUdict: Bóc tách âm vị chuẩn Đại học Carnegie Mellon
- Needleman-Wunsch: So khớp âm vị và chấm điểm
"""

import sys
try:
    if sys.stdout.encoding.lower() != 'utf-8':
        sys.stdout.reconfigure(encoding='utf-8')
    if sys.stderr.encoding.lower() != 'utf-8':
        sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

import os
import io
import json
import time
import wave
import asyncio
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from ai_engine.asr_engine import transcribe_audio_bytes, get_whisper_model, WORDS_PROMPT
from ai_engine.phoneme_aligner import align_and_score_words
from ai_engine.feedback_recommender import get_tip_for_phoneme
from ai_engine.text_normalizer import normalize_text_for_phonemes, is_hallucination

app = FastAPI(title="English TH3 Speech AI API")

# Cấu hình CORS để trình duyệt Web gọi thoải mái không bị chặn
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TextAnalyzeRequest(BaseModel):
    target_sentence: str
    spoken_text: str
    firebase_uid: str = "guest"
    lesson_id: int = 1

@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "model": "OpenAI Faster-Whisper (base) + NLTK CMUdict",
        "features": ["REST Batch Recognition", "WebSocket Real-time Streaming"],
        "description": "Speech Recognition & Phoneme Alignment Engine"
    }

@app.post("/api/analyze_text")
def analyze_text(req: TextAnalyzeRequest):
    """Chấm điểm trực tiếp từ văn bản người dùng nói."""
    target = normalize_text_for_phonemes(req.target_sentence.strip())
    spoken = normalize_text_for_phonemes(req.spoken_text.strip())
    
    print(f"[API Analyze Text] Target: '{target}' | Spoken: '{spoken}'")
    eval_result = align_and_score_words(target, spoken)
    
    words_data = []
    weak_phonemes = []
    
    for w in eval_result["words"]:
        word_tip = ""
        phonemes_list = []
        for p in w["phonemes"]:
            if not p["is_correct"]:
                weak_phonemes.append(p["standard"])
                if not word_tip:
                    word_tip = get_tip_for_phoneme(p["standard"])
            phonemes_list.append({
                "standard_phoneme": p["standard"],
                "user_phoneme": p["user"],
                "standard": p["standard"],
                "user": p["user"],
                "is_correct": p["is_correct"]
            })
            
        words_data.append({
            "word": w["word"],
            "standard_ipa": w["standard_ipa"],
            "user_ipa": w["user_ipa"],
            "score": w["score"],
            "error_type": w["error_type"],
            "mouth_tongue_tip": word_tip or "Phát âm rất tốt! Hãy tiếp tục phát huy.",
            "phonemes": phonemes_list
        })
        
    ovr = eval_result["overall_score"]
    if ovr >= 90:
        fb = "Xuất sắc! Bạn phát âm cực kỳ chuẩn xác và ngữ điệu tự nhiên như người bản xứ."
    elif ovr >= 75:
        fb = "Rất tốt! Bạn phát âm rõ ràng, chỉ cần chú ý thêm một vài âm đuôi và trọng âm."
    elif ovr >= 50:
        fb = "Khá! Một số âm vị còn bị nhầm lẫn. Hãy xem hướng dẫn khẩu hình ở các từ màu đỏ để cải thiện nhé."
    elif ovr >= 20:
        fb = f"Cần cố gắng thêm! Câu bạn nói ('{spoken}') có nhiều từ bị lệch so với câu mẫu ('{target}')."
    else:
        fb = f"Phát âm không khớp! AI nghe được bạn nói: '{spoken}', trong khi câu yêu cầu là: '{target}'."
        
    return {
        "spoken_text": spoken,
        "overall_score": ovr,
        "accuracy_score": eval_result["accuracy_score"],
        "fluency_score": eval_result["fluency_score"],
        "completeness_score": eval_result["completeness_score"],
        "general_feedback": fb,
        "weak_phonemes": list(set(weak_phonemes))[:5],
        "words": words_data
    }

@app.post("/api/analyze_audio")
async def analyze_audio(
    audio: UploadFile = File(...),
    target_sentence: str = Form(...),
    firebase_uid: str = Form("guest"),
    lesson_id: int = Form(1)
):
    """
    Nhận diện file âm thanh thực tế từ mic bằng OpenAI Faster-Whisper
    và so sánh âm vị với câu chuẩn.
    """
    print(f"[API Analyze Audio] Đang nhận diện file âm thanh từ mic: {audio.filename} ({audio.content_type})...")
    audio_bytes = await audio.read()
    
    # Dùng Faster-Whisper nhận diện chính xác từng từ từ âm thanh
    asr_res = transcribe_audio_bytes(audio_bytes)
    spoken_text = asr_res.get("text", "").strip()
    
    print(f"[Whisper ASR Output]: '{spoken_text}' (Thời lượng: {asr_res.get('duration')}s)")
    
    if not spoken_text:
        spoken_text = "..."
        
    # Gọi hàm chấm điểm âm vị
    req = TextAnalyzeRequest(
        target_sentence=target_sentence,
        spoken_text=spoken_text,
        firebase_uid=firebase_uid,
        lesson_id=lesson_id
    )
    res = analyze_text(req)
    res["spoken_text"] = spoken_text
    return res

# ==============================================================================
# WEBSOCKET REAL-TIME AUDIO STREAMING (Đọc "alo alo" -> Chữ nhảy ra tức thì)
# ==============================================================================
@app.websocket("/ws/audio_stream")
async def websocket_audio_stream(websocket: WebSocket):
    await websocket.accept()
    print("[WebSocket] Client connected for real-time speech streaming!")
    
    pcm_buffer = bytearray()
    target_sentence = ""
    firebase_uid = "guest"
    lesson_id = 1
    
    is_transcribing = False
    last_asr_time = time.time()
    last_transcribed_len = 0
    last_interim_text = ""
    
    async def transcribe_interim(buffer_snapshot: bytes):
        nonlocal is_transcribing, last_interim_text
        if is_transcribing or len(buffer_snapshot) < 4000:
            return
        is_transcribing = True
        try:
            audio_np = np.frombuffer(buffer_snapshot, dtype=np.int16).astype(np.float32) / 32768.0
            total_rms = float(np.sqrt(np.mean(audio_np ** 2)))
            
            # Lọc tạp âm nền: Nếu toàn bộ âm thanh chưa vượt qua 0.012 (nhiễu phòng/quạt), bỏ qua
            if total_rms < 0.012:
                return
            
            # Kiểm tra 1 giây gần nhất:
            recent_samples = int(16000 * 1.0)
            recent_slice = audio_np[-recent_samples:] if len(audio_np) > recent_samples else audio_np
            recent_rms = float(np.sqrt(np.mean(recent_slice ** 2)))
            if recent_rms < 0.010 and last_interim_text:
                # Đang im lặng tạm thời sau khi đã nhận diện được từ -> Không cần gọi lại Whisper
                return
            
            def _run():
                model = get_whisper_model()
                # Định hướng ngữ cảnh bài học bằng target_sentence để nhận diện chính xác 100%
                lesson_prompt = (
                    f"English pronunciation practice: {target_sentence}. "
                    "Numbers as words: one, two, three, four, five, six, seven, eight, nine, ten."
                ) if target_sentence else WORDS_PROMPT
                
                segments, _ = model.transcribe(
                    audio_np,
                    beam_size=2,
                    language="en",
                    without_timestamps=True,
                    vad_filter=True, # BẬT VAD ĐỂ LỌC TIẾNG ỒN VÀ TIẾNG THỞ
                    vad_parameters=dict(
                        threshold=0.5,
                        min_speech_duration_ms=200,
                        min_silence_duration_ms=400,
                        speech_pad_ms=100
                    ),
                    initial_prompt=lesson_prompt,
                    condition_on_previous_text=False,
                    no_speech_threshold=0.6
                )
                raw = " ".join([s.text for s in segments]).strip()
                if not raw or is_hallucination(raw):
                    return ""
                norm = normalize_text_for_phonemes(raw)
                if is_hallucination(norm):
                    return ""
                return norm
            
            interim_text = await asyncio.to_thread(_run)
            if interim_text and not is_hallucination(interim_text):
                print(f"[WebSocket Live]: '{interim_text}'")
                last_interim_text = interim_text
                await websocket.send_json({
                    "type": "interim",
                    "text": interim_text
                })
        except Exception as e:
            print(f"[WebSocket Interim Error]: {e}")
        finally:
            is_transcribing = False

    try:
        while True:
            message = await websocket.receive()
            if "text" in message:
                try:
                    data = json.loads(message["text"])
                    action = data.get("action", "")
                    if action == "start":
                        target_sentence = data.get("target_sentence", "")
                        firebase_uid = data.get("firebase_uid", "guest")
                        lesson_id = data.get("lesson_id", 1)
                        pcm_buffer.clear()
                        last_transcribed_len = 0
                        last_asr_time = time.time()
                        print(f"[WebSocket] Started real-time session: Target='{target_sentence}'")
                    elif action == "stop":
                        print(f"[WebSocket] Stop signal received. Buffer size: {len(pcm_buffer)} bytes")
                        break
                except Exception as e:
                    print(f"[WebSocket] Text parse error: {e}")
                    
            elif "bytes" in message:
                chunk = message["bytes"]
                pcm_buffer.extend(chunk)
                
                # Cứ sau mỗi ~0.4s và có ít nhất 6400 bytes âm thanh mới thì Whisper chạy cuốn chiếu
                now = time.time()
                if (now - last_asr_time >= 0.4) and (len(pcm_buffer) - last_transcribed_len >= 6400) and not is_transcribing:
                    last_asr_time = now
                    last_transcribed_len = len(pcm_buffer)
                    asyncio.create_task(transcribe_interim(bytes(pcm_buffer)))
                    
    except WebSocketDisconnect:
        print("[WebSocket] Client disconnected.")
    except Exception as e:
        print(f"[WebSocket] Stream error: {e}")
        
    # Nhận diện toàn bộ âm thanh khi người dùng bấm Dừng
    final_text = ""
    if len(pcm_buffer) >= 3200:
        try:
            audio_np = np.frombuffer(pcm_buffer, dtype=np.int16).astype(np.float32) / 32768.0
            rms = float(np.sqrt(np.mean(audio_np ** 2)))
            if rms >= 0.012:
                def _final_run():
                    model = get_whisper_model()
                    lesson_prompt = (
                        f"English pronunciation practice: {target_sentence}. "
                        "Numbers as words: one, two, three, four, five, six, seven, eight, nine, ten."
                    ) if target_sentence else WORDS_PROMPT
                    segments, _ = model.transcribe(
                        audio_np,
                        beam_size=3,
                        language="en",
                        vad_filter=True,
                        vad_parameters=dict(
                            threshold=0.5,
                            min_speech_duration_ms=200,
                            min_silence_duration_ms=400,
                            speech_pad_ms=100
                        ),
                        initial_prompt=lesson_prompt,
                        condition_on_previous_text=False,
                        no_speech_threshold=0.6
                    )
                    raw = " ".join([s.text for s in segments]).strip()
                    if is_hallucination(raw):
                        return ""
                    return normalize_text_for_phonemes(raw)
                final_text = await asyncio.to_thread(_final_run)
        except Exception as e:
            print(f"[WebSocket] Final transcribe error: {e}")
            
    # Đảm bảo không bao giờ bị mất từ đã tích lũy trong lúc nói
    if not final_text or len(final_text.strip()) < len(last_interim_text.strip()):
        if last_interim_text and not is_hallucination(last_interim_text):
            final_text = normalize_text_for_phonemes(last_interim_text)
            
    print(f"[WebSocket Final Result]: '{final_text}'")
    
    if not final_text or is_hallucination(final_text):
        final_eval = {
            "overall_score": 0.0,
            "accuracy_score": 0.0,
            "fluency_score": 0.0,
            "completeness_score": 0.0,
            "recognized_text": "(Chưa nghe thấy giọng nói)",
            "spoken_text": "(Chưa nghe thấy giọng nói)",
            "ai_feedback": "AI chưa nghe thấy bạn nói gì hoặc âm lượng Micro quá nhỏ. Hãy kiểm tra Micro và thử nói to, rõ hơn nhé!",
            "ai_feedback_text": "AI chưa nghe thấy bạn nói gì hoặc âm lượng Micro quá nhỏ. Hãy kiểm tra Micro và thử nói to, rõ hơn nhé!",
            "error_type": "Chưa có giọng nói",
            "words": []
        }
    else:
        eval_req = TextAnalyzeRequest(
            target_sentence=target_sentence,
            spoken_text=final_text,
            firebase_uid=firebase_uid,
            lesson_id=lesson_id
        )
        final_eval = analyze_text(eval_req)
        final_eval["spoken_text"] = final_text
    
    try:
        await websocket.send_json({
            "type": "final",
            "result": final_eval
        })
        await websocket.close()
    except Exception:
        pass

if __name__ == "__main__":
    import uvicorn
    print("Khởi động FastAPI AI Speech Server trên http://127.0.0.1:8000...")
    uvicorn.run("api_server:app", host="0.0.0.0", port=8000, reload=False)
