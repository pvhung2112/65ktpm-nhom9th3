"""
Module Needleman-Wunsch Phoneme Aligner:
Thuật toán quy hoạch động gióng hàng chuỗi âm vị để phát hiện lỗi:
- Substitution: Thay thế âm (ví dụ /θ/ -> /t/)
- Omission: Nuốt âm / thiếu âm đuôi
- Insertion: Thừa âm
Đồng thời tính điểm Accuracy, Fluency, Completeness và Overall Score.
"""

import re
from .g2p_phoneme import get_word_phonemes, arpabet_to_ipa
from .text_normalizer import normalize_text_for_phonemes

def strip_stress(phoneme: str) -> str:
    """Xóa trọng âm (0, 1, 2) khỏi âm vị ARPAbet để so sánh cốt lõi."""
    return re.sub(r'\d+', '', phoneme).upper()

def needleman_wunsch_align(seq_ref: list[str], seq_hyp: list[str]):
    """
    Quy hoạch động Needleman-Wunsch để gióng hàng chuỗi âm vị chuẩn (seq_ref)
    và chuỗi âm vị người dùng phát âm (seq_hyp).
    """
    n = len(seq_ref)
    m = len(seq_hyp)
    
    # Ma trận điểm số
    # Match: +2, Near-match: +1, Mismatch/Substitution: -1, Gap (Omission/Insertion): -2
    dp = [[0] * (m + 1) for _ in range(n + 1)]
    
    gap_penalty = -2
    match_score = 2
    mismatch_penalty = -1
    
    for i in range(n + 1):
        dp[i][0] = i * gap_penalty
    for j in range(m + 1):
        dp[0][j] = j * gap_penalty
        
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            ref_p = strip_stress(seq_ref[i - 1])
            hyp_p = strip_stress(seq_hyp[j - 1])
            
            if ref_p == hyp_p:
                score = match_score
            else:
                score = mismatch_penalty
                
            match_val = dp[i - 1][j - 1] + score
            delete_val = dp[i - 1][j] + gap_penalty
            insert_val = dp[i][j - 1] + gap_penalty
            
            dp[i][j] = max(match_val, delete_val, insert_val)
            
    # Traceback để lấy đường đi tối ưu
    aligned_ref = []
    aligned_hyp = []
    
    i, j = n, m
    while i > 0 or j > 0:
        ref_p = strip_stress(seq_ref[i - 1]) if i > 0 else None
        hyp_p = strip_stress(seq_hyp[j - 1]) if j > 0 else None
        score = match_score if (ref_p and hyp_p and ref_p == hyp_p) else mismatch_penalty
        
        if i > 0 and j > 0 and dp[i][j] == dp[i - 1][j - 1] + score:
            aligned_ref.append(seq_ref[i - 1])
            aligned_hyp.append(seq_hyp[j - 1])
            i -= 1
            j -= 1
        elif i > 0 and dp[i][j] == dp[i - 1][j] + gap_penalty:
            aligned_ref.append(seq_ref[i - 1])
            aligned_hyp.append("-")  # Omission (Bỏ sót)
            i -= 1
        else:
            aligned_ref.append("-")  # Insertion (Thừa âm)
            aligned_hyp.append(seq_hyp[j - 1])
            j -= 1
            
    aligned_ref.reverse()
    aligned_hyp.reverse()
    return aligned_ref, aligned_hyp

def align_and_score_words(target_sentence: str, recognized_text: str):
    """
    So sánh phát âm từng từ giữa câu mục tiêu và văn bản nhận diện được.
    Trả về danh sách chi tiết các từ kèm điểm số, loại lỗi và các âm đúng/sai.
    """
    # Chuẩn hóa số thành chữ tiếng Anh (3 -> three, 3000 -> three thousand, 3,333 -> three thousand three hundred and thirty three)
    norm_target = normalize_text_for_phonemes(target_sentence)
    norm_rec = normalize_text_for_phonemes(recognized_text)
    
    target_words = re.findall(r"\b[\w']+\b", norm_target)
    rec_words = re.findall(r"\b[\w']+\b", norm_rec)
    
    results = []
    total_phonemes = 0
    correct_phonemes = 0
    
    # Ghép từ tương ứng theo thứ tự
    max_len = max(len(target_words), len(rec_words))
    
    for idx in range(len(target_words)):
        t_word = target_words[idx]
        t_phones = get_word_phonemes(t_word)
        t_ipa = arpabet_to_ipa(t_phones)
        word_total = len(t_phones)
        total_phonemes += word_total
        
        if idx < len(rec_words):
            r_word = rec_words[idx]
            r_phones = get_word_phonemes(r_word)
            r_ipa = arpabet_to_ipa(r_phones)
        else:
            r_word = ""
            r_phones = []
            r_ipa = "//"
            
        if not r_word:
            # Nuốt cả từ
            word_score = 0.0
            error_type = "OMISSION"
            phoneme_matches = [{"standard": p, "user": "-", "is_correct": False} for p in t_phones]
        else:
            # Gióng hàng âm vị
            a_ref, a_hyp = needleman_wunsch_align(t_phones, r_phones)
            phoneme_matches = []
            word_correct = 0
            
            for ref_p, hyp_p in zip(a_ref, a_hyp):
                if ref_p == "-":
                    continue  # Bỏ qua âm chèn
                is_match = (strip_stress(ref_p) == strip_stress(hyp_p))
                if is_match:
                    word_correct += 1
                phoneme_matches.append({
                    "standard": ref_p,
                    "user": hyp_p,
                    "is_correct": is_match
                })
                
            correct_phonemes += word_correct
            
            word_score = round((word_correct / max(1, word_total)) * 100, 1)
            
            if word_score >= 80:
                error_type = "CORRECT"
            elif word_score >= 50:
                error_type = "SUBSTITUTION"
            else:
                error_type = "SUBSTITUTION"
                
        results.append({
            "word": t_word,
            "standard_ipa": t_ipa,
            "user_ipa": r_ipa,
            "score": word_score,
            "error_type": error_type,
            "phonemes": phoneme_matches
        })
        
    accuracy_score = round((correct_phonemes / max(1, total_phonemes)) * 100, 1) if total_phonemes > 0 else 0.0
    
    # Tính completeness (đọc đủ bao nhiêu từ)
    completeness_score = round((min(len(rec_words), len(target_words)) / max(1, len(target_words))) * 100, 1)
    
    # Tính fluency (tỉ lệ mượt mà)
    if accuracy_score < 20.0:
        fluency_score = accuracy_score
    else:
        fluency_score = round(min(100.0, accuracy_score * 0.7 + completeness_score * 0.3), 1)
    
    # Điểm tổng hợp
    overall_score = round(0.6 * accuracy_score + 0.25 * fluency_score + 0.15 * completeness_score, 1)
    
    return {
        "overall_score": overall_score,
        "accuracy_score": accuracy_score,
        "fluency_score": fluency_score,
        "completeness_score": completeness_score,
        "words": results
    }

if __name__ == "__main__":
    res = align_and_score_words("I think that is right", "I tink dat is right")
    print(f"Overall: {res['overall_score']}, Accuracy: {res['accuracy_score']}")
    for w in res['words']:
        print(f"Word: {w['word']}, Score: {w['score']}, Error: {w['error_type']}")

