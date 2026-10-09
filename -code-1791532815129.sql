-- ==============================================================================
-- CAI: Augmented Reality (AR) - Database Setup
-- วิชา: วิทยาการคำนวณ (2103404)
-- ==============================================================================

-- 1. สร้าง Schema สำหรับเก็บข้อมูลที่เป็นความลับ (ห้าม Client เข้าถึง)
CREATE SCHEMA IF NOT EXISTS private;

-- 2. สร้างตารางหลัก (Tables)
CREATE TABLE public.teachers (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.students (
    id TEXT PRIMARY KEY CHECK (id ~ '^[0-9]{11}$'),
    title TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    section TEXT NOT NULL,
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    photo_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    kind TEXT CHECK (kind IN ('pre', 'post')),
    test_set TEXT CHECK (test_set IN ('A', 'B')),
    score INT CHECK (score >= 0 AND score <= 10),
    answers JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, kind) -- 1 คน ทำ pre ได้ 1 ครั้ง, post ได้ 1 ครั้ง
);

CREATE TABLE public.progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    unit INT CHECK (unit >= 1 AND unit <= 5),
    done BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, unit) -- 1 คน มีสถานะ 1 แถวต่อ 1 หน่วย
);

CREATE TABLE public.submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    unit INT CHECK (unit >= 1 AND unit <= 5),
    kind TEXT CHECK (kind IN ('link', 'file')),
    url TEXT,
    storage_path TEXT,
    note TEXT,
    score INT CHECK (score >= 0 AND score <= 10),
    teacher_comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (
        (kind = 'link' AND url IS NOT NULL) OR 
        (kind = 'file' AND storage_path IS NOT NULL)
    )
);

CREATE TABLE public.materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    kind TEXT CHECK (kind IN ('file', 'link', 'video')),
    url TEXT,
    storage_path TEXT,
    file_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ตารางเก็บเฉลยแบบทดสอบ (อยู่ใน schema private ผู้เรียนอ่านไม่ได้)
CREATE TABLE private.quiz_keys (
    test_set TEXT CHECK (test_set IN ('A', 'B')),
    item_no INT CHECK (item_no >= 1 AND item_no <= 10),
    correct_choice INT CHECK (correct_choice >= 1 AND correct_choice <= 4),
    PRIMARY KEY (test_set, item_no)
);

-- 3. กำหนดข้อมูลเฉลย (ชุด A และ B อย่างละ 10 ข้อ)
-- หมายเหตุ: เป็นตัวอย่างเฉลยตามที่โครงสร้างกำหนดไว้เพื่อใช้คำนวณคะแนน
INSERT INTO private.quiz_keys (test_set, item_no, correct_choice) VALUES
('A',1,2), ('A',2,3), ('A',3,1), ('A',4,4), ('A',5,2), ('A',6,3), ('A',7,1), ('A',8,4), ('A',9,2), ('A',10,1),
('B',1,3), ('B',2,1), ('B',3,4), ('B',4,2), ('B',5,1), ('B',6,4), ('B',7,2), ('B',8,3), ('B',9,1), ('B',10,4);

