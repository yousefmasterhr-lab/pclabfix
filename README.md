# ApexCare Engine (Beast Edition) 🚀⚡
**Enterprise-Grade Autonomous Windows Performance Tuning, Diagnostics, Kernel Optimization & Deep System Maintenance Suite**

ApexCare Engine (Beast Edition) هي أداة متطورة وشاملة صُممت لتعمل كأداة تحسين أداء خارقة (Beast Mode)، وتشخيص فائق للعتاد، وتحديث للتعريفات، وإصلاح عميق واستقرار لنظام ويندوز مع واجهة Modern Fluent TUI ودعم كامل لاستمرار العمل بعد إعادة التشغيل (Reboot Survival).

---

## ⚡ التشغيل الفوري بسطر واحد (In-Memory Web Execution)
يمكنك تشغيل الأداة مباشرة في الذاكرة الحية (RAM) دون الحاجة لتحميل مسبق عبر فتح **PowerShell كمسؤول (Run as Administrator)** واستخدام أي من الرابطين:

### 1. الرابط السريع المختصر (Recommended):
```powershell
irm tinyurl.com/pclabfix | iex
```

### 2. الرابط المباشر من GitHub:
```powershell
irm https://raw.githubusercontent.com/yousefmasterhr-lab/pclabfix/main/ApexCare.ps1 | iex
```

### 3. التشغيل بضغطة زر واحدة (1-Click Launcher):
إذا قمت بتحميل المشروع محلياً، يمكنك ببساطة النقر المزدوج على ملف **`ApexCare.bat`** وسيقوم بطلب صلاحية المسؤول وتشغيل الأداة مباشرة.

---

## 🛠️ البنية البرمجية والوحدات الرئيسية (Beast Architecture)

### 1. 🖥️ واجهة مستخدم رسومية حديثة ومتوافقة 100% (Modern Fluent TUI)
- تصميم احترافي مستوحى من أدوات سطر الأوامر المؤسسية بألوان Cyberpunk وإطارات متوافقة مع كافة بيئات PowerShell 5.1 و 7 وCMD.
- قائمة تفاعلية مرقمة بدقة تسمح بتشغيل الطيار الآلي الكامل أو اختيار وحدات صيانة محددة.

### 2. ⚡ تسريع الشبكة وإلغاء القيود (Network Stack Turbocharging)
- تصفية كاش DNS وجداول توجيه ARP وتصفير Winsock ومكدس TCP/IP.
- تفعيل ميزات الأداء القصوى: TCP Window Auto-Tuning إلى Normal، وتقنية Receive-Side Scaling (RSS)، وتفعيل TCP Fast Open.
- إلغاء تقييد حزم الوسائط والشبكة في الويندوز نهائياً عبر ضبط `NetworkThrottlingIndex = 0xFFFFFFFF` و `SystemResponsiveness = 0`.

### 3. 🚀 استجابة المعالج والنواة القصوى (CPU & Kernel Peak Responsiveness)
- تفعيل وتكرار خطة الطاقة الخارقة **Ultimate Performance** مع الرجوع التلقائي إلى High Performance في حال تقييد العتاد.
- تعطيل ميزة Fast Startup (`Hiberboot`) لضمان مسح النواة وإعادة تشغيل كود الويندوز بنقاء كامل.
- تقليص تأخير القوائم والنوافذ `MenuShowDelay` إلى 0ms لاستجابة فورية.
- إيقاف تسجيل زمن الوصول الأخير للأقراص (`fsutil behavior set disablelastaccess 1`) لمنع الكتابات المستمرة على وحدات التخزين.
- فرض تفعيل نمط الألعاب التلقائي (Auto Game Mode Scheduling).

