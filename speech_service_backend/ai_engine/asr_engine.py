"""
Module ASR Engine:
Nhận diện giọng nói từ âm thanh sử dụng mô hình Whisper (faster-whisper).
Xử lý audio bytes và trích xuất chữ kèm mốc thời gian (word-level timestamps).
"""

import sys
try:
    if sys.stdout.encoding.lower() != 'utf-8':
        sys.stdout.reconfigure(encoding='utf-8')
    if sys.stderr.encoding.lower() != 'utf-8':
        sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

import io
import os
import tempfile
import wave
from faster_whisper import WhisperModel
from .text_normalizer import normalize_text_for_phonemes, is_hallucination

WORDS_PROMPT = (
    "Transcribe spoken English strictly as words. "
    "Always spell out numbers as English words: one, two, three, four, five, six, seven, eight, nine, ten, "
    "eleven, twelve, thirteen, fourteen, fifteen, sixteen, seventeen, eighteen, nineteen, twenty, thirty, "
    "forty, fifty, sixty, seventy, eighty, ninety, hundred, thousand, million. "
    "Do not write digits or numbers like 1, 2, 3, 3000."
)

_model = None

def get_whisper_model():
    """Tải và cache mô hình Whisper (dùng bản base nhỏ nhẹ ~70MB, chạy nhanh trên CPU)."""
    global _model
    if _model is None:
        print("[ASR Engine] Đang khởi tạo mô hình Whisper (base int8)...")
        _model = WhisperModel("base", device="cpu", compute_type="int8")
        print("[ASR Engine] Mô hình Whisper đã sẵn sàng!")
    return _model

def transcribe_audio_file(file_path: str) -> dict:
    """Nhận diện giọng nói từ đường dẫn file âm thanh."""
    model = get_whisper_model()
    segments, info = model.transcribe(
        file_path,
        beam_size=5,
        word_timestamps=True,
        vad_filter=True,  # Tự động lọc tiếng ồn nền
        temperature=0.0,
        initial_prompt=None,
        repetition_penalty=1.2,
        no_repeat_ngram_size=3,
        condition_on_previous_text=False,
        no_speech_threshold=0.5,
        compression_ratio_threshold=2.2,
        log_prob_threshold=-1.0
    )
    
    full_text_list = []
    word_details = []
    
    for seg in segments:
        seg_text = seg.text.strip()
        if is_hallucination(seg_text):
            continue
        full_text_list.append(seg_text)
        if hasattr(seg, 'words') and seg.words:
            for w in seg.words:
                w_str = normalize_text_for_phonemes(w.word.strip())
                if w_str:
                    word_details.append({
                        "word": w_str,
                        "start": round(w.start, 2),
                        "end": round(w.end, 2),
                        "probability": round(w.probability, 2)
                    })
                
    full_text = " ".join(full_text_list).strip()
    full_text = normalize_text_for_phonemes(full_text)
    return {
        "text": full_text,
        "language": info.language if info else "unknown",
        "duration": round(info.duration, 2) if info else 0.0,
        "words": word_details
    }

def transcribe_audio_bytes(audio_bytes: bytes) -> dict:
    """Nhận diện giọng nói trực tiếp từ mảng bytes âm thanh WAV/PCM/WEBM."""
    if not audio_bytes or len(audio_bytes) < 500:
        return {"text": "", "duration": 0.0, "words": []}
        
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_name = tmp.name
        tmp.write(audio_bytes)
        
    try:
        result = transcribe_audio_file(tmp_name)
    finally:
        if os.path.exists(tmp_name):
            try:
                os.remove(tmp_name)
            except Exception:
                pass
                
    return result

if __name__ == "__main__":
    model = get_whisper_model()
    print("ASR Engine ready for streaming!")
