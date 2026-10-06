# Watcha

แอป Flutter สำหรับจัดการรายการหนังและซีรีส์ส่วนตัวในธีมมืด

- Dashboard พร้อมจำนวน Wishlist, Watching และ Completed
- ค้นหาชื่อรายการ, filter ตามหมวด และแสดง empty state
- เพิ่ม/แก้ไขรายการ พร้อมตรวจสอบชื่อและปีที่ออกฉาย
- เปลี่ยนสถานะ, ให้คะแนน 1–5 เฉพาะรายการที่ดูจบแล้ว และเขียนหมายเหตุ
- เปิดรายละเอียดและลบรายการพร้อม dialog ยืนยัน
- สมัครสมาชิก/เข้าสู่ระบบจริงด้วย REST API และ JWT
- เก็บ session เพื่อกลับเข้าแอปได้หลังปิดเปิดใหม่ และออกจากระบบได้
- เพิ่มโปสเตอร์ด้วย URL และบันทึกลิงก์รับชมสำหรับแต่ละรายการ

## โครงสร้างและการต่อยอด

`lib/main.dart` มี `ApiClient` ที่เชื่อมต่อ backend จริงและส่ง JWT ในทุก request ที่ต้องยืนยันตัวตน
โดย endpoint ที่ใช้มีดังนี้

```text
GET    /api/watchlist?status=watching&search=...
POST   /api/watchlist
PUT    /api/watchlist/:id
DELETE /api/watchlist/:id
POST   /api/auth/login
POST   /api/auth/register
GET    /api/auth/profile
POST   /api/auth/logout
```

## เริ่ม backend และเชื่อมแอป

1. ตั้งค่า `serverapi_ts/.env` จาก `serverapi_ts/.env.example` และกำหนด `JWT_SECRET`
   (ถ้าไม่กำหนดใน development ระบบจะใช้ secret สำหรับ local ชั่วคราวและจะแจ้งเตือนใน console;
   production จะไม่ยอมให้ server เริ่มทำงานโดยไม่มี `JWT_SECRET`)
2. สร้างฐานข้อมูลและ migration:

```bash
cd serverapi_ts
npm install
npm run db:setup
npm start
```

3. รัน Flutter:

```bash
cd ..
flutter pub get
flutter run
```

ค่า API เริ่มต้นคือ `http://10.0.2.2:3000/api` สำหรับ Android emulator และ
`http://localhost:3000/api` สำหรับ Web, iOS simulator และ desktop หากใช้ IP หรือ port อื่น
ให้กำหนดตอนรันด้วย:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Flutter ไม่ได้เชื่อม MySQL โดยตรง ฐานข้อมูลถูกเข้าถึงผ่าน backend เท่านั้น โดย backend
บังคับ foreign key, unique email, index `(user_id, status)` และกฎ rating 1–5

### เพิ่มโปสเตอร์และลิงก์รับชมจากในแอป

ในหน้า `เพิ่มรายการใหม่` หรือ `แก้ไขรายการ`:

1. กรอกข้อมูลหนังตามปกติ
2. ถ้ามีลิงก์รูป ให้กรอกที่ช่อง `URL โปสเตอร์`
3. กรอกลิงก์ของบริการสตรีมมิงในช่อง `ลิงก์รับชม` (ถ้ามี)
4. กด `บันทึกรายการ` แล้วเปิดลิงก์ได้จากหน้ารายละเอียด

รูปจะไม่ถูกอัปโหลดไปยัง backend แอปใช้ URL โดยตรงและแสดง placeholder
เมื่อ URL ว่างหรือโหลดไม่ได้ โดย URL จะถูกบันทึกใน `watchlist.poster_url`
และลิงก์รับชมใน `watchlist.watch_url` ผ่าน JSON API


## ตรวจสอบคุณภาพ

```bash
cd serverapi_ts
npm test
npm run build

cd ..
flutter analyze
flutter test
```
