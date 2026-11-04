"""
Module G2P: Chuyển đổi chữ viết tiếng Anh sang hệ âm vị chuẩn quốc tế (CMUdict / ARPAbet sang IPA).
Dựa trên từ điển âm học chính thống của Đại học Carnegie Mellon (NLTK CMUdict).
"""

import re
import nltk
from nltk.corpus import cmudict

# Tải từ điển CMUdict nếu chưa có
try:
    _cmu_dict = cmudict.dict()
except LookupError:
    nltk.download('cmudict')
    _cmu_dict = cmudict.dict()

# Bảng tra cứu ký hiệu ARPAbet (CMUdict) sang ký hiệu quốc tế IPA
ARPABET_TO_IPA = {
    # Phụ âm (Consonants)
    'B': 'b', 'D': 'd', 'DH': 'ð', 'F': 'f', 'G': 'ɡ',
    'HH': 'h', 'JH': 'dʒ', 'K': 'k', 'L': 'l', 'M': 'm',
    'N': 'n', 'NG': 'ŋ', 'P': 'p', 'R': 'r', 'S': 's',
    'SH': 'ʃ', 'T': 't', 'TH': 'θ', 'V': 'v', 'W': 'w',
    'Y': 'j', 'Z': 'z', 'ZH': 'ʒ', 'CH': 'tʃ',
    
    # Nguyên âm ngắn & dài (Vowels)
    'AA': 'ɑː', 'AA0': 'ɑː', 'AA1': 'ɑː', 'AA2': 'ɑː',
    'AE': 'æ',  'AE0': 'æ',  'AE1': 'æ',  'AE2': 'æ',
    'AH': 'ʌ',  'AH0': 'ə',  'AH1': 'ʌ',  'AH2': 'ʌ',
    'AO': 'ɔː', 'AO0': 'ɔː', 'AO1': 'ɔː', 'AO2': 'ɔː',
    'AW': 'aʊ', 'AW0': 'aʊ', 'AW1': 'aʊ', 'AW2': 'aʊ',
    'AY': 'aɪ', 'AY0': 'aɪ', 'AY1': 'aɪ', 'AY2': 'aɪ',
    'EH': 'e',  'EH0': 'e',  'EH1': 'e',  'EH2': 'e',
    'ER': 'ɜːr', 'ER0': 'ər', 'ER1': 'ɜːr', 'ER2': 'ɜːr',
    'EY': 'eɪ', 'EY0': 'eɪ', 'EY1': 'eɪ', 'EY2': 'eɪ',
    'IH': 'ɪ',  'IH0': 'ɪ',  'IH1': 'ɪ',  'IH2': 'ɪ',
    'IY': 'iː', 'IY0': 'iː', 'IY1': 'iː', 'IY2': 'iː',
    'OW': 'oʊ', 'OW0': 'oʊ', 'OW1': 'oʊ', 'OW2': 'oʊ',
    'OY': 'ɔɪ', 'OY0': 'ɔɪ', 'OY1': 'ɔɪ', 'OY2': 'ɔɪ',
    'UH': 'ʊ',  'UH0': 'ʊ',  'UH1': 'ʊ',  'UH2': 'ʊ',
    'UW': 'uː', 'UW0': 'uː', 'UW1': 'uː', 'UW2': 'uː',
}

def clean_word(word: str) -> str:
    """Làm sạch từ: xóa dấu câu, chuyển chữ thường."""
    return re.sub(r'[^a-zA-Z\']', '', word).lower()

def get_word_phonemes(word: str) -> list[str]:
    """
    Tra cứu âm vị của từ trong CMUdict.
    Trả về danh sách các âm vị ARPAbet chuẩn (ví dụ: ['TH', 'IH1', 'NG', 'K']).
    """
    cleaned = clean_word(word)
    if not cleaned:
        return []
    
    # 1. Tra trong từ điển CMUdict
    if cleaned in _cmu_dict:
        return _cmu_dict[cleaned][0]
    
    # 2. Dự phòng tra cứu từng ký tự nếu từ viết tắt hoặc lạ
    fallback_phonemes = []
    for ch in cleaned:
        if ch in _cmu_dict:
            fallback_phonemes.extend(_cmu_dict[ch][0])
        else:
            fallback_phonemes.append(ch.upper())
    return fallback_phonemes

def arpabet_to_ipa(arpabet_list: list[str]) -> str:
    """Chuyển mảng ARPAbet sang chuỗi ký hiệu IPA quốc tế (/θɪŋk/)."""
    ipa_tokens = []
    for p in arpabet_list:
        clean_p = re.sub(r'\d+', '', p).upper()
        ipa_char = ARPABET_TO_IPA.get(p, ARPABET_TO_IPA.get(clean_p, clean_p.lower()))
        ipa_tokens.append(ipa_char)
    return f"/{''.join(ipa_tokens)}/"

def sentence_to_phonemes(sentence: str) -> list[dict]:
    """
    Bóc tách toàn bộ câu thành danh sách các từ và âm vị chi tiết.
    """
    words = re.findall(r"\b[\w']+\b", sentence)
    result = []
    for w in words:
        phonemes = get_word_phonemes(w)
        ipa = arpabet_to_ipa(phonemes)
        result.append({
            "word": w,
            "raw_phonemes": phonemes,
            "ipa": ipa
        })
    return result

if __name__ == "__main__":
    test_word = "think"
    phones = get_word_phonemes(test_word)
    print(f"Word: {test_word} -> ARPAbet: {phones} -> IPA: {arpabet_to_ipa(phones)}")

