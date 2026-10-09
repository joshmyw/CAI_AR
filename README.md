[README.md](https://github.com/user-attachments/files/33241072/README.md)
# ระบบ CAI วิทยาการคำนวณ เรื่องความจริงเสริม (AR)

โปรเจกต์นี้คือ คอร์สแวร์ (Computer-Assisted Instruction: CAI) รายวิชา วิทยาการคำนวณ รหัสวิชา 2103404 สำหรับนักเรียนชั้นประถมศึกษาปีที่ 4 พัฒนาขึ้นในรูปแบบ Web Application แบบหน้าเดียว (Single Page Application) โดยเน้นความปลอดภัยของข้อมูลและการจัดการสิทธิ์ผู้ใช้งานอย่างรัดกุม

## 🌟 ฟีเจอร์หลัก (Features)

### สำหรับผู้เรียน (Students)
* **ระบบจัดการบัญชี:** สมัครสมาชิกและเข้าสู่ระบบด้วยรหัสประจำตัวนักเรียน 11 หลัก (ตรวจสอบกับฐานข้อมูล)
* **การเรียนรู้ตามลำดับ (Sequential Learning):** บังคับทำแบบทดสอบก่อนเรียน -> เรียนหน่วยที่ 1-5 -> ทำแบบทดสอบหลังเรียน
* **บทเรียน AR โต้ตอบได้:** แสดงผลโมเดล 3 มิติผ่าน `<model-viewer>` รองรับการดูแบบ WebAR บนอุปกรณ์ที่รองรับ
* **แบบทดสอบ (Quiz):** สุ่มชุดข้อสอบ (A/B) ตามเลขประจำตัว ตรวจคำตอบและคำนวณคะแนนฝั่ง Backend เพื่อป้องกันข้อสอบรั่วไหล
* **การส่งงาน:** อัปโหลดไฟล์ (จำกัดขนาดและประเภท) หรือส่งลิงก์ผลงานได้
* **การประเมินผล:** แสดงคะแนนและคำนวณค่าความก้าวหน้า (Normalized Gain) อัตโนมัติ

### สำหรับผู้สอน (Teachers)
* **แดชบอร์ด:** ดูความก้าวหน้าและคะแนนของนักเรียนทุกคนแบบเรียลไทม์
* **ตรวจงาน:** เรียกดูลิงก์หรือดาวน์โหลดไฟล์ผลงานที่นักเรียนส่ง
* **ส่งออกข้อมูล:** ส่งออกคะแนนผลการเรียนเป็นไฟล์ `.csv` (รองรับภาษาไทย ป้องกัน Formula Injection)

## 🛠 เทคโนโลยีที่ใช้ (Tech Stack)

* **Frontend:** HTML5, CSS3 (Vanilla), JavaScript (ES6) - *รวมอยู่ในไฟล์เดียวเพื่อความสะดวกในการนำไปใช้*
* **Backend / Database:** [Supabase](https://supabase.com/) (PostgreSQL, GoTrue Auth, Storage)
* **AR Component:** [`<model-viewer>`](https://modelviewer.dev/) (เวอร์ชัน 4.0.0)
* **Font:** Google Fonts (Sarabun)

## 📂 โครงสร้างไฟล์ (File Structure)

1. `setup.sql` - สคริปต์สำหรับรันใน Supabase SQL Editor เพื่อสร้าง Tables, Schema, Security Definer Functions, Row Level Security (RLS) และ Storage Policies
2. `courseware.html` - ไฟล์โปรแกรมหลักที่รวม UI และ Logic การทำงานทั้งหมดไว้ในไฟล์เดียว
3. `documentation.md` - เอกสารคู่มือการติดตั้งแบบละเอียด ตารางกรณีทดสอบระบบ และรายการตรวจสอบสำหรับผู้สอน
4. `README.md` - ไฟล์เอกสารแนะนำโปรเจกต์นี้

## 🔒 ความปลอดภัย (Security Highlights)

* **Row Level Security (RLS):** ผู้เรียนเข้าถึงได้เฉพาะข้อมูลของตนเองเท่านั้น
* **Backend Grading:** เฉลยถูกเก็บใน `private` schema การตรวจคำตอบทำผ่าน RPC (Remote Procedure Call)
* **No Secrets in Frontend:** โค้ดฝั่ง Client มีเฉพาะ URL และ `anon_key` (Public) เท่านั้น ไม่มี Service Role Key
* **Storage Policies:** จำกัดขนาดไฟล์ ประเภทไฟล์ (MIME Type) และสิทธิ์การอัปโหลด/ดาวน์โหลดของแต่ละโฟลเดอร์ผู้ใช้

## 🚀 การเริ่มต้นใช้งานเบื้องต้น (Quick Start)

1. สร้างโปรเจกต์ใน Supabase และรันคำสั่งจาก `setup.sql`
2. คัดลอก `Project URL` และ `anon public key` จาก Supabase
3. เปิดไฟล์ `courseware.html` และนำค่าไปวางในตัวแปร `SUPABASE_URL` และ `SUPABASE_ANON_KEY`
4. เปิดไฟล์ `courseware.html` ผ่านเบราว์เซอร์เพื่อใช้งานได้ทันที

*(โปรดดูขั้นตอนการตั้งค่าผู้สอนและการนำเข้ารายชื่อนักเรียนอย่างละเอียดในไฟล์ `documentation.md`)*

## 📚 แหล่งอ้างอิงทางวิชาการ (Academic References)
* Azuma, R. T. (1997). A Survey of Augmented Reality. *Presence: Teleoperators and Virtual Environments*, 6(4), 355-385.
* Milgram, P., & Kishino, F. (1994). A Taxonomy of Mixed Reality Visual Displays. *IEICE Transactions on Information and Systems*, E77-D(12), 1321-1329.
* Mayer, R. E. (2021). *Multimedia Learning* (3rd ed.). Cambridge University Press.
* Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content specialists in the assessment of criterion-referenced test item validity. *Dutch Journal of Educational Research*, 2, 49-60.
* Hake, R. R. (1998). Interactive-engagement versus traditional methods: A six-thousand-student survey of mechanics test data for introductory physics courses. *American Journal of Physics*, 66(1), 64-74.