-- 4. ฟังก์ชันจัดการความปลอดภัยและการตรวจข้อสอบ (Security Definer)
-- 4.1 ตรวจสอบสิทธิ์ผู้สอน
CREATE OR REPLACE FUNCTION public.is_teacher() 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.teachers WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 4.2 ตรวจสอบสิทธิ์ผู้ใช้งานในระบบ (ผู้เรียนที่ผูกบัญชีแล้ว หรือผู้สอน)
CREATE OR REPLACE FUNCTION public.is_authorized_user() 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.students WHERE user_id = auth.uid()) OR public.is_teacher();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 4.3 ฟังก์ชันตรวจคำตอบและบันทึกผลคะแนน ป้องกันการส่งค่า score ตรงๆ จากเว็บ
CREATE OR REPLACE FUNCTION public.submit_attempt_secure(
    p_kind TEXT, 
    p_answers JSONB
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_student_id TEXT;
    v_test_set TEXT;
    v_score INT := 0;
    v_item RECORD;
    v_ans INT;
    v_progress_count INT;
BEGIN
    -- ตรวจสอบว่าเป็นนักเรียนหรือไม่
    SELECT id INTO v_student_id FROM public.students WHERE user_id = v_user_id;
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Only registered students can submit attempts.';
    END IF;

    -- กำหนดชุดข้อสอบตามเลขประจำตัว (คู่: A/B, คี่: B/A)
    IF CAST(RIGHT(v_student_id, 1) AS INT) % 2 = 0 THEN
        v_test_set := CASE WHEN p_kind = 'pre' THEN 'A' ELSE 'B' END;
    ELSE
        v_test_set := CASE WHEN p_kind = 'pre' THEN 'B' ELSE 'A' END;
    END IF;

    -- ตรวจสอบเงื่อนไขการทำ post test (ต้องเรียนจบ 5 หน่วย)
    IF p_kind = 'post' THEN
        SELECT COUNT(*) INTO v_progress_count FROM public.progress WHERE user_id = v_user_id AND done = TRUE;
        IF v_progress_count < 5 THEN
            RAISE EXCEPTION 'Prerequisite not met: Must complete all 5 units before post-test.';
        END IF;
    END IF;

    -- ตรวจว่าส่งซ้ำหรือไม่
    IF EXISTS (SELECT 1 FROM public.attempts WHERE user_id = v_user_id AND kind = p_kind) THEN
        RAISE EXCEPTION 'Conflict: % test already submitted.', p_kind;
    END IF;

    -- ตรวจคำตอบเทียบกับเฉลยใน private schema
    FOR v_item IN SELECT item_no, correct_choice FROM private.quiz_keys WHERE test_set = v_test_set LOOP
        v_ans := CAST(p_answers->>v_item.item_no::TEXT AS INT);
        IF v_ans = v_item.correct_choice THEN
            v_score := v_score + 1;
        END IF;
    END LOOP;

    -- บันทึกผลลงตาราง
    INSERT INTO public.attempts (user_id, kind, test_set, score, answers)
    VALUES (v_user_id, p_kind, v_test_set, v_score, p_answers);

    -- คืนค่าผลลัพธ์ (ไม่คืนเฉลยหากเป็น pre test)
    IF p_kind = 'pre' THEN
        RETURN json_build_object('success', true, 'message', 'Pre-test submitted successfully.');
    ELSE
        RETURN json_build_object('success', true, 'score', v_score, 'message', 'Post-test submitted successfully.');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private, pg_temp;

-- 4.4 ฟังก์ชันผูกบัญชีนักเรียน (ตรวจสอบว่าอีเมลตรงกับเลข 11 หลัก และมีรายชื่อในระบบ)
CREATE OR REPLACE FUNCTION public.link_student_account(p_student_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
    -- ตรวจสอบรูปแบบอีเมลและป้องกันการผูกซ้ำ
    IF v_email = p_student_id || '@snru.ac.th' THEN
        UPDATE public.students 
        SET user_id = auth.uid() 
        WHERE id = p_student_id AND user_id IS NULL;
        
        IF FOUND THEN RETURN TRUE; END IF;
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 5. สร้าง View สำหรับดึงผลลัพธ์พร้อมคำนวณ Normalized Gain
CREATE OR REPLACE VIEW public.results WITH (security_invoker = true) AS
SELECT 
    s.id, s.title, s.first_name, s.last_name, s.section, s.photo_path,
    pre.score AS pre_score,
    pre.test_set AS pre_set,
    post.score AS post_score,
    post.test_set AS post_set,
    CASE 
        WHEN pre.score IS NULL OR post.score IS NULL THEN NULL
        WHEN pre.score = 10 THEN 'N/A' -- คำนวณไม่ได้เมื่อคะแนนก่อนเรียนเต็ม
        ELSE ROUND(((post.score - pre.score)::NUMERIC / (10 - pre.score)::NUMERIC), 2)::TEXT
    END AS normalized_gain
FROM public.students s
LEFT JOIN public.attempts pre ON s.user_id = pre.user_id AND pre.kind = 'pre'
LEFT JOIN public.attempts post ON s.user_id = post.user_id AND post.kind = 'post';

-- 6. Row Level Security (RLS)
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

-- ถอดสิทธิ์ทั้งหมดจากผู้ใช้ทั่วไป (anon)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;

-- นโยบาย Teachers
CREATE POLICY "Teachers can read all students" ON public.students FOR SELECT TO authenticated USING (public.is_teacher() OR auth.uid() = user_id);
-- นักเรียนอัปเดตได้เฉพาะรูปภาพตนเองผ่านคอลัมน์ photo_path (จำกัดสิทธิ์ในระดับแอป)
CREATE POLICY "Students update own photo" ON public.students FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- นโยบาย Attempts
CREATE POLICY "Users read own attempts" ON public.attempts FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_teacher());
-- (Insert ปิดไว้ ให้ใช้ผ่าน submit_attempt_secure เท่านั้น)

-- นโยบาย Progress
CREATE POLICY "Users read own progress" ON public.progress FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_teacher());
CREATE POLICY "Users update own progress" ON public.progress FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users modify own progress" ON public.progress FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- นโยบาย Submissions
CREATE POLICY "Users read own submissions" ON public.submissions FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_teacher());
CREATE POLICY "Users insert own submissions" ON public.submissions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id AND score IS NULL AND teacher_comment IS NULL);
CREATE POLICY "Teachers update submissions" ON public.submissions FOR UPDATE TO authenticated USING (public.is_teacher());

