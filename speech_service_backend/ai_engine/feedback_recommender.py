"""
Module Feedback & Recommender:
Cung cấp hướng dẫn khẩu hình đặt lưỡi, mở môi bằng tiếng Việt cho từng âm vị,
đồng thời phát hiện âm vị yếu nhất để sinh bài tập khắc phục (Targeted Drills).
"""

# Hướng dẫn khẩu hình chi tiết cho các âm vị tiếng Anh hay bị người Việt phát âm sai
PHONEME_TIPS_VIETNAMESE = {
    'TH': 'Âm /θ/ (ví dụ think, three): Đặt đầu lưỡi nhẹ nhàng giữa hai hàm răng, đẩy luồng hơi êm qua khe răng, không cắn chặt răng và không rung thanh quản.',
    'DH': 'Âm /ð/ (ví dụ that, this): Đặt đầu lưỡi giữa hai hàm răng giống âm /θ/, nhưng vừa thổi hơi vừa rung nhẹ dây thanh quản ở cổ họng.',
    'S':  'Âm /s/ (âm đuôi): Khép hai hàm răng hờ, đặt đầu lưỡi sát chân răng trên, xì hơi mạnh và dứt khoát ra ngoài.',
    'Z':  'Âm /z/ (âm đuôi): Khẩu hình giống âm /s/ nhưng rung dây thanh quản (nghe như tiếng ong kêu zzz).',
    'SH': 'Âm /ʃ/ (ví dụ she, shoe): Chu môi tròn về phía trước, nâng thân lưỡi lên vòm họng và thổi luồng hơi lớn ra ngoài.',
    'CH': 'Âm /tʃ/ (ví dụ chair, watch): Khẩu hình chu môi như /ʃ/, chặn hơi lại rồi bật mạnh dứt khoát.',
    'JH': 'Âm /dʒ/ (ví dụ job, bridge): Giống âm /tʃ/ nhưng rung dây thanh quản mạnh mẽ.',
    'R':  'Âm /r/ (ví dụ red, right): Uốn cong đầu lưỡi về phía vòm họng nhưng KHÔNG chạm vào vòm miệng, hơi mở môi.',
    'L':  'Âm /l/ (ví dụ light, call): Đặt đầu lưỡi chạm vào phần nướu phía sau răng cửa hàm trên.',
    'V':  'Âm /v/ (ví dụ very, voice): Đặt nhẹ răng cửa hàm trên lên môi dưới và rung dây thanh quản.',
    'F':  'Âm /f/ (ví dụ feel, safe): Đặt nhẹ răng cửa hàm trên lên môi dưới và thổi luồng hơi ra, không rung dây thanh.',
    'NG': 'Âm /ŋ/ (ví dụ think, song): Nâng cuống lưỡi chạm vào ngạc mềm phía sau cổ họng, cho luồng hơi thoát ra qua đường mũi.',
    'K':  'Âm /k/ (âm bật hơi đuôi): Nâng cuống lưỡi chặn luồng hơi lại rồi bật mở dứt khoát tạo tiếng khậc nhẹ.',
    'T':  'Âm /t/ (âm đuôi): Đặt đầu lưỡi lên chân răng trên, chặn luồng khí lại rồi bật mở hơi dứt khoát.'
}

# Ngân hàng câu luyện tập tập trung (Targeted Drills) theo từng nhóm âm vị
DRILLS_BY_PHONEME = {
    'TH': [
        {"sentence": "I think this is the third thing.", "focus": "/θ/"},
        {"sentence": "Thirty-three thousand people.", "focus": "/θ/"},
        {"sentence": "Thank you for the thoughtful gift.", "focus": "/θ/"}
    ],
    'DH': [
        {"sentence": "This and that are both theirs.", "focus": "/ð/"},
        {"sentence": "They breathe the fresh air.", "focus": "/ð/"},
        {"sentence": "Neither brother went there.", "focus": "/ð/"}
    ],
    'R': [
        {"sentence": "Red roses grow around the river.", "focus": "/r/"},
        {"sentence": "Reading really relaxes right now.", "focus": "/r/"}
    ],
    'L': [
        {"sentence": "Little Lily loves yellow lollipops.", "focus": "/l/"},
        {"sentence": "Please call all the tall players.", "focus": "/l/"}
    ],
    'SH': [
        {"sentence": "She sells seashells on the shore.", "focus": "/ʃ/"},
        {"sentence": "Should we show the short movie?", "focus": "/ʃ/"}
    ],
    'S': [
        {"sentence": "She likes facts and statistics.", "focus": "/s/ (ending)"},
        {"sentence": "Six cats sit on six desks.", "focus": "/s/ (ending)"}
    ]
}

def get_tip_for_phoneme(phoneme: str) -> str:
    """Lấy lời khuyên khẩu hình miệng tương ứng."""
    clean_p = phoneme.replace('0', '').replace('1', '').replace('2', '').upper()
    return PHONEME_TIPS_VIETNAMESE.get(clean_p, "Hãy lắng nghe audio mẫu và chú ý phát âm rõ từng âm tiết, đặc biệt là âm đuôi.")

def get_recommendations_for_weaknesses(weak_phonemes: list[str]) -> list[dict]:
    """Sinh danh sách bài tập khắc phục cho các âm vị yếu."""
    recommendations = []
    seen = set()
    for p in weak_phonemes:
        clean_p = p.replace('0', '').replace('1', '').replace('2', '').upper()
        if clean_p in DRILLS_BY_PHONEME and clean_p not in seen:
            seen.add(clean_p)
            recommendations.extend(DRILLS_BY_PHONEME[clean_p])
    if not recommendations:
        # Nếu phát âm tốt, gợi ý câu giao tiếp nâng cao
        recommendations = [
            {"sentence": "We appreciate your dedication to this project.", "focus": "Fluency & Stress"},
            {"sentence": "Consistent practice leads to confident speaking.", "focus": "Rhythm & Intonation"}
        ]
    return recommendations[:3]

