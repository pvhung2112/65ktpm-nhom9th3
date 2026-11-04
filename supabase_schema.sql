-- ====================================================================
-- SUPABASE SCHEMA DỰ ÁN TH3: ENGLISH PRONUNCIATION AI & STREAK
-- ====================================================================

-- 1. BẢNG PROFILES (Người dùng & Chuỗi Streak Kỷ Luật)
CREATE TABLE IF NOT EXISTS public.profiles (
    firebase_uid TEXT PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    current_streak INT DEFAULT 0,
    max_streak INT DEFAULT 0,
    last_practice_date DATE,
    daily_target_minutes INT DEFAULT 15,
    daily_target_sentences INT DEFAULT 5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. BẢNG DAILY_GOALS (Tiến Độ Học & Mục Tiêu Ngày)
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT REFERENCES public.profiles(firebase_uid) ON DELETE CASCADE,
    goal_date DATE DEFAULT CURRENT_DATE,
    target_minutes INT DEFAULT 15,
    practiced_minutes INT DEFAULT 0,
    target_sentences INT DEFAULT 5,
    practiced_sentences INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    UNIQUE (firebase_uid, goal_date)
);

-- 3. BẢNG LESSONS (Ngân Hàng Bài Học & Câu Phát Âm Mẫu)
CREATE TABLE IF NOT EXISTS public.lessons (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    target_sentence TEXT NOT NULL,
    standard_ipa TEXT NOT NULL,
    target_focus_phonemes TEXT NOT NULL,
    audio_native_url TEXT
);

-- 4. BẢNG PRACTICE_HISTORIES (Lịch Sử Luyện Tập & Điểm Số AI)
CREATE TABLE IF NOT EXISTS public.practice_histories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT REFERENCES public.profiles(firebase_uid) ON DELETE CASCADE,
    lesson_id INT REFERENCES public.lessons(id) ON DELETE SET NULL,
    audio_storage_url TEXT,
    overall_score FLOAT NOT NULL,
    accuracy_score FLOAT NOT NULL,
    fluency_score FLOAT NOT NULL,
    completeness_score FLOAT NOT NULL,
    duration_seconds INT DEFAULT 0,
    recognized_text TEXT,
    ai_feedback_text TEXT,
    practiced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. BẢNG PHONEME_ANALYSES (Chi Tiết Phân Tích Từng Âm Vị Đúng/Sai)
CREATE TABLE IF NOT EXISTS public.phoneme_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    practice_history_id UUID REFERENCES public.practice_histories(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    standard_word_ipa TEXT NOT NULL,
    user_word_ipa TEXT,
    is_correct BOOLEAN DEFAULT TRUE,
    word_score FLOAT DEFAULT 100,
    error_type TEXT DEFAULT 'CORRECT',
    phoneme_details JSONB DEFAULT '[]'::JSONB,
    tip_recommendation TEXT
);

-- 6. BẢNG REMINDER_SETTINGS (Cài Đặt Thông Báo Nhắc Nhở Hàng Ngày)
CREATE TABLE IF NOT EXISTS public.reminder_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT REFERENCES public.profiles(firebase_uid) ON DELETE CASCADE,
    reminder_time TEXT DEFAULT '20:00',
    is_enabled BOOLEAN DEFAULT TRUE,
    sound_tone TEXT DEFAULT 'default'
);

-- BẬT ROW LEVEL SECURITY (RLS) VỚI POLICY MỞ CHO PHÉP ĐỌC GHI HỢP LỆ
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_histories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phoneme_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all on lessons" ON public.lessons FOR ALL USING (true);
CREATE POLICY "Allow all on profiles" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow all on daily_goals" ON public.daily_goals FOR ALL USING (true);
CREATE POLICY "Allow all on practice_histories" ON public.practice_histories FOR ALL USING (true);
CREATE POLICY "Allow all on phoneme_analyses" ON public.phoneme_analyses FOR ALL USING (true);
CREATE POLICY "Allow all on reminder_settings" ON public.reminder_settings FOR ALL USING (true);

