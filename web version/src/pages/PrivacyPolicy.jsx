import React, { useState } from "react";
import "../styles/privacyPolicy.css";
import "../styles/ProgramEpisodes.css";

const AR = {
  title: "سياسة الخصوصية",
  intro:
    "مرحبًا بكم في makkahtv.tv، القناة التلفزيونية التي تقدم محتوى الفيديو  والبرامج. توضح هذه السياسة كيف نجمع بياناتكم الشخصية ونستخدمها ونحميها.",
  sections: [
    {
      heading: "1. البيانات التي نجمعها",
      items: [
        "البيانات التي تقدمها بنفسك: الاسم، البريد الإلكتروني، ورقم الهاتف عند التسجيل أو التواصل معنا.",
        "بيانات الاستخدام: الصفحات التي تزورها، الفيديوهات التي تشاهدها، وتفضيلاتك.",
        "البيانات التقنية: عنوان IP، نوع المتصفح، نظام التشغيل، وملفات تعريف الارتباط (الكوكيز).",
      ],
    },
    {
      heading: "2. استخدام البيانات",
      items: [
        "توفير الخدمات والمحتوى على موقعنا وتحسينها.",
        "التواصل معك، بما في ذلك إرسال الإشعارات والعروض إذا وافقت على ذلك.",
        "التحليل والإحصاءات لفهم استخدام الموقع وتحسين أدائه.",
        "الامتثال للقوانين واللوائح المعمول بها.",
      ],
    },
    {
      heading: "3. مشاركة البيانات",
      intro: "قد نشارك بياناتك مع:",
      items: [
        "مزودي الخدمات التقنية، مثل خدمات التحليلات والاستضافة، بموجب اتفاقيات تضمن حماية بياناتك.",
        "الجهات القانونية أو التنظيمية إذا تطلب القانون ذلك.",
      ],
    },
    {
      heading: "4. حفظ البيانات وحمايتها",
      items: [
        "نحتفظ ببياناتك للفترة اللازمة لتحقيق الأغراض التي جُمعت من أجلها فقط، ثم نحذفها بطريقة آمنة مع مراعاة المتطلبات القانونية.",
        "نتخذ التدابير التقنية والتنظيمية المناسبة لحماية بياناتك من الوصول غير المصرح به أو التعديل أو الفقدان أو الكشف.",
      ],
    },
    {
      heading: "5. حقوقك",
      items: [
        "معرفة ما إذا كنا نعالج بياناتك، والوصول إليها.",
        "تصحيح بياناتك أو طلب حذفها.",
        "سحب موافقتك في أي وقت، أو طلب تقييد المعالجة.",
      ],
    },
    {
      heading: "6. التعديلات على السياسة",
      items: [
        "قد نحدّث هذه السياسة من وقت لآخر، وننشر أي تغييرات على هذه الصفحة مع تاريخ آخر تحديث.",
      ],
    },
    {
      heading: "7. الاتصال بنا",
      intro: "لأي أسئلة أو طلبات تتعلق ببياناتك أو حقوقك، يمكنك مراسلتنا عبر:",
      items: ["البريد الإلكتروني: info@makkahtv.tv"],
    },
  ],
};

const EN = {
  title: "Privacy Policy",
  intro:
    "Welcome to makkahtv.tv, the television channel providing video content, news, and programs. This policy explains how we collect, use, and protect your personal data.",
  sections: [
    {
      heading: "1. Data We Collect",
      items: [
        "Data you provide: your name, email address, and phone number when you register or contact us.",
        "Usage data: the pages you visit, the videos you watch, and your preferences.",
        "Technical data: IP address, browser type, operating system, and cookies.",
      ],
    },
    {
      heading: "2. How We Use Your Data",
      items: [
        "Providing and improving the services and content on our website.",
        "Communicating with you, including sending notifications and offers if you have consented.",
        "Analysis and statistics to understand how the website is used and improve its performance.",
        "Complying with applicable laws and regulations.",
      ],
    },
    {
      heading: "3. Data Sharing",
      intro: "We may share your data with:",
      items: [
        "Technical service providers, such as analytics and hosting services, under agreements that ensure your data is protected.",
        "Legal or regulatory authorities, where required by law.",
      ],
    },
    {
      heading: "4. Data Retention & Security",
      items: [
        "We retain your data only for as long as needed to fulfill the purposes for which it was collected, then delete it securely, subject to legal requirements.",
        "We take appropriate technical and organizational measures to protect your data from unauthorized access, alteration, loss, or disclosure.",
      ],
    },
    {
      heading: "5. Your Rights",
      items: [
        "To know whether we are processing your data, and to access it.",
        "To correct your data or request its deletion.",
        "To withdraw your consent at any time, or request restriction of processing.",
      ],
    },
    {
      heading: "6. Changes to This Policy",
      items: [
        "We may update this policy from time to time, and will post any changes on this page along with the date of the last update.",
      ],
    },
    {
      heading: "7. Contact Us",
      intro: "For any questions or requests regarding your data or your rights, you can reach us at:",
      items: ["Email: info@makkahtv.tv"],
    },
  ],
};

const PrivacyPolicy = () => {
  const [lang, setLang] = useState("ar");
  const isRTL = lang === "ar";
  const data = isRTL ? AR : EN;

  const lastUpdated = isRTL
    ? new Intl.DateTimeFormat("ar-SA", { year: "numeric", month: "long", day: "numeric" }).format(new Date())
    : new Intl.DateTimeFormat("en-US", { year: "numeric", month: "long", day: "numeric" }).format(new Date());

  return (
    <div className="privacy-wrapper" dir={isRTL ? "rtl" : "ltr"}>
      <div className="container privacy-container">
        <div className="privacy-lang-toggle">
          <button type="button" className={isRTL ? "active" : ""} onClick={() => setLang("ar")}>
            العربية
          </button>
          <button type="button" className={!isRTL ? "active" : ""} onClick={() => setLang("en")}>
            English
          </button>
        </div>

        <h1 className="section-title">
          <span className="title-bar"></span>
          {data.title}
        </h1>

        <p className="privacy-updated">
          {isRTL ? `آخر تحديث: ${lastUpdated}` : `Last updated: ${lastUpdated}`}
        </p>

        <p className="privacy-intro">{data.intro}</p>

        {data.sections.map((sec, i) => (
          <section className="privacy-section" key={i}>
            <h2>{sec.heading}</h2>
            {sec.intro && <p>{sec.intro}</p>}
            {sec.items && (
              <ul>
                {sec.items.map((item, j) => (
                  <li key={j}>{item}</li>
                ))}
              </ul>
            )}
          </section>
        ))}
      </div>
    </div>
  );
};

export default PrivacyPolicy;
