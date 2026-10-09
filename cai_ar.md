<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ระบบ CAI วิทยาการคำนวณ เรื่องความจริงเสริม (AR)</title>
    
    <!-- Google Font: Sarabun -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- Supabase JS -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.39.3/dist/umd/supabase.min.js"></script>
    
    <!-- Model Viewer (WebAR) - ตรวจสอบเวอร์ชันล่าสุดที่เสถียร (4.0.0+) -->
    <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/4.0.0/model-viewer.min.js"></script>

    <style>
        :root {
            --primary-dark: #0f172a; /* น้ำเงินเข้ม */
            --primary-light: #1e293b;
            --bg-light: #f8fafc; /* เทาอ่อน */
            --bg-white: #ffffff;
            --text-main: #334155;
            --text-light: #f8fafc;
            --accent: #3b82f6;
            --success: #059669;
            --danger: #dc2626;
            --border: #e2e8f0;
        }

        * { box-sizing: border-box; font-family: 'Sarabun', sans-serif; }
        body { margin: 0; padding: 0; background-color: var(--bg-light); color: var(--text-main); line-height: 1.6; }
        
        /* Layouts */
        header { background-color: var(--primary-dark); color: var(--text-light); padding: 1rem; display: flex; justify-content: space-between; align-items: center; }
        .header-title { font-size: 1.25rem; font-weight: 600; margin: 0; }
        .container { max-width: 1000px; margin: 0 auto; padding: 1.5rem 1rem; }
        
        /* Cards & Panels */
        .card { background: var(--bg-white); border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; border: 1px solid var(--border); }
        .card-header { background-color: var(--primary-light); color: var(--text-light); padding: 1rem; margin: -1.5rem -1.5rem 1.5rem -1.5rem; border-radius: 8px 8px 0 0; }
        .card-header h2 { margin: 0; font-size: 1.2rem; }
        
        /* Buttons */
        button { cursor: pointer; padding: 0.5rem 1rem; border: none; border-radius: 4px; font-weight: 500; transition: opacity 0.2s; }
        button:hover { opacity: 0.9; }
        button:disabled { opacity: 0.5; cursor: not-allowed; }
        .btn-primary { background-color: var(--accent); color: var(--bg-white); }
        .btn-success { background-color: var(--success); color: var(--bg-white); }
        .btn-danger { background-color: var(--danger); color: var(--bg-white); }
        .btn-outline { background-color: transparent; border: 1px solid var(--text-light); color: var(--text-light); }
        
        /* Forms */
        .form-group { margin-bottom: 1rem; }
        .form-group label { display: block; font-weight: 600; margin-bottom: 0.5rem; }
        .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 0.5rem; border: 1px solid var(--border); border-radius: 4px; font-family: 'Sarabun'; }
        
        /* Utilities */
        .hidden { display: none !important; }
        .text-center { text-align: center; }
        .alert { padding: 1rem; border-radius: 4px; margin-bottom: 1rem; font-weight: 500; }
        .alert-error { background-color: #fee2e2; color: #991b1b; border: 1px solid #f87171; }
        .alert-info { background-color: #dbeafe; color: #1e40af; border: 1px solid #60a5fa; }
        
        /* Tables */
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
        th, td { border: 1px solid var(--border); padding: 0.75rem; text-align: left; }
        th { background-color: var(--primary-dark); color: var(--text-light); }
        tr:nth-child(even) { background-color: var(--bg-light); }

        /* Media Queries for Mobile (360px+) */
        @media (max-width: 600px) {
            header { flex-direction: column; gap: 0.5rem; text-align: center; }
            table { font-size: 0.85rem; }
            th, td { padding: 0.5rem; }
            .card { padding: 1rem; }
        }

        /* 3D Model Viewer specific */
        model-viewer { width: 100%; height: 400px; background-color: #eee; border-radius: 8px; }
        
        /* Quiz choices */
        .choice-label { display: block; padding: 0.75rem; border: 1px solid var(--border); border-radius: 4px; margin-bottom: 0.5rem; cursor: pointer; }
        .choice-label:hover { background-color: var(--bg-light); }
        .choice-label input { margin-right: 10px; }
    </style>
</head>
<body>

<header>
    <h1 class="header-title">CAI: วิทยาการคำนวณ ความจริงเสริม (AR)</h1>
    <div id="user-menu" class="hidden">
        <span id="user-display-name"></span>
        <button class="btn-outline" style="margin-left: 1rem;" onclick="app.logout()">ออกจากระบบ</button>
    </div>
</header>

<main class="container" id="app-container">
    <!-- View: Setup Error (แสดงเมื่อไม่มี URL/Key) -->
    <div id="view-setup" class="card hidden">
        <div class="card-header" style="background-color: var(--danger);">
            <h2>⚠️ ระบบยังไม่พร้อมใช้งาน (ตั้งค่าไม่สมบูรณ์)</h2>
        </div>
        <p><strong>ผู้สอน/ผู้ดูแลระบบ:</strong> โปรดระบุ <code>SUPABASE_URL</code> และ <code>SUPABASE_ANON_KEY</code> ในส่วนตั้งค่า (Configuration) ต้นไฟล์ <code>courseware.html</code> ก่อนนำไปใช้งาน</p>
        <p>เพื่อความปลอดภัย ห้ามนำ Secret Role Key มาใส่ในไฟล์นี้เด็ดขาด</p>
    </div>

    <!-- View: Auth (เข้าสู่ระบบ / สมัคร) -->
    <div id="view-auth" class="card hidden">
        <div class="card-header"><h2>เข้าสู่ระบบ / ลงทะเบียนผู้เรียน</h2></div>
        <div id="auth-alert" class="alert hidden"></div>
        
        <div id="login-form-container">
            <div class="form-group">
                <label>อีเมล (ผู้สอน) หรือ รหัสนักเรียน 11 หลัก (ผู้เรียน):</label>
                <input type="text" id="auth-identifier" placeholder="เช่น 11111111111 หรือ teacher@school.com">
            </div>
            <div class="form-group">
                <label>รหัสผ่าน:</label>
                <input type="password" id="auth-password">
            </div>
            <button class="btn-primary" onclick="app.login()">เข้าสู่ระบบ</button>
            <hr style="margin: 1.5rem 0; border: 0.5px solid var(--border);">
            <p>สำหรับนักเรียนที่ยังไม่มีบัญชี: <button class="btn-outline" style="color: var(--primary-dark); border-color: var(--primary-dark);" onclick="app.toggleAuthMode('register')">สมัครสมาชิก</button></p>
        </div>

        <div id="register-form-container" class="hidden">
            <div class="form-group">
                <label>รหัสประจำตัวนักเรียน (11 หลัก):</label>
                <input type="text" id="reg-id" maxlength="11">
                <small style="color: #64748b;">* ต้องมีชื่อในระบบแล้ว และใช้อีเมลรูปแบบ รหัส@snru.ac.th อัตโนมัติ</small>
            </div>
            <div class="form-group">
                <label>ตั้งรหัสผ่าน (ขั้นต่ำ 6 ตัวอักษร):</label>
                <input type="password" id="reg-password">
            </div>
            <button class="btn-success" onclick="app.registerStudent()">ลงทะเบียน</button>
            <button class="btn-outline" style="color: var(--primary-dark);" onclick="app.toggleAuthMode('login')">ยกเลิก</button>
        </div>
    </div>

    <!-- View: Teacher Dashboard -->
    <div id="view-teacher" class="hidden">
        <div class="card">
            <div class="card-header"><h2>แผงควบคุมสำหรับผู้สอน</h2></div>
            <div style="margin-bottom: 1rem;">
                <button class="btn-primary" onclick="app.loadTeacherData('students')">ผลการเรียนนักเรียน</button>
                <button class="btn-primary" onclick="app.loadTeacherData('materials')">จัดการสื่อเพิ่มเติม</button>
                <button class="btn-success" onclick="app.exportCSV()">ดาวน์โหลด CSV</button>
            </div>
            <div id="teacher-content"></div>
        </div>
    </div>

    <!-- View: Student Dashboard -->
    <div id="view-student" class="hidden">
        <div class="card">
            <div class="card-header"><h2 id="student-welcome">แดชบอร์ดการเรียน</h2></div>
            <div style="display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1rem;">
                <div style="flex: 1; min-width: 250px; text-align: center;">
                    <img id="student-photo" src="" alt="Profile Photo" style="width: 100px; height: 100px; border-radius: 50%; object-fit: cover; background: #eee; display: block; margin: 0 auto 0.5rem auto;">
                    <input type="file" id="upload-photo" accept="image/png, image/jpeg" class="hidden" onchange="app.uploadProfilePhoto(event)">
                    <button class="btn-outline" style="color: var(--text-main); border-color: var(--border); font-size: 0.8rem;" onclick="document.getElementById('upload-photo').click()">เปลี่ยนรูปโปรไฟล์</button>
                </div>
                <div style="flex: 2; min-width: 250px;">
                    <h3>เส้นทางการเรียนรู้</h3>
                    <ul style="list-style: none; padding: 0;" id="student-path">
                        <!-- ถูกสร้างโดย JS -->
                    </ul>
                </div>
            </div>
            <div id="student-summary" class="alert alert-info hidden"></div>
        </div>
    </div>

    <!-- View: Lesson Content -->
    <div id="view-lesson" class="card hidden">
        <div class="card-header">
            <h2 id="lesson-title">บทเรียน</h2>
        </div>
        <div id="lesson-content"></div>
        <div id="lesson-interspersed" class="hidden" style="margin-top: 2rem; padding: 1rem; background: var(--bg-light); border-radius: 8px;">
            <h3>คำถามทบทวนความเข้าใจ</h3>
            <div id="lesson-question-container"></div>
        </div>
        <div style="margin-top: 1.5rem; display: flex; justify-content: space-between;">
            <button class="btn-outline" style="color: var(--text-main); border-color: var(--text-main);" onclick="app.showStudentDashboard()">กลับหน้าหลัก</button>
            <button id="lesson-next-btn" class="btn-primary" onclick="app.finishUnit()">ทำเครื่องหมายว่าเรียนจบ</button>
        </div>
    </div>

    <!-- View: Quiz -->
    <div id="view-quiz" class="card hidden">
        <div class="card-header">
            <h2 id="quiz-title">แบบทดสอบ</h2>
        </div>
        <div id="quiz-info" class="alert alert-info">กรุณาเลือกคำตอบที่ถูกต้องที่สุดเพียงข้อเดียว</div>
        <div id="quiz-container"></div>
        <div style="margin-top: 1.5rem; text-align: right;">
            <button class="btn-primary" onclick="app.submitQuiz()">ส่งคำตอบ</button>
        </div>
    </div>

</main>

<script>
/** 
 * ==========================================
 * 1. CONFIGURATION
 * ==========================================
 * กำหนด URL และ Key จากหน้า Project Settings -> API ของ Supabase
 * ห้ามฝัง Service Role Key เด็ดขาด ใช้เฉพาะ public anon key เท่านั้น
 */
const SUPABASE_URL = ''; 
const SUPABASE_ANON_KEY = ''; 

/**
 * ==========================================
 * 2. INITIALIZATION & STATE
 * ==========================================
 */
let supabase = null;
const state = {
    user: null,
    role: null, // 'student' or 'teacher'
    studentData: null,
    progress: [],
    attempts: [],
    currentQuizKind: null,
    currentUnit: null,
    quizAnswers: {}
};

// Utilities เพื่อป้องกัน XSS
const sanitizeHTML = (str) => {
    const temp = document.createElement('div');
    temp.textContent = str;
    return temp.innerHTML;
};

const safeCreateElement = (tag, text = '', attributes = {}) => {
    const el = document.createElement(tag);
    if (text) el.textContent = text;
    for (const key in attributes) {
        el.setAttribute(key, attributes[key]);
    }
    return el;
};

const isValidURL = (string) => {
    try {
        const url = new URL(string);
        return url.protocol === 'http:' || url.protocol === 'https:';
    } catch (_) {
        return false;
    }
};

const showAlert = (message, isError = true) => {
    alert(message); // แบบง่าย สำหรับ prototype
};

/**
 * ==========================================
 * 3. CONTENT DATA (เนื้อหาวิชาการตามข้อกำหนด)
 * ==========================================
 */
const COURSE_CONTENT = {
    1: {
        title: "หน่วยที่ 1 พื้นฐานความจริงเสริม",
        body: `
            <p><strong>วัตถุประสงค์:</strong> อธิบายความหมายและองค์ประกอบของเทคโนโลยีความจริงเสริมได้ถูกต้อง</p>
            <h3>ความจริงเสริม (Augmented Reality - AR) คืออะไร?</h3>
            <p>อ้างอิงจาก Azuma (1997) เทคโนโลยีความจริงเสริมต้องประกอบด้วยคุณสมบัติ 3 ประการคือ:</p>
            <ol>
                <li>การผสานโลกจริงกับวัตถุเสมือน (Combines real and virtual)</li>
                <li>การโต้ตอบแบบเรียลไทม์ (Interactive in real time)</li>
                <li>การจัดวางสัมพันธ์กับตำแหน่งในปริภูมิสามมิติ (Registered in 3-D)</li>
            </ol>
            <h3>Reality-Virtuality Continuum</h3>
            <p>Milgram และ Kishino (1994) ได้เสนอแนวคิดแกนความต่อเนื่อง ซึ่งอธิบายว่า AR ไม่ได้แยกขาดจากความจริง (Real Environment) หรือโลกเสมือนทั้งหมด (Virtual Environment - VR) แต่เป็นส่วนหนึ่งของ Mixed Reality (MR) ที่อยู่กึ่งกลาง โดยดึงสภาพแวดล้อมจริงเป็นหลักแล้วเสริมด้วยข้อมูลเสมือน</p>
            <p><strong>ตัวอย่างในห้องเรียน:</strong> การใช้แท็บเล็ตส่องไปที่บัตรคำศัพท์ภาษาอังกฤษ เพื่อให้เกิดภาพสามมิติของสัตว์ชนิดนั้นๆ ปรากฏขึ้นบนโต๊ะเรียน</p>
        `,
        questions: [{
            q: "ตามคำนิยามของ Azuma (1997) ข้อใดไม่ใช่คุณสมบัติหลักของความจริงเสริม (AR)?",
            choices: ["ผสานโลกจริงกับวัตถุเสมือน", "โต้ตอบแบบเรียลไทม์", "ตัดขาดผู้ใช้จากสภาพแวดล้อมจริงทั้งหมด", "จัดวางสัมพันธ์ในตำแหน่งสามมิติ"],
            ans: 2, // 0-based index. ข้อ 3 ผิด (นั่นคือ VR)
            explanation: "คำตอบที่ถูกต้องคือ 'ตัดขาดผู้ใช้จากสภาพแวดล้อมจริงทั้งหมด' เนื่องจาก AR ผสมผสานโลกจริงและเสมือน ไม่ได้ตัดขาดโลกจริง ซึ่งเป็นลักษณะของ VR"
        }]
    },
    2: {
        title: "หน่วยที่ 2 ชนิดและเทคโนโลยี AR",
        body: `
            <p><strong>วัตถุประสงค์:</strong> จำแนกประเภทของเทคโนโลยี AR และข้อจำกัดในการใช้งานได้</p>
            <h3>ประเภทของเทคโนโลยี AR</h3>
            <ul>
                <li><strong>Marker-based:</strong> ใช้รูปภาพหรือสัญลักษณ์เฉพาะ (Marker) เป็นจุดอ้างอิงเพื่อแสดงวัตถุ 3 มิติ เหมาะกับสภาพแวดล้อมที่ควบคุมแสงได้</li>
                <li><strong>Markerless:</strong> ไม่ต้องใช้ Marker แต่ใช้เซ็นเซอร์จับพื้นผิวจริง เช่น พื้นโต๊ะ หรือผนัง (ใช้บ่อยใน WebAR สมัยใหม่)</li>
                <li><strong>Location-based:</strong> ใช้ GPS และเข็มทิศในมือถือเพื่อแสดงข้อมูลตามสถานที่จริง เช่น เกมจับมอนสเตอร์</li>
                <li><strong>Projection-based:</strong> การฉายแสงโปรเจคเตอร์ลงบนพื้นผิวจริงเพื่อสร้างการโต้ตอบ</li>
            </ul>
            <h3>WebAR vs แอปพลิเคชันเนทีฟ</h3>
            <p><strong>WebAR</strong> ทำงานผ่านเบราว์เซอร์โดยไม่ต้องโหลดแอปเพิ่ม แต่มีข้อจำกัดด้านประสิทธิภาพการประมวลผล ส่วน <strong>แอปเนทีฟ</strong> (เช่น แอปใน iOS/Android) เข้าถึงฮาร์ดแวร์ได้ดีกว่าแต่มีขั้นตอนติดตั้ง</p>
            <p><strong>ข้อจำกัด:</strong> AR ไม่ได้รองรับในสมาร์ทโฟนทุกรุ่น โดยเฉพาะ Markerless ที่ต้องใช้เซ็นเซอร์จับความลึก (Depth sensor) การใช้งานยังขึ้นอยู่กับแสงสว่าง อินเทอร์เน็ต และต้องพิจารณาความเป็นส่วนตัวของการเปิดกล้องด้วย</p>
        `,
        questions: [{
            q: "เทคโนโลยี AR ชนิดใดที่อาศัย GPS และเข็มทิศในการกำหนดตำแหน่งแสดงผลมากที่สุด?",
            choices: ["Marker-based", "Location-based", "Projection-based", "WebAR"],
            ans: 1,
            explanation: "Location-based AR ใช้ตำแหน่งทางภูมิศาสตร์จาก GPS ในการทำงาน"
        }]
    },
    3: {
        title: "หน่วยที่ 3 การออกแบบสื่อ AR เพื่อการเรียนรู้",
        body: `
            <p><strong>วัตถุประสงค์:</strong> ประยุกต์ใช้หลักการออกแบบสื่อมัลติมีเดียในการสร้าง AR ได้</p>
            <h3>ภาระทางปัญญา (Cognitive Load) และหลักการของ Mayer</h3>
            <p>ในการออกแบบ AR ต้องระวังไม่ให้เกิดภาระทางปัญญามากเกินไป (Cognitive overload) ควรนำหลักการของ Mayer (Multimedia Learning ฉบับปี 2021) มาปรับใช้ ได้แก่:</p>
            <ul>
                <li><strong>Coherence Principle:</strong> ตัดข้อความ ภาพ หรือเสียงที่ไม่จำเป็นออก ให้เหลือเฉพาะสาระสำคัญ เพื่อไม่ให้รบกวนสมาธิ</li>
                <li><strong>Signaling Principle:</strong> เน้นหรือทำเครื่องหมายจุดที่สำคัญในโมเดล 3 มิติ เพื่อนำสายตาผู้เรียน</li>
                <li><strong>Segmenting Principle:</strong> แบ่งเนื้อหาที่ซับซ้อนออกเป็นช่วงสั้นๆ ให้ผู้เรียนกดไปทีละขั้นแทนการยัดเยียดข้อมูลทั้งหมดในครั้งเดียว</li>
            </ul>
            <h3>การรองรับผู้ใช้ (Accessibility)</h3>
            <p>ประสบการณ์ผู้ใช้สำหรับเด็กประถมต้องเรียบง่าย ปุ่มมีขนาดใหญ่ และเนื่องจากอุปกรณ์บางเครื่องอาจไม่รองรับ AR ครูต้องเตรียม <strong>ทางเลือกสำรอง (Fallback)</strong> เช่น การแสดงโมเดล 3 มิติที่หมุนดูได้บนจอ หรือวิดีโอสาธิตการใช้งาน</p>
        `,
        questions: [{
            q: "หลักการ Coherence Principle ของ Mayer แนะนำให้ปฏิบัติอย่างไรในการออกแบบสื่อ?",
            choices: ["ใส่ภาพเคลื่อนไหวและเสียงดนตรีประกอบให้มากที่สุดเพื่อดึงดูดความสนใจ", "ตัดเนื้อหา รูปภาพ และเสียงที่ไม่เกี่ยวข้องกับวัตถุประสงค์การเรียนรู้ออก", "แบ่งเนื้อหาออกเป็นบทย่อยๆ หลายๆ บท", "ใช้คำอธิบายที่เป็นข้อความควบคู่กับเสียงอ่านตลอดเวลา"],
            ans: 1,
            explanation: "Coherence Principle คือการตัดสิ่งรบกวนที่ไม่จำเป็นออก เพื่อลดภาระทางปัญญา"
        }]
    },
    4: {
        title: "หน่วยที่ 4 ปฏิบัติ: สร้างสื่อ WebAR ขั้นพื้นฐาน",
        body: `
            <p><strong>วัตถุประสงค์:</strong> สามารถใช้งานและแสดงผลโมเดล 3 มิติผ่าน WebAR ได้</p>
            <p>หน่วยนี้เราจะใช้แท็ก <code>&lt;model-viewer&gt;</code> ซึ่งเป็นมาตรฐานเปิดของเว็บในการแสดงผล AR ขั้นตอนมีดังนี้:</p>
            <ol>
                <li>เตรียมไฟล์โมเดล 3 มิติ นามสกุล <code>.glb</code></li>
                <li>ฝากไฟล์โมเดลไว้บนเซิร์ฟเวอร์ที่รองรับ <code>HTTPS</code> (เช่น Supabase Storage)</li>
                <li>เขียนโค้ดฝังในเว็บ: <code>&lt;model-viewer src="ลิงก์ไฟล์.glb" ar ar-modes="webxr scene-viewer quick-look" camera-controls&gt;&lt;/model-viewer&gt;</code></li>
            </ol>
            <p><strong>ทดสอบโมเดลจำลอง:</strong> ลองใช้เมาส์หรือนิ้วหมุนดูโมเดลด้านล่าง หากอุปกรณ์ของนักเรียนรองรับ AR จะมีปุ่ม "เปิดในโหมด AR" ปรากฏขึ้นมุมล่างขวา (ข้อจำกัด: อาจไม่แสดงผลในมือถือรุ่นเก่าที่ไม่มี ARCore/ARKit)</p>
            <div style="margin: 1.5rem 0; border: 2px dashed var(--border); padding: 1rem; border-radius: 8px;">
                <model-viewer 
                    src="https://modelviewer.dev/shared-assets/models/Astronaut.glb" 
                    ios-src="https://modelviewer.dev/shared-assets/models/Astronaut.usdz" 
                    alt="นักบินอวกาศ" 
                    ar 
                    ar-modes="webxr scene-viewer quick-look" 
                    camera-controls 
                    auto-rotate>
                    <!-- Fallback เมื่อไม่รองรับ AR -->
                    <div slot="poster" style="display:flex; justify-content:center; align-items:center; height:100%; color:#666;">กำลังโหลดโมเดล...</div>
                </model-viewer>
                <p class="text-center" style="font-size: 0.85rem; margin-top:0.5rem; color: #64748b;">(หมายเหตุ: นี่คือโมเดลจำลองสำหรับการสาธิตจาก ModelViewer.dev)</p>
            </div>
            <h3>การส่งงาน</h3>
            <p>ให้นักเรียนสร้างชิ้นงาน และอัปโหลดไฟล์ภาพหน้าจอ (PNG/JPEG) หรือส่งเป็นลิงก์ผ่านระบบที่หน้าแรก</p>
        `,
        questions: [{
            q: "นามสกุลไฟล์มาตรฐานใดที่แนะนำให้ใช้กับ <model-viewer> เพื่อการแสดงผล 3 มิติบนเว็บ?",
            choices: [".mp4", ".glb", ".docx", ".pdf"],
            ans: 1,
            explanation: "ไฟล์ .glb (GL Transmission Format) เป็นรูปแบบมาตรฐานที่มีขนาดเล็กและรวมพื้นผิวไว้ในไฟล์เดียว เหมาะกับ WebAR"
        }]
    },
    5: {
        title: "หน่วยที่ 5 การทดสอบและประเมินสื่อ AR",
        body: `
            <p><strong>วัตถุประสงค์:</strong> เข้าใจวิธีการประเมินประสิทธิภาพสื่อ AR ทางการศึกษา</p>
            <h3>ตัวชี้วัดและการประเมิน</h3>
            <ul>
                <li><strong>การทดสอบผู้ใช้จริง (Usability Testing):</strong> ให้กลุ่มเป้าหมายลองใช้งานและบันทึกปัญหาที่พบ เช่น ความยากในการเปิดโหมด AR</li>
                <li><strong>ดัชนีความสอดคล้อง (IOC):</strong> วิธีของ Rovinelli และ Hambleton (1977) ใช้ผู้เชี่ยวชาญตรวจสอบความสอดคล้องระหว่างข้อสอบกับวัตถุประสงค์ โดยเกณฑ์ทั่วไปที่ยอมรับคือ IOC &ge; 0.50 (ทั้งนี้ผู้วิจัยควรตรวจสอบเกณฑ์ดั้งเดิมของต้นฉบับก่อนอ้างอิงเสมอ)</li>
                <li><strong>ประสิทธิภาพ E1/E2 (80/80):</strong> E1 คือร้อยละคะแนนระหว่างเรียน (เช่น คำถามท้ายบท) E2 คือร้อยละคะแนนแบบทดสอบหลังเรียน ค่าทั้งสองคำนวณจาก (คะแนนรวม/คะแนนเต็ม) x 100 </li>
                <li><strong>Normalized Gain (Hake, 1998):</strong> ค่าพัฒนาการสัมพัทธ์ สูตรคือ <code>g = (Post - Pre) / (Full - Pre)</code> ใช้ดูความก้าวหน้า หมายเหตุ: เกณฑ์ตีความของ Hake (สูง กลาง ต่ำ) ออกแบบมาสำหรับ "ค่าเฉลี่ยของกลุ่ม" ไม่ควรใช้ตัดสินเกรดหรือผลการเรียนของ "รายบุคคล" โดยอัตโนมัติ</li>
            </ul>
        `,
        questions: [{
            q: "หากนักเรียนได้คะแนนก่อนเรียน 4 คะแนน และคะแนนหลังเรียน 7 คะแนน (คะแนนเต็ม 10) ค่า Normalized gain จะมีค่าเท่าใด?",
            choices: ["0.3", "0.5", "0.7", "3.0"],
            ans: 1,
            explanation: "คำนวณจาก (7 - 4) / (10 - 4) = 3 / 6 = 0.5"
        }]
    }
};

/**
 * ==========================================
 * 4. QUIZ DATA (เก็บเฉพาะคำถามและตัวเลือก ห้ามฝังเฉลย!)
 * ==========================================
 */
const QUIZ_SETS = {
    A: [
        { q: "1. เทคโนโลยี AR หมายถึงข้อใด?", choices: ["การสร้างโลกเสมือนทั้งหมด", "การนำวัตถุเสมือนมาซ้อนทับบนโลกจริง", "การใช้งานเครือข่ายอินเทอร์เน็ต", "การสวมแว่นตาVRเพื่อเล่นเกม"] },
        { q: "2. ผู้ใดเป็นผู้เสนอคุณสมบัติ 3 ประการของ AR ในปี 1997?", choices: ["Mayer", "Hake", "Azuma", "Milgram"] },
        { q: "3. AR จัดอยู่ในส่วนใดของ Reality-Virtuality Continuum?", choices: ["Mixed Reality", "Virtual Reality", "Real Environment", "Unreal Engine"] },
        { q: "4. Marker-based AR ทำงานอย่างไร?", choices: ["ใช้ GPS ระบุตำแหน่ง", "ตรวจจับใบหน้าผู้ใช้", "ใช้เสียงสั่งการ", "ใช้ภาพสัญลักษณ์เป็นจุดอ้างอิง"] },
        { q: "5. ข้อจำกัดสำคัญของการใช้ WebAR ในห้องเรียนคืออะไร?", choices: ["ต้องติดตั้งแอปพลิเคชันที่มีขนาดใหญ่", "จำเป็นต้องใช้อินเทอร์เน็ตและเบราว์เซอร์ที่รองรับ", "รองรับเฉพาะระบบ iOS เท่านั้น", "ไม่สามารถแสดงภาพ 3 มิติได้"] },
        { q: "6. หลักการ Coherence ของ Mayer ในการทำ AR คืออะไร?", choices: ["ใส่สีสันให้มากที่สุด", "เพิ่มเสียงเพลงบรรเลงตลอดเวลา", "ตัดเนื้อหาที่ไม่จำเป็นเพื่อลดภาระทางปัญญา", "ให้ผู้เรียนสวมแว่นสามมิติ"] },
        { q: "7. การแบ่งเนื้อหา AR เป็นช่วงสั้นๆ ตรงกับหลักการใด?", choices: ["Segmenting Principle", "Signaling Principle", "Spatial Contiguity", "Modality Principle"] },
        { q: "8. นามสกุลไฟล์ใดที่นิยมใช้ใน <model-viewer>?", choices: [".mp3", ".jpg", ".doc", ".glb"] },
        { q: "9. ค่า IOC ใช้ประเมินสิ่งใด?", choices: ["ความเร็วของแอปพลิเคชัน", "ความสอดคล้องของข้อสอบกับวัตถุประสงค์", "ความพึงพอใจของผู้เรียน", "ความละเอียดของโมเดล 3 มิติ"] },
        { q: "10. Normalized Gain ใช้คำนวณอะไร?", choices: ["พัฒนาการทางการเรียนเปรียบเทียบก่อนและหลัง", "ประสิทธิภาพการทำงานของเซิร์ฟเวอร์", "ขนาดของไฟล์ที่ใช้อัปโหลด", "เวลาเฉลี่ยที่ใช้ในระบบ"] }
    ],
    B: [
        { q: "1. ตามแนวคิดของ Milgram และ Kishino (1994) AR จัดอยู่ในกลุ่มใด?", choices: ["Virtual Environment", "Real Environment", "Mixed Reality", "Physical Reality"] },
        { q: "2. ข้อใดคือคุณสมบัติของ AR ตามนิยามของ Azuma (1997)?", choices: ["ผสานโลกจริงและเสมือน, โต้ตอบเรียลไทม์, สามมิติ", "ต้องใช้แว่น VR เท่านั้น", "ทำงานโดยไม่ใช้อินเทอร์เน็ต", "เป็นการดูวิดีโอ 360 องศา"] },
        { q: "3. AR รูปแบบใดที่อาศัยพิกัดภูมิศาสตร์ (GPS)?", choices: ["Marker-based", "Projection-based", "Markerless", "Location-based"] },
        { q: "4. การใช้มือถือส่องหาพื้นที่ราบเพื่อวางวัตถุ 3 มิติ เป็น AR ชนิดใด?", choices: ["Marker-based", "Markerless", "Location-based", "WebAR-only"] },
        { q: "5. การออกแบบสื่อที่ดีเพื่อลดภาระทางปัญญา (Cognitive overload) ควรทำอย่างไร?", choices: ["เน้นสาระสำคัญและตัดสิ่งรบกวน", "ใส่ข้อมูลทุกอย่างไว้ในหน้าเดียว", "ใช้เอฟเฟกต์แสงสีให้ตื่นตาตื่นใจ", "เพิ่มคำศัพท์ภาษาอังกฤษให้มากที่สุด"] },
        { q: "6. การทำลูกศรชี้เน้นส่วนสำคัญในโมเดล 3 มิติ สอดคล้องกับหลักการใดของ Mayer?", choices: ["Coherence Principle", "Segmenting Principle", "Redundancy Principle", "Signaling Principle"] },
        { q: "7. แท็ก HTML มาตรฐานใดที่ใช้เปิดโหมด AR สำหรับไฟล์ .glb?", choices: ["<video-ar>", "<model-viewer>", "<ar-canvas>", "<3d-object>"] },
        { q: "8. หากอุปกรณ์ไม่รองรับ AR ระบบควรจัดการอย่างไรจึงจะเหมาะสมกับนักเรียนประถม?", choices: ["หักคะแนนนักเรียน", "ไม่อนุญาตให้เรียนบทนั้น", "มีภาพ 3 มิติหรือวิดีโอให้ดูเป็นทางเลือกสำรอง", "บังคับให้ผู้ปกครองซื้อโทรศัพท์ใหม่"] },
        { q: "9. ค่า E1 ในเกณฑ์ประสิทธิภาพ 80/80 หมายถึงข้อใด?", choices: ["ร้อยละของคะแนนระหว่างเรียน", "ร้อยละของคะแนนสอบปลายภาค", "ร้อยละของนักเรียนที่เข้าเรียน", "ร้อยละของคะแนนแบบทดสอบหลังเรียน"] },
        { q: "10. สูตรการหาค่า Normalized Gain (Hake) มีตัวส่วนเป็นอะไร?", choices: ["คะแนนหลังเรียน", "คะแนนก่อนเรียน", "คะแนนเต็ม - คะแนนหลังเรียน", "คะแนนเต็ม - คะแนนก่อนเรียน"] }
    ]
};

/**
 * ==========================================
 * 5. CORE APPLICATION LOGIC
 * ==========================================
 */
const app = {
    init: async function() {
        if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
            document.getElementById('view-setup').classList.remove('hidden');
            return;
        }

        try {
            supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            const { data: { session } } = await supabase.auth.getSession();
            
            if (session) {
                await this.handleSession(session);
            } else {
                this.showView('view-auth');
            }
        } catch (err) {
            console.error("Init error:", err);
            document.getElementById('view-setup').classList.remove('hidden');
        }
    },

    handleSession: async function(session) {
        state.user = session.user;
        
        // เช็คบทบาท (Teacher or Student)
        const { data: isTeacher } = await supabase.rpc('is_teacher');
        if (isTeacher) {
            state.role = 'teacher';
            document.getElementById('user-display-name').textContent = 'ผู้สอน';
            document.getElementById('user-menu').classList.remove('hidden');
            this.showView('view-teacher');
            this.loadTeacherData('students');
        } else {
            // เช็คว่าเป็นนักเรียนหรือไม่
            const { data: student, error } = await supabase.from('students').select('*').eq('user_id', state.user.id).single();
            if (student) {
                state.role = 'student';
                state.studentData = student;
                document.getElementById('user-display-name').textContent = `${student.title}${student.first_name} ${student.last_name}`;
                document.getElementById('user-menu').classList.remove('hidden');
                await this.loadStudentDashboard();
            } else {
                // บัญชีทั่วไปที่ยังไม่ผูก หรือ ผูกไม่สำเร็จ
                showAlert('บัญชีของคุณยังไม่ได้เชื่อมโยงกับข้อมูลนักเรียน หรือคุณไม่มีสิทธิ์เข้าถึงระบบ', true);
                this.logout();
            }
        }
    },

    login: async function() {
        const identifier = document.getElementById('auth-identifier').value.trim();
        const password = document.getElementById('auth-password').value;
        const alertBox = document.getElementById('auth-alert');
        
        if (!identifier || !password) return this.uiAlert(alertBox, 'กรุณากรอกข้อมูลให้ครบถ้วน', true);

        // ถ้าระบุ 11 หลัก ให้แปลงเป็นอีเมลอัตโนมัติ
        let email = identifier;
        if (/^\d{11}$/.test(identifier)) {
            email = `${identifier}@snru.ac.th`;
        }

        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        
        if (error) {
            this.uiAlert(alertBox, 'เข้าสู่ระบบล้มเหลว: ตรวจสอบข้อมูลผู้ใช้และรหัสผ่าน', true);
        } else {
            window.location.reload();
        }
    },

    registerStudent: async function() {
        const studentId = document.getElementById('reg-id').value.trim();
        const password = document.getElementById('reg-password').value;
        const alertBox = document.getElementById('auth-alert');

        if (!/^\d{11}$/.test(studentId)) return this.uiAlert(alertBox, 'รหัสประจำตัวนักเรียนต้องเป็นตัวเลข 11 หลัก', true);
        if (password.length < 6) return this.uiAlert(alertBox, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร', true);

        const email = `${studentId}@snru.ac.th`;

        // สั่งสร้าง Auth User
        const { data, error } = await supabase.auth.signUp({ email, password });
        
        if (error) {
            if(error.message.includes("already registered")) {
                this.uiAlert(alertBox, 'บัญชีนี้มีอยู่ในระบบแล้ว โปรดเข้าสู่ระบบ', true);
            } else {
                this.uiAlert(alertBox, 'การสมัครล้มเหลว: ' + error.message, true);
            }
            return;
        }

        // ล็อกอินแล้วเรียก RPC เพื่อผูกบัญชี (เนื่องจาก Confirm email ปิดอยู่)
        const { data: linkSuccess, error: linkErr } = await supabase.rpc('link_student_account', { p_student_id: studentId });
        
        if (linkErr || !linkSuccess) {
            this.uiAlert(alertBox, 'ผูกบัญชีนักเรียนไม่สำเร็จ รหัสนักเรียนอาจผิดซ้ำ หรือมีคนใช้แล้ว', true);
            await supabase.auth.signOut();
        } else {
            alert('ลงทะเบียนและผูกบัญชีสำเร็จ!');
            window.location.reload();
        }
    },

    logout: async function() {
        await supabase.auth.signOut();
        window.location.reload();
    },

    toggleAuthMode: function(mode) {
        document.getElementById('auth-alert').classList.add('hidden');
        if(mode === 'register') {
            document.getElementById('login-form-container').classList.add('hidden');
            document.getElementById('register-form-container').classList.remove('hidden');
        } else {
            document.getElementById('register-form-container').classList.add('hidden');
            document.getElementById('login-form-container').classList.remove('hidden');
        }
    },

    showView: function(viewId) {
        const views = ['view-setup', 'view-auth', 'view-teacher', 'view-student', 'view-lesson', 'view-quiz'];
        views.forEach(v => {
            const el = document.getElementById(v);
            if (el) el.classList.add('hidden');
        });
        document.getElementById(viewId).classList.remove('hidden');
    },

    uiAlert: function(element, message, isError) {
        element.textContent = message;
        element.className = `alert ${isError ? 'alert-error' : 'alert-info'}`;
        element.classList.remove('hidden');
    },

    /* =======================================
       STUDENT LOGIC
       ======================================= */
    loadStudentDashboard: async function() {
        this.showView('view-student');
        
        // Load Photo
        const photoEl = document.getElementById('student-photo');
        if (state.studentData.photo_path) {
            const { data } = await supabase.storage.from('photos').createSignedUrl(state.studentData.photo_path, 60);
            if(data && data.signedUrl) photoEl.src = data.signedUrl;
        } else {
            photoEl.src = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect width="100" height="100" fill="#cbd5e1"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="30" fill="#fff">📷</text></svg>';
        }

        // Load Progress & Attempts
        const [{ data: progress }, { data: attempts }] = await Promise.all([
            supabase.from('progress').select('unit').eq('done', true),
            supabase.from('attempts').select('kind, score')
        ]);
        
        state.progress = progress ? progress.map(p => p.unit) : [];
        state.attempts = attempts || [];

        this.renderStudentPath();
        this.renderStudentSummary();
    },

    renderStudentPath: function() {
        const pathEl = document.getElementById('student-path');
        pathEl.innerHTML = '';
        
        const hasPre = state.attempts.some(a => a.kind === 'pre');
        const hasPost = state.attempts.some(a => a.kind === 'post');
        const unitsDone = state.progress.length;

        // Pre-test
        pathEl.appendChild(this.createPathItem('ก่อนเรียน', 'แบบทดสอบก่อนเรียน', hasPre, true, () => this.startQuiz('pre')));
        
        // Units 1-5
        for(let i = 1; i <= 5; i++) {
            const isUnlocked = hasPre && (i === 1 || state.progress.includes(i-1));
            const isDone = state.progress.includes(i);
            pathEl.appendChild(this.createPathItem(`หน่วย ${i}`, COURSE_CONTENT[i].title, isDone, isUnlocked, () => this.openUnit(i)));
        }

        // Post-test
        const postUnlocked = unitsDone === 5 && !hasPost;
        pathEl.appendChild(this.createPathItem('หลังเรียน', 'แบบทดสอบหลังเรียน', hasPost, postUnlocked, () => this.startQuiz('post')));
    },

    createPathItem: function(label, title, isDone, isUnlocked, onClick) {
        const li = document.createElement('li');
        li.style.padding = '0.75rem';
        li.style.border = '1px solid var(--border)';
        li.style.marginBottom = '0.5rem';
        li.style.borderRadius = '4px';
        li.style.display = 'flex';
        li.style.justifyContent = 'space-between';
        li.style.alignItems = 'center';
        li.style.backgroundColor = isDone ? '#ecfdf5' : (isUnlocked ? '#fff' : '#f1f5f9');

        const textDiv = document.createElement('div');
        const strong = document.createElement('strong');
        strong.textContent = label + ': ';
        textDiv.appendChild(strong);
        textDiv.appendChild(document.createTextNode(title));

        const btn = document.createElement('button');
        if (isDone) {
            btn.textContent = 'ทำแล้ว/ทบทวน';
            btn.className = 'btn-outline';
            btn.style.color = 'var(--success)';
            btn.style.borderColor = 'var(--success)';
            btn.onclick = onClick;
        } else if (isUnlocked) {
            btn.textContent = 'เข้าสู่บทเรียน';
            btn.className = 'btn-primary';
            btn.onclick = onClick;
        } else {
            btn.textContent = 'ล็อก';
            btn.className = 'btn-outline';
            btn.disabled = true;
        }

        li.appendChild(textDiv);
        li.appendChild(btn);
        return li;
    },

    renderStudentSummary: async function() {
        const sumEl = document.getElementById('student-summary');
        sumEl.innerHTML = '';
        
        const hasPost = state.attempts.some(a => a.kind === 'post');
        if (!hasPost) {
            sumEl.classList.add('hidden');
            return;
        }

        // Fetch results via View to get gain safely
        const { data, error } = await supabase.from('results').select('pre_score, post_score, normalized_gain').eq('id', state.studentData.id).single();
        
        if (data) {
            sumEl.classList.remove('hidden');
            const p1 = document.createElement('p');
            p1.textContent = `คะแนนก่อนเรียน: ${data.pre_score}/10 | คะแนนหลังเรียน: ${data.post_score}/10`;
            sumEl.appendChild(p1);

            const p2 = document.createElement('p');
            p2.innerHTML = `<strong>Normalized Gain:</strong> ${data.normalized_gain}`;
            sumEl.appendChild(p2);

            const p3 = document.createElement('p');
            p3.style.fontSize = '0.8rem';
            p3.textContent = '*หมายเหตุ: เกณฑ์ตีความของ Hake (1998) ออกแบบมาสำหรับใช้แปลผลค่าเฉลี่ยของกลุ่ม ไม่ใช่เกณฑ์จัดระดับผู้เรียนรายบุคคล';
            sumEl.appendChild(p3);
        }
    },

    startQuiz: function(kind) {
        state.currentQuizKind = kind;
        state.quizAnswers = {};
        this.showView('view-quiz');
        
        // Determine Set (Even ID -> Pre A/Post B, Odd -> Pre B/Post A)
        const idLastDigit = parseInt(state.studentData.id.slice(-1));
        const isEven = idLastDigit % 2 === 0;
        const set = (kind === 'pre') ? (isEven ? 'A' : 'B') : (isEven ? 'B' : 'A');
        
        document.getElementById('quiz-title').textContent = `แบบทดสอบ${kind === 'pre' ? 'ก่อน' : 'หลัง'}เรียน (ชุด ${set})`;
        
        const qContainer = document.getElementById('quiz-container');
        qContainer.innerHTML = '';
        
        const questions = QUIZ_SETS[set];
        questions.forEach((q, idx) => {
            const div = document.createElement('div');
            div.style.marginBottom = '1.5rem';
            
            const p = document.createElement('p');
            p.style.fontWeight = '600';
            p.textContent = q.q;
            div.appendChild(p);
            
            q.choices.forEach((choice, cIdx) => {
                const label = document.createElement('label');
                label.className = 'choice-label';
                
                const input = document.createElement('input');
                input.type = 'radio';
                input.name = `q_${idx+1}`;
                input.value = cIdx + 1;
                input.onchange = (e) => { state.quizAnswers[idx+1] = parseInt(e.target.value); };
                
                label.appendChild(input);
                label.appendChild(document.createTextNode(choice));
                div.appendChild(label);
            });
            qContainer.appendChild(div);
        });
    },

    submitQuiz: async function() {
        if(Object.keys(state.quizAnswers).length < 10) {
            return alert('กรุณาตอบคำถามให้ครบ 10 ข้อ');
        }

        const btn = document.querySelector('#view-quiz .btn-primary');
        btn.disabled = true;
        btn.textContent = 'กำลังส่งข้อมูล...';

        try {
            // Call RPC Secure Function
            const { data, error } = await supabase.rpc('submit_attempt_secure', {
                p_kind: state.currentQuizKind,
                p_answers: state.quizAnswers
            });

            if (error) throw error;
            
            alert(data.message + (data.score !== undefined ? `\nคะแนนของคุณคือ: ${data.score}/10` : ''));
            await this.loadStudentDashboard();

        } catch (err) {
            console.error(err);
            alert('เกิดข้อผิดพลาด: ' + err.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'ส่งคำตอบ';
        }
    },

    openUnit: function(unitNum) {
        state.currentUnit = unitNum;
        this.showView('view-lesson');
        
        const content = COURSE_CONTENT[unitNum];
        document.getElementById('lesson-title').textContent = content.title;
        document.getElementById('lesson-content').innerHTML = content.body; // ใช้ innerHTML เฉพาะข้อมูลที่เขียนฮาร์ดโค้ดเองในระบบ ไม่ใช่รับจาก DB

        // Setup Interspersed Questions (Client-side validation limitation)
        const qContainer = document.getElementById('lesson-question-container');
        qContainer.innerHTML = '';
        
        if (content.questions && content.questions.length > 0) {
            document.getElementById('lesson-interspersed').classList.remove('hidden');
            document.getElementById('lesson-next-btn').disabled = true;
            
            content.questions.forEach((q, idx) => {
                const div = document.createElement('div');
                div.style.marginBottom = '1rem';
                div.textContent = q.q;
                
                const select = document.createElement('select');
                select.className = 'form-group';
                select.style.width = '100%';
                select.style.marginTop = '0.5rem';
                
                const optDef = document.createElement('option');
                optDef.value = ""; optDef.textContent = "-- เลือกคำตอบ --";
                select.appendChild(optDef);
                
                q.choices.forEach((c, i) => {
                    const opt = document.createElement('option');
                    opt.value = i; opt.textContent = c;
                    select.appendChild(opt);
                });

                const feedback = document.createElement('div');
                feedback.style.marginTop = '0.5rem';
                feedback.style.fontSize = '0.9rem';

                select.onchange = () => {
                    if (parseInt(select.value) === q.ans) {
                        feedback.textContent = "✅ ถูกต้อง: " + q.explanation;
                        feedback.style.color = "var(--success)";
                        document.getElementById('lesson-next-btn').disabled = false; // Prototype limitation check
                    } else {
                        feedback.textContent = "❌ ยังไม่ถูกต้อง ลองพิจารณาใหม่อีกครั้ง";
                        feedback.style.color = "var(--danger)";
                        document.getElementById('lesson-next-btn').disabled = true;
                    }
                };

                qContainer.appendChild(div);
                qContainer.appendChild(select);
                qContainer.appendChild(feedback);
            });
        } else {
            document.getElementById('lesson-interspersed').classList.add('hidden');
            document.getElementById('lesson-next-btn').disabled = false;
        }

        // Add Submission form for Unit 4
        if (unitNum === 4) {
            this.renderSubmissionForm();
        }
    },

    renderSubmissionForm: function() {
        const formDiv = document.createElement('div');
        formDiv.style.marginTop = '2rem';
        formDiv.style.padding = '1.5rem';
        formDiv.style.border = '1px solid var(--border)';
        formDiv.style.borderRadius = '8px';
        
        formDiv.innerHTML = `
            <h3>ส่งงานปฏิบัติ (เฉพาะลิงก์เท่านั้นเพื่อความปลอดภัยในเวอร์ชัน Prototype)</h3>
            <div class="form-group">
                <label>URL ของผลงาน (ต้องขึ้นต้นด้วย http:// หรือ https://)</label>
                <input type="url" id="submit-url" placeholder="https://...">
            </div>
            <button class="btn-primary" onclick="app.submitWork()">ส่งงาน</button>
            <div id="submit-msg" class="alert hidden" style="margin-top: 1rem;"></div>
        `;
        document.getElementById('lesson-content').appendChild(formDiv);
    },

    submitWork: async function() {
        const url = document.getElementById('submit-url').value.trim();
        const msgEl = document.getElementById('submit-msg');
        
        if (!isValidURL(url)) return this.uiAlert(msgEl, 'URL ไม่ถูกต้อง', true);

        try {
            const { error } = await supabase.from('submissions').insert({
                user_id: state.user.id,
                unit: 4,
                kind: 'link',
                url: url
            });
            if (error) throw error;
            this.uiAlert(msgEl, 'ส่งงานสำเร็จ', false);
        } catch (err) {
            this.uiAlert(msgEl, 'เกิดข้อผิดพลาด: ' + err.message, true);
        }
    },

    finishUnit: async function() {
        const unit = state.currentUnit;
        if (!state.progress.includes(unit)) {
            // INSERT to progress securely (RLS checks user_id)
            const { error } = await supabase.from('progress').insert({
                user_id: state.user.id,
                unit: unit,
                done: true
            });
            if (error) {
                console.error("Progress save error:", error);
                alert("เกิดข้อผิดพลาดในการบันทึกความก้าวหน้า");
                return;
            }
        }
        await this.loadStudentDashboard();
    },

    uploadProfilePhoto: function(event) {
        const file = event.target.files[0];
        if (!file) return;

        // Resize & Upload logic (HTML5 Canvas)
        const reader = new FileReader();
        reader.onload = (e) => {
            const img = new Image();
            img.onload = async () => {
                const canvas = document.createElement('canvas');
                const MAX_WIDTH = 400;
                const MAX_HEIGHT = 400;
                let width = img.width;
                let height = img.height;

                if (width > height) {
                    if (width > MAX_WIDTH) { height *= MAX_WIDTH / width; width = MAX_WIDTH; }
                } else {
                    if (height > MAX_HEIGHT) { width *= MAX_HEIGHT / height; height = MAX_HEIGHT; }
                }
                
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);
                
                canvas.toBlob(async (blob) => {
                    const ext = file.name.split('.').pop();
                    const path = `${state.user.id}/profile_${Date.now()}.${ext}`;
                    
                    try {
                        // Upload to Storage
                        const { error: uploadError } = await supabase.storage.from('photos').upload(path, blob, { upsert: true });
                        if (uploadError) throw uploadError;

                        // Update Database column (RLS policy handles security)
                        const { error: dbError } = await supabase.from('students').update({ photo_path: path }).eq('id', state.studentData.id);
                        if (dbError) throw dbError;

                        alert('อัปเดตรูปโปรไฟล์สำเร็จ');
                        this.loadStudentDashboard();

                    } catch (err) {
                        alert('อัปโหลดล้มเหลว: ' + err.message);
                    }
                }, 'image/jpeg', 0.8);
            };
            img.src = e.target.result;
        };
        reader.readAsDataURL(file);
    },

    showStudentDashboard: function() {
        this.showView('view-student');
    },

    /* =======================================
       TEACHER LOGIC
       ======================================= */
    loadTeacherData: async function(tab) {
        const contentDiv = document.getElementById('teacher-content');
        contentDiv.innerHTML = '<p>กำลังโหลดข้อมูล...</p>';
        
        if (tab === 'students') {
            // ดึงข้อมูลผ่าน View `results` ซึ่งมี Normalized gain แล้ว
            const { data, error } = await supabase.from('results').select('*').order('id', { ascending: true });
            
            if (error) {
                contentDiv.textContent = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ' + error.message;
                return;
            }

            const table = document.createElement('table');
            table.innerHTML = `
                <thead>
                    <tr>
                        <th>รหัส</th>
                        <th>ชื่อ-สกุล</th>
                        <th>ห้อง</th>
                        <th>ก่อนเรียน</th>
                        <th>ชุด</th>
                        <th>หลังเรียน</th>
                        <th>ชุด</th>
                        <th>Gain</th>
                    </tr>
                </thead>
                <tbody></tbody>
            `;
            
            const tbody = table.querySelector('tbody');
            data.forEach(s => {
                const tr = document.createElement('tr');
                // Use safeCreateElement or textContent to prevent XSS
                const addCell = (text) => { const td = document.createElement('td'); td.textContent = text || '-'; tr.appendChild(td); };
                
                addCell(s.id);
                addCell(`${s.title}${s.first_name} ${s.last_name}`);
                addCell(s.section);
                addCell(s.pre_score !== null ? s.pre_score : '-');
                addCell(s.pre_set);
                addCell(s.post_score !== null ? s.post_score : '-');
                addCell(s.post_set);
                addCell(s.normalized_gain !== null ? s.normalized_gain : '-');
                
                tbody.appendChild(tr);
            });
            contentDiv.innerHTML = '';
            contentDiv.appendChild(table);
        } else if (tab === 'materials') {
            contentDiv.innerHTML = '<p>ระบบจัดการสื่อสารยังอยู่ในช่วงพัฒนาต้นแบบ (Prototype)</p>';
        }
    },

    exportCSV: async function() {
        const { data, error } = await supabase.from('results').select('*').order('id', { ascending: true });
        if (error) return alert("Export failed");

        let csv = '\uFEFF'; // UTF-8 BOM
        csv += 'รหัส,คำนำหน้า,ชื่อ,นามสกุล,ห้อง,ก่อนเรียน,ชุด,หลังเรียน,ชุด,NormalizedGain\n';

        const sanitize = (str) => {
            if (str == null) return '';
            let s = String(str);
            // Escape Formula Injection
            if (s.startsWith('=') || s.startsWith('+') || s.startsWith('-') || s.startsWith('@')) {
                s = "'" + s; 
            }
            // Escape quotes and commas
            s = s.replace(/"/g, '""');
            if (s.includes(',') || s.includes('\n') || s.includes('"')) {
                s = `"${s}"`;
            }
            return s;
        };

        data.forEach(row => {
            csv += [
                sanitize(row.id), sanitize(row.title), sanitize(row.first_name), sanitize(row.last_name),
                sanitize(row.section), sanitize(row.pre_score), sanitize(row.pre_set),
                sanitize(row.post_score), sanitize(row.post_set), sanitize(row.normalized_gain)
            ].join(',') + '\n';
        });

        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.setAttribute("href", url);
        link.setAttribute("download", "student_results.csv");
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
};

// Start App when DOM is loaded
document.addEventListener('DOMContentLoaded', () => app.init());
</script>

</body>
</html>