-- SEED DỮ LIỆU BÀI HỌC MẪU (TỪ VỰNG NGẮN & CÂU GIAO TIẾP TỪ CƠ BẢN ĐẾN THỬ THÁCH)
INSERT INTO public.lessons (title, category, difficulty, target_sentence, standard_ipa, target_focus_phonemes, audio_native_url) VALUES
('Từ vựng: Xin chào', 'Vocabulary', 'Beginner', 'Hello', '/həˈloʊ/', '/h/, /oʊ/', ''),
('Từ vựng: Số ba (Âm /θ/)', 'Vocabulary', 'Beginner', 'Three', '/θriː/', '/θ/, /r/', ''),
('Từ vựng: Cảm ơn', 'Vocabulary', 'Beginner', 'Thank you', '/ˈθæŋk juː/', '/θ/, /ŋ/', ''),
('Từ vựng: Quả táo', 'Vocabulary', 'Beginner', 'Apple', '/ˈæpəl/', '/æ/, /p/, /l/', ''),
('Từ vựng: Nước uống', 'Vocabulary', 'Beginner', 'Water', '/ˈwɔːtər/', '/w/, /t/', ''),
('Từ vựng: Cà phê', 'Vocabulary', 'Beginner', 'Coffee', '/ˈkɔːfi/', '/k/, /f/', ''),
('Từ vựng: Chào buổi sáng', 'Vocabulary', 'Beginner', 'Good morning', '/ɡʊd ˈmɔːrnɪŋ/', '/ɡ/, /ʊ/, /ŋ/', ''),
('Từ vựng: Tạm biệt', 'Vocabulary', 'Beginner', 'Goodbye', '/ɡʊdˈbaɪ/', '/d/, /aɪ/', ''),
('Từ vựng: Âm nhạc', 'Vocabulary', 'Beginner', 'Music', '/ˈmjuːzɪk/', '/z/, /k/', ''),
('Từ vựng: Gia đình', 'Vocabulary', 'Beginner', 'Family', '/ˈfæməli/', '/f/, /æ/, /l/', ''),
('Giao tiếp hàng ngày 1', 'Daily Life', 'Beginner', 'I think that is right.', '/aɪ θɪŋk ðæt ɪz raɪt/', '/θ/, /ð/', ''),
('Giao tiếp hàng ngày 2', 'Daily Life', 'Beginner', 'Thank you very much for your help.', '/θæŋk juː ˈveri mʌtʃ fɔːr jɔːr help/', '/θ/, /tʃ/', ''),
('Cặp âm tối thiểu /θ/ và /s/', 'Minimal Pairs', 'Intermediate', 'Think and sink are different words.', '/θɪŋk ænd sɪŋk ɑːr ˈdɪfrənt wɜːrdz/', '/θ/, /s/', ''),
('Cặp âm tối thiểu /r/ và /l/', 'Minimal Pairs', 'Intermediate', 'Red lorry yellow lorry.', '/red ˈlɒri ˈjeləʊ ˈlɒri/', '/r/, /l/', ''),
('Thử thách âm đuôi /s/, /t/', 'Pronunciation Challenge', 'Intermediate', 'She likes facts and statistics.', '/ʃiː laɪks fækts ænd stəˈtɪstɪks/', '/ks/, /kts/', ''),
('Thử thách nguyên âm dài ngắn', 'Pronunciation Challenge', 'Intermediate', 'Please sit on this seat.', '/pliːz sɪt ɒn ðɪs siːt/', '/ɪ/, /iː/', ''),
('Thử thách âm /ʃ/ và /tʃ/', 'Pronunciation Challenge', 'Advanced', 'She sells seashells on the seashore.', '/ʃiː selz ˈsiːʃelz ɒn ðə ˈsiːʃɔːr/', '/ʃ/', ''),
('Môi trường công sở', 'Business', 'Advanced', 'We appreciate your dedication to this project.', '/wiː əˈpriːʃieɪt jɔːr ˌdedɪˈkeɪʃn tuː ðɪs ˈprɒdʒekt/', '/ʃ/, /dʒ/', ''),
('Thời tiết & Cảm xúc', 'Daily Life', 'Beginner', 'The weather is really nice today.', '/ðə ˈweðər ɪz ˈrɪəli naɪs təˈdeɪ/', '/ð/, /s/', ''),
('Phát âm số đếm khó', 'Minimal Pairs', 'Beginner', 'Three thousand three hundred and thirty three.', '/θriː ˈθaʊznd θriː ˈhʌndrəd ænd ˈθɜːti θriː/', '/θ/', '')
ON CONFLICT DO NOTHING;