### 4. 🎮 تسريع كروت الشاشة وعرض الرسوميات (GPU Beast Mode)
- تفعيل جدولة معالجة الرسومات المسرّعة عتادياً (Hardware-Accelerated GPU Scheduling - HAGS).
- تفعيل معدل التحديث المتغير العالمي (Variable Refresh Rate - VRR).
- توجيه أولويات الرسوميات في الويندوز لتفضيل معالجات الرسومات المنفصلة عالية الأداء (Discrete High-Performance GPU).
- كشف نوع كارت الشاشة تلقائياً (NVIDIA, AMD, Intel Arc) وتثبيت البرمجيات المعتمدة رسمياً عبر Winget.

### 5. 🧠 تفريغ الذاكرة المؤقتة وتنظيف التخزين (Standby RAM Purge & TRIM)
- تفريغ واستعادة مساحات العمل للعمليات الخاملة في الرام (Working Sets) بأمان عبر استدعاءات Win32 API (`EmptyWorkingSet`) دون إغلاق البرامج.
- تنظيف شامل للملفات المؤقتة، Prefetch، SoftwareDistribution، وذاكرة التخزين المؤقتة للمتصفحات.
- تحسين وحدات NVMe/SSD عبر أمر TRIM على مستوى الكتل التخزينية.

### 6. 🛡️ إزالة الخدمات الخاملة وأدوات التتبع بأمان (Safe Telemetry Debloat)
- إيقاف وتعطيل خدمات التعقب غير الأساسية بأمان دون المساس بـ Windows Update أو Microsoft Store (`DiagTrack`, `dmwappushservice`).
- تعطيل مهام برنامج تحسين تجربة المستخدم (CEIP) ومهام تجميع القياس عن بُعد.

### 7. 🔧 إصلاح مستودع وصور النظام النواة (Core OS Image Repair)
- فحص وإصلاح مستودع مكونات النظام باستخدام `DISM /Online /Cleanup-Image /RestoreHealth /NoRestart`.
- فحص وتصحيح ملفات النظام المحمية باستخدام `SFC /scannow`.

### 8. 🌐 مركز دعم وموقع الشركات المصنعة (OEM Ecosystem & Driver Servicing)
- التعرف الذكي على نوع الجهاز وسيريال الشركة المصنعة (Dell, HP, Lenovo, Acer, ASUS, MSI, Gigabyte, Samsung, Huawei, Surface, Intel/AMD).
- توفير الروابط الرسمية المباشرة لأدوات الفحص وصفحات التعريفات المخصصة لجهازك مع إمكانية فتحها مباشرة في المتصفح.
- فحص مستودع مايكروسوفت الرسمي وتثبيت تعريفات الأجهزة والملحقات المعلقة عبر `PSWindowsUpdate`.

### 9. 📦 ترقية حزمة البرامج المثبتة (Winget Fleet Upgrade)
- تحديث كافة التطبيقات والبرامج المثبتة على الويندوز دفعة واحدة من مصادرها الرسمية بأمر واحد.

### 10. 🛡️ نقطة استعادة النظام التلقائية (System Restore Point Safeguard)
- تفعيل خدمة وحماية استعادة النظام على القرص C: وإنشاء نقطة استعادة فورية باسم `ApexCare Pre-Optimization` قبل أي تعديل عميق.

### 11. 🎮 وضع ألعاب فائق الاستجابة وزمن وصول منخفض (Gamer Latency & Core Unparking)
- تعطيل خوارزمية Nagle (`TcpAckFrequency = 1` و `TCPNoDelay = 1`) لإلغاء أي تأخير في إرسال حزم البيانات في الألعاب التنافسية (Valorant, CS2, Fortnite).
- رفع أولوية جدولة معالجة خيوط الألعاب في خدمة `MMCSS` إلى High.
- فك حظر أنوية المعالج (Disable CPU Core Parking) بنسبة 100% لمنع التقطيع والـ Micro-Stutters أثناء الضغط العالي.

### 12. 🌐 مسرع ومبدل الـ DNS بنقرة واحدة (DNS Turbo Switcher)
- التبديل الفوري مع تنظيف الكاش بين أسرع وأأمن مزودات الـ DNS:
  - Cloudflare Gaming DNS (`1.1.1.1` / `1.0.0.1`)
  - Google Public DNS (`8.8.8.8` / `8.8.4.4`)
  - AdGuard Anti-Ad DNS (`94.140.14.14` / `94.140.15.15`)
  - Quad9 Threat Blocking DNS (`9.9.9.9` / `149.112.112.112`)
  - استعادة التوزيع التلقائي الأصلي (DHCP / Router Default).

