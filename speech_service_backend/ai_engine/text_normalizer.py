"""
Module Text Normalizer:
Chuẩn hóa văn bản nhận diện được từ Whisper và câu mẫu:
1. Chuyển đổi toàn bộ chữ số thành từ tiếng Anh (VD: 3 -> three, 3000 -> three thousand, 3,333 -> three thousand three hundred and thirty-three)
2. Loại bỏ dấu câu gây nhiễu cho từ điển CMUdict
3. Loại bỏ các cụm từ ảo giác (hallucinations) thường gặp của Whisper khi có tiếng ồn nền
"""

import re
from num2words import num2words

WHISPER_HALLUCINATIONS = {
    "oh, hello.", "oh, hello", "oh hello", "hello.", "hello",
    "thank you.", "thank you", "thank you for watching.", "thank you for watching",
    "subtitles by", "subtitles by...", "subtitles by the amara.org community",
    "you", "bye.", "bye", "goodbye.", "...", ".", "yes.", "no.",
    "so", "um", "uh", "ah"
}

def is_hallucination(text: str) -> bool:
    """Kiểm tra xem văn bản nhận diện có phải là ảo giác của Whisper do tiếng ồn hay không."""
    if not text:
        return True
    t_clean = text.lower().strip()
    if t_clean in WHISPER_HALLUCINATIONS:
        return True
    # Kiểm tra các cụm bắt đầu bằng subtitles by
    if t_clean.startswith("subtitles by") or t_clean.startswith("thank you for"):
        return True
    return False

def normalize_text_for_phonemes(text: str) -> str:
    """
    Chuyển đổi số thành chữ tiếng Anh và chuẩn hóa dấu câu để CMUdict có thể phân tích 100% âm vị.
    Ví dụ: 'Three thousand 300 and 33.' -> 'Three thousand three hundred and thirty three'
    """
    if not text:
        return ""
        
    # Xử lý số có dấu phẩy ngăn cách hàng nghìn (ví dụ 3,333 -> 3333)
    text = re.sub(r'(\d+),(\d+)', r'\1\2', text)
    
    def replace_num(match):
        num_str = match.group(0)
        try:
            val = int(num_str)
            if val < 1000000000:
                words = num2words(val)
                # Xóa dấu phẩy và gạch nối: "thirty-three" -> "thirty three"
                words = words.replace('-', ' ').replace(',', '')
                return words
        except Exception:
            pass
        return num_str

    # Thay thế các cụm chữ số
    text = re.sub(r'\b\d+\b', replace_num, text)
    
    # Xóa các ký tự đặc biệt thừa nhưng giữ lại chữ cái và dấu nháy đơn trong từ (don't, it's)
    text = re.sub(r'[^\w\s\']', ' ', text)
    
    # Chuẩn hóa khoảng trắng
    text = re.sub(r'\s+', ' ', text).strip()
    return text

