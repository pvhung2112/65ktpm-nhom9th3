# BÁO CÁO BÀI TẬP TH3: ỨNG DỤNG HỌC TIẾNG ANH VỚI PHÂN TÍCH PHÁT ÂM AI & KỶ LUẬT STREAK

## 1. TỔNG QUAN HỆ THỐNG
Dự án được xây dựng hoàn chỉnh với sự kết hợp của các công nghệ hiện đại chuẩn Enterprise:
- **Frontend App**: **Flutter (Dart 3.x, Flutter 3.47+)** - Giao diện Material 3, vẽ sóng âm thanh real-time, responsive trên Web/Mobile/Desktop.
- **Xác thực người dùng**: **Firebase Authentication** - Quản lý tài khoản, đăng ký, đăng nhập bảo mật bằng Email/Password.
- **Cơ sở dữ liệu & Lưu trữ**: **Supabase (PostgreSQL Database + Supabase Storage)** - 6 bảng dữ liệu chuẩn hóa liên kết qua `firebase_uid`.
- **Giao thức nhận diện âm thanh**: **WebSocket Real-time Audio Streaming (TCP Song công Full-duplex)** - Micro stream trực tiếp các gói PCM 16-bit 16kHz lên Server, hiển thị chữ ngay trong lúc nói.
- **AI Pronunciation Engine**: **OpenAI Whisper (bản tối ưu Faster-Whisper int8)** + **NLTK CMUdict** của Đại học Carnegie Mellon kết hợp thuật toán **Needleman-Wunsch Alignment** so sánh từng âm vị và chấm điểm đa chiều.

---

## 2. BẢNG NGHIỆM THU ĐỐI CHIẾU 7 MỤC CHECKLIST CỦA ĐỀ BÀI

| Mục | Tiêu Chí Đề Bài | Giải Pháp Kỹ Thuật Đã Triển Khai | Vị Trí File Mã Nguồn |
| :---: | :--- | :--- | :--- |
| **1** | Thiết kế CSDL lưu trữ User, lịch sử luyện tập, kết quả âm vị | 6 bảng PostgreSQL trên Supabase (`profiles`, `daily_goals`, `lessons`, `practice_histories`, `phoneme_analyses`, `reminder_settings`) + Bucket `audio_recordings` | `supabase_schema.sql`<br>`englishth3/lib/services/supabase_service.dart` |
| **2** | Theo dõi tiến độ: đếm streak, thống kê thời gian học, đặt mục tiêu ngày | Logic tính chuỗi ngày liên tiếp (Streak 🔥), Stopwatch đếm giờ học thực tế, Progress Bar mục tiêu kép, Biểu đồ cột 7 ngày (`fl_chart`) | `englishth3/lib/views/dashboard/dashboard_screen.dart`<br>`englishth3/lib/widgets/score_circle.dart` |
| **3** | Tích hợp API nhận dạng giọng nói thu âm & xử lý | Package `record` thu âm 16kHz + **WebSocket Streaming (`ws://.../ws/audio_stream`)** truyền stream PCM trực tiếp lên Faster-Whisper ASR | `speech_service_backend/api_server.py`<br>`englishth3/lib/views/practice/practice_screen.dart` |
| **4** | Mô hình AI / thuật toán so sánh âm vị & chấm điểm | Từ điển **NLTK CMUdict** + Thuật toán **Needleman-Wunsch Dynamic Alignment** chấm điểm Accuracy, Fluency, Completeness, Overall | `speech_service_backend/ai_engine/phoneme_aligner.py`<br>`speech_service_backend/ai_engine/g2p_phoneme.py` |
| **5** | Module phản hồi: hiển thị điểm, tô màu âm sai, đề xuất bài tập | **Word Chips 3 màu** (🟢 Xanh $\ge 80$, 🟡 Vàng $50-79$, 🔴 Đỏ $< 50$), BottomSheet hướng dẫn khẩu hình lưỡi/môi và nút sinh bài tập khắc phục | `englishth3/lib/views/feedback/pronunciation_feedback_dialog.dart`<br>`speech_service_backend/ai_engine/feedback_recommender.py` |
| **6** | Hệ thống thông báo nhắc nhở hàng ngày & giao diện tiến độ | Package `flutter_local_notifications` đẩy thông báo theo giờ hẹn hàng ngày + Banner cảnh báo giữ vững streak | `englishth3/lib/services/notification_service.dart`<br>`englishth3/lib/views/dashboard/dashboard_screen.dart` |
| **7** | Kiểm thử ứng dụng với nhiều người dùng và các giọng nói khác nhau | Tab **Testing Lab**: 4 mẫu giọng thực tế (Mỹ chuẩn, Anh chuẩn, Việt chuẩn, Việt lỗi) + 3 tài khoản kiểm thử với mức streak khác nhau | `englishth3/lib/views/test_lab/testing_lab_screen.dart`<br>`englishth3/lib/services/ai_speech_service.dart` |

---