### 13. 🪟 تخصيصات وتخفيف ويندوز 11 (Windows 11 Power Tweaks)
- استعادة قائمة الكليك يمين الكاملة الكلاسيكية لويندوز 10 وإلغاء اختصار "Show more options" بضغطة زر واحدة.
- تعطيل أدوات شريط المهام الثقيلة (Taskbar Widgets و Copilot والبحث المزعج) لتوفير الذاكرة واستجابة المعالج.
- إمكانية التراجع والعودة للقائمة الحديثة لويندوز 11 في أي وقت.

### 14. 🏥 طبيب تحديثات ويندوز وإعادة الضبط (Windows Update Doctor)
- حل أعطال التحديثات العالقة وأكواد الخطأ المستعصية (مثل `0x80070002` و `0x80240034`).
- إيقاف الخدمات المعنية وتصفير وإعادة بناء مستودعات `SoftwareDistribution` و `Catroot2` وتصفير مكدس Winsock ثم إعادة تشغيل الخدمات وفحص التحديثات بنقاء كامل.

### 15. 📊 التقرير البصري التفاعلي الداكن (Cyberpunk HTML Dashboard)
- تصدير ملف HTML كامل ومستقل ومصمم بأسلوب Dark Mode أنيق يتضمن رسوماً بيانية وأشرطة تقدم لنسب استهلاك الرام، كروت الشاشة، مساحات الأقراص، نوع الوسائط (NVMe/SSD/HDD)، ونسبة تآكل بطارية اللابتوب مع الفتح التلقائي في المتصفح.

### 16. 🔄 استعادة ضبط المصنع والتراجع عن كافة التحسينات (Factory Defaults & Undo Engine)
- وحدة متكاملة تسمح للمستخدم في أي لحظة بإلغاء التعديلات وإرجاع خطة الطاقة إلى Balanced، وإعادة تفعيل Fast Startup وخدمات القياس عن بُعد، وتصفير الـ DNS وخوارزميات الشبكة إلى الإعدادات الأصلية الافتراضية لويندوز بنقرة واحدة.

### 17. 🔄 نظام البقاء بعد إعادة التشغيل (Deterministic State Machine)
- تسجيل تقدم المراحل عبر `$env:ProgramData\ApexCare\state.json`.
- حقن استئناف فوري في مسار `HKLM:\...\RunOnce` بحيث إذا استدعى تثبيت تعريف أو ملف نظام إعادة تشغيل إجبارية، يستأنف المحرك عمله تلقائياً فور تسجيل الدخول من المرحلة التالية دون تكرار ما تم إنجازه.

---

## 🛠️ تحويل الأداة إلى ملف تنفيذي (.exe)

لتحويل السكريبت إلى تطبيق تنفيذي مستقل يطلب صلاحيات الأدمن تلقائياً:

```powershell
# 1. تثبيت حزمة ps2exe
Install-Module -Name ps2exe -Scope CurrentUser -Force

# 2. إنشاء الملف التنفيذي
Invoke-PS2EXE -InputFile ".\ApexCare.ps1" -OutputFile ".\ApexCare.exe" -RequireAdmin -Title "ApexCare Engine (Beast Edition)" -Description "Enterprise Autonomous Windows Performance & Diagnostics Suite" -NoConsole:$false
```

---

## 📋 المتطلبات (Requirements)
- **نظام التشغيل**: Windows 10 (1903+) / Windows 11 / Windows Server 2019+
- **الصلاحيات**: Administrator (يتضمن السكريبت فحصاً ذاتياً للصعود التلقائي للصلاحيات)
- **بيئة التشغيل**: PowerShell 5.1 أو PowerShell 7+