-- นโยบาย Materials
CREATE POLICY "Authorized read materials" ON public.materials FOR SELECT TO authenticated USING (public.is_authorized_user());
CREATE POLICY "Teachers manage materials" ON public.materials FOR ALL TO authenticated USING (public.is_teacher());

-- 7. ข้อมูลจำลองนักเรียน 6 คน (สำหรับ Table Editor)
INSERT INTO public.students (id, title, first_name, last_name, section) VALUES
('11111111111', 'ด.ช.', 'สมชาย', 'ใจดี', 'ป.4/1'),
('11111111112', 'ด.ญ.', 'สมหญิง', 'รักเรียน', 'ป.4/1'),
('11111111113', 'ด.ช.', 'มานะ', 'อดทน', 'ป.4/2'),
('11111111114', 'ด.ญ.', 'มานี', 'มีสติ', 'ป.4/2'),
('11111111115', 'ด.ช.', 'ปิติ', 'พิทักษ์', 'ป.4/3'),
('11111111116', 'ด.ญ.', 'ชูใจ', 'ใฝ่รู้', 'ป.4/3');

-- ==============================================================================
-- การผูกบัญชีผู้สอน (คำแนะนำ)
-- ผู้ดูแลระบบต้องไปที่เมนู Authentication ใน Supabase -> สร้างบัญชีผู้สอนด้วยอีเมล
-- จากนั้นนำอีเมลมาใส่ในคำสั่งด้านล่าง ลบคอมเมนต์ออก และรันเฉพาะส่วนนี้
-- ==============================================================================
-- INSERT INTO public.teachers (user_id, email)
-- SELECT id, email FROM auth.users WHERE email = 'teacher@school.ac.th';

-- 8. Storage Buckets & Policies (ต้องเปิดใช้ Extension pgcrypto หากไม่มี)
INSERT INTO storage.buckets (id, name, public) VALUES 
('photos', 'photos', false),
('submissions', 'submissions', false),
('materials', 'materials', false)
ON CONFLICT DO NOTHING;

-- นโยบาย Photos Bucket
CREATE POLICY "User manage own photos" ON storage.objects FOR ALL TO authenticated USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Teacher read all photos" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'photos' AND public.is_teacher());

-- นโยบาย Submissions Bucket
CREATE POLICY "User insert own submissions" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "User read own submissions file" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Teacher read all submissions" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'submissions' AND public.is_teacher());

-- นโยบาย Materials Bucket
CREATE POLICY "Authorized read materials bucket" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'materials' AND public.is_authorized_user());
CREATE POLICY "Teacher manage materials bucket" ON storage.objects FOR ALL TO authenticated USING (bucket_id = 'materials' AND public.is_teacher());