## 3. CẤU TRÚC THƯ MỤC DỰ ÁN

```
d:\th3\
├── englishth3/                       # ỨNG DỤNG FRONTEND FLUTTER
│   ├── lib/
│   │   ├── main.dart                 # Khởi tạo Firebase, Supabase, Notifications
│   │   ├── config/
│   │   │   ├── firebase_options.dart # Cấu hình Firebase
│   │   │   └── supabase_config.dart  # Supabase URL & Key
│   │   ├── models/                   # Profile, Lesson, PracticeHistory, PronunciationResult
│   │   ├── services/
│   │   │   ├── auth_service.dart     # Firebase Authentication
│   │   │   ├── supabase_service.dart # Supabase PostgreSQL & Storage
│   │   │   ├── ai_speech_service.dart # AI Service (REST & WebSocket Aligner)
│   │   │   └── notification_service.dart # Nhắc nhở local notifications
│   │   ├── views/
│   │   │   ├── auth/login_screen.dart
│   │   │   ├── dashboard/dashboard_screen.dart
│   │   │   ├── practice/practice_screen.dart # Micro Real-time Streaming & Waveform
│   │   │   ├── feedback/pronunciation_feedback_dialog.dart
│   │   │   └── test_lab/testing_lab_screen.dart
│   │   └── widgets/                  # Waveform, ScoreCircle, StreakBadge
│   └── pubspec.yaml
│
├── speech_service_backend/           # BACKEND AI SPEECH & PHONEME SERVICE (FASTAPI & PYTHON)
│   ├── ai_engine/
│   │   ├── asr_engine.py             # OpenAI Faster-Whisper Streaming ASR
│   │   ├── g2p_phoneme.py            # NLTK CMUdict IPA Phonemes
│   │   ├── phoneme_aligner.py        # Needleman-Wunsch Alignment
│   │   └── feedback_recommender.py   # Lời khuyên khẩu hình miệng tiếng Việt
│   └── api_server.py                 # FastAPI Server (REST & WebSocket /ws/audio_stream)
│
├── supabase_schema.sql               # File SQL khởi tạo 6 bảng trên Supabase
└── README.md                         # Báo cáo nghiệm thu đồ án
```

---

## 4. HƯỚNG DẪN CHẠY ỨNG DỤNG

### Bước 1: Khởi động Backend AI Server (Python Faster-Whisper & NLTK)
Mở một cửa sổ Terminal (PowerShell):
```powershell
$env:PYTHONIOENCODING="utf-8"
cd d:\th3\speech_service_backend
python -m uvicorn api_server:app --host 0.0.0.0 --port 8000
```
👉 Server sẽ báo: `Application startup complete. Uvicorn running on http://0.0.0.0:8000`

### Bước 2: Khởi động Ứng Dụng Flutter
Mở một cửa sổ Terminal khác:
```powershell
cd d:\th3\englishth3
flutter run -d chrome
```

---

## 5. HƯỚNG DẪN DÀNH CHO THẦY CÔ CHẤM BÀI (NGHIỆM THU NHANH)

1. **Kiểm tra Xác thực Firebase**:
   - Tại màn hình đăng nhập, có sẵn 3 nút đăng nhập nhanh vào 3 tài khoản mẫu:
     - *Nguyễn An*: Học viên mới (Streak 1 ngày).
     - *Trần Bình*: Học viên chăm chỉ (Streak 7 ngày).
     - *Lê Cường*: Học viên kỳ cựu (Streak 21 ngày).
2. **Kiểm tra Kỷ luật & Streak (Checklist 2 & 6)**:
   - Trên thanh tiêu đề: Thẻ lửa Streak hiển thị số ngày liên tiếp.
   - Bấm vào biểu tượng **Chuông 🔔**: Hệ thống lập tức bắn thông báo nhắc nhở luyện tập hàng ngày.
   - Thẻ tiến độ ngày: Vòng tròn % mục tiêu ngày và Biểu đồ cột 7 ngày học tập.
3. **Kiểm tra Luyện phát âm & Phân tích âm vị AI (Checklist 3, 4, 5)**:
   - Bấm vào bài học bất kỳ.
   - Bấm biểu tượng loa để nghe audio đọc mẫu bản xứ (US English to & rõ).
   - Bấm Micro để thu âm giọng nói (hoặc chọn các Accent kiểm thử ở góc phải: US, UK, VN Good, VN Error).
   - Xem popup phản hồi chi tiết: Bảng điểm tổng thể, các từ tô màu 3 cấp độ (Xanh/Vàng/Đỏ), bấm vào từng từ để xem so sánh âm vị chi tiết (Needleman-Wunsch) và khẩu hình lưỡi/môi.
4. **Kiểm tra Testing Lab (Checklist 7)**:
   - Chuyển sang tab **Testing Lab** ở thanh điều hướng dưới.
   - Bấm "Chạy kiểm thử toàn bộ Benchmark" để xem hệ thống AI phân tích tự động 4 mẫu giọng thực tế.

