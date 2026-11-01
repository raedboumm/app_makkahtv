import React, { useState } from "react";
import "../styles/privacyPolicy.css";
import "../styles/ProgramEpisodes.css";

const AR = {
  title: "سياسة الخصوصية",
  intro:
    "مرحبًا بكم في makkahtv.tv. نحن نولي خصوصيتكم أهمية كبيرة، ونسعى من خلال هذه السياسة إلى شرح كيف نجمع بياناتكم الشخصية، كيف نستخدمها، وكيف نحميها، وذلك بما يتوافق مع قانون حماية البيانات الشخصية في المملكة العربية السعودية (PDPL).",
  sections: [
    {
      heading: "1. من نحن",
      items: [
        "اسم الجهة: makkahtv.tv",
        "الغرض من الموقع: منصة تلفزيونية / إعلامية تقدم محتوى فيديو، أخبار، برامج، وغيرها.",
        "وسائل الاتصال:",
        "البريد الإلكتروني: info@makkahtv.tv",
        "العنوان: (سيُضاف لاحقًا)",
        "الجهة المسؤولة عن حماية البيانات (إن وجدت): (ستُضاف بياناتها عند تعيينها)",
      ],
    },
    {
      heading: "2. البيانات التي نجمعها",
      intro: "نقوم بجمع ومعالجة أنواع مختلفة من البيانات الشخصية، ومنها:",
      items: [
        "البيانات التي تقدمها بنفسك: الاسم، البريد الإلكتروني، رقم الهاتف (إذا تطلب التسجيل أو الاشتراك)",
        "بيانات استخدام الموقع: مثل الصفحات التي تزورها، الفيديوهات التي تشاهدها، المدة التي تقضيها، تفضيلاتك.",
        "بيانات تقنية: عنوان IP، نوع المتصفح، نظام التشغيل، بيانات الكوكيز (ملفات تعريف الارتباط).",
      ],
    },
    {
      heading: "3. كيف نجمع البيانات؟",
      items: [
        "مباشرة من المستخدم عند التسجيل أو التواصل معنا.",
        "عبر ملفات تعريف الارتباط (\"كوكيز\") وتحليلات الويب.",
        "قد نستقبل بعض البيانات من طرف ثالث إذا كنت تتفاعل مع شركائنا (بشروط واضحة).",
      ],
    },
    {
      heading: "4. استخدام البيانات (أغراض المعالجة)",
      intro: "نستخدم بياناتك لأغراض مثل:",
      items: [
        "توفير وتحسين الخدمات والمحتوى على موقعنا.",
        "التواصل معك: إرسال إشعارات، تحديثات، عروض، أو رسائل دعائية إذا وافقت.",
        "التحليل والإحصاءات: لفهم كيف يستخدم المستخدمون الموقع وتحسين الأداء.",
        "الامتثال للقوانين واللوائح: مثل التزاماتنا بموجب PDPL.",
      ],
    },
    {
      heading: "5. الأساس القانوني لمعالجة البيانات",
      intro: "نعالج بياناتك اعتمادًا على:",
      items: [
        "موافقتك (عندما يكون ذلك مناسبًا).",
        "مصلحتنا المشروعة (مثل تحسين الموقع وتحليل الاستخدام).",
        "الالتزام القانوني (إذا تطلب القانون ذلك).",
      ],
    },
    {
      heading: "6. مشاركة البيانات",
      intro: "قد نشارك بياناتك مع:",
      items: [
        "شركائنا التقنيين (مثل مزودي خدمات التحليلات أو الاستضافة)",
        "الجهات القانونية أو التنظيمية إن تطلب الأمر بموجب القانون",
        "مقدمي خدمات تابعين لنا ولكن بموجب اتفاقيات تضمن حماية بياناتك",
      ],
    },
    {
      heading: "7. حفظ البيانات والتدمير",
      items: [
        "نحتفظ ببياناتك فقط للفترة التي نحتاجها لتحقيق الأغراض التي جُمِعت من أجلها.",
        "عند انتهاء الحاجة لاستخدام بياناتك، سنقوم بحذفها بطريقة آمنة بحيث لا يمكن استرجاعها، مع مراعاة أي متطلبات قانونية.",
      ],
    },
    {
      heading: "8. حقوقك بموجب PDPL",
      intro: "بموجب قانون حماية البيانات الشخصية (PDPL)، لديك حقوق، منها:",
      items: [
        "الحق في معرفة ما إذا كنا نعالج بياناتك.",
        "الحق في الوصول إلى بياناتك الشخصية.",
        "الحق في تصحيح بياناتك إذا كانت غير دقيقة.",
        "الحق في حذف بياناتك (\"النسيان\").",
        "الحق في سحب الموافقة في أي وقت (إذا كانت المعالجة قائمة على موافقة).",
        "الحق في طلب تقييد المعالجة.",
      ],
    },
    {
      heading: "9. الأمان",
      items: [
        "نتخذ التدابير التقنية والتنظيمية المناسبة لحماية بياناتك من الوصول غير المصرح به، أو التعديل، أو الفقدان، أو الكشف. وتشمل هذه التدابير تشفير البيانات، مراقبة الأنظمة، وتدريب فريق العمل.",
      ],
    },
    {
      heading: "10. نقل البيانات دوليًا",
      items: [
        "إذا قمنا بنقل بعض البيانات خارج المملكة العربية السعودية، فسنضمن وجود ضمانات مناسبة تضمن حماية بياناتك وفقًا للوائح نقل البيانات الشخصية.",
      ],
    },
    {
      heading: "11. التعديلات على سياسة الخصوصية",
      items: [
        "قد نقوم بتحديث هذه السياسة من وقت لآخر. سنقوم بنشر أي تغييرات على هذه الصفحة مع تحديد تاريخ آخر تحديث. يُنصح بمراجعة هذه السياسة بشكل دوري لمعرفة التحديثات.",
      ],
    },
    {
      heading: "12. كيفية الاتصال بنا",
      intro: "إذا كان لديك أي أسئلة أو طلبات تتعلق ببياناتك أو حقوقك بموجب هذه السياسة، يمكنك الاتصال بنا عبر:",
      items: ["البريد الإلكتروني: info@makkahtv.tv"],
    },
  ],
};

const EN = {
  title: "Privacy Policy",
  intro:
    "Welcome to makkahtv.tv. We place great importance on your privacy, and through this policy we aim to explain how we collect your personal data, how we use it, and how we protect it, in accordance with the Personal Data Protection Law (PDPL) of the Kingdom of Saudi Arabia.",
  sections: [
    {
      heading: "1. Who We Are",
      items: [
        "Entity name: makkahtv.tv",
        "Purpose of the website: a television/media platform providing video content, news, programs, and more.",
        "Contact methods:",
        "Email: info@makkahtv.tv",
        "Address: (to be added)",
        "Data Protection Officer (if applicable): (to be added once designated)",
      ],
    },
    {
      heading: "2. Data We Collect",
      intro: "We collect and process various types of personal data, including:",
      items: [
        "Data you provide yourself: name, email address, phone number (if registration or subscription is required).",
        "Website usage data: such as the pages you visit, the videos you watch, time spent, and your preferences.",
        "Technical data: IP address, browser type, operating system, and cookie data.",
      ],
    },
    {
      heading: "3. How We Collect Data",
      items: [
        "Directly from you when you register or contact us.",
        "Through cookies and web analytics.",
        "We may receive some data from third parties if you interact with our partners (under clear terms).",
      ],
    },
    {
      heading: "4. How We Use Your Data",
      intro: "We use your data for purposes such as:",
      items: [
        "Providing and improving the services and content on our website.",
        "Communicating with you: sending notifications, updates, offers, or promotional messages if you have consented.",
        "Analysis and statistics: to understand how users use the website and to improve performance.",
        "Complying with laws and regulations, including our obligations under the PDPL.",
      ],
    },
    {
      heading: "5. Legal Basis for Processing",
      intro: "We process your data based on:",
      items: [
        "Your consent (where applicable).",
        "Our legitimate interest (such as improving the website and analyzing usage).",
        "Legal obligation (where required by law).",
      ],
    },
    {
      heading: "6. Data Sharing",
      intro: "We may share your data with:",
      items: [
        "Our technical partners (such as analytics or hosting providers).",
        "Legal or regulatory authorities, where required by law.",
        "Affiliated service providers, under agreements that ensure your data is protected.",
      ],
    },
    {
      heading: "7. Data Retention & Deletion",
      items: [
        "We retain your data only for as long as necessary to fulfill the purposes for which it was collected.",
        "Once it is no longer needed, we delete it securely so it cannot be recovered, in line with any applicable legal requirements.",
      ],
    },
    {
      heading: "8. Your Rights under the PDPL",
      intro: "Under the Personal Data Protection Law (PDPL), your rights include:",
      items: [
        "The right to know whether we are processing your data.",
        "The right to access your personal data.",
        "The right to correct your data if it is inaccurate.",
        "The right to have your data deleted (\"the right to be forgotten\").",
        "The right to withdraw consent at any time (where processing is based on consent).",
        "The right to request restriction of processing.",
      ],
    },
    {
      heading: "9. Security",
      items: [
        "We take appropriate technical and organizational measures to protect your data from unauthorized access, alteration, loss, or disclosure. These measures include data encryption, system monitoring, and staff training.",
      ],
    },
    {
      heading: "10. International Data Transfers",
      items: [
        "If we transfer data outside the Kingdom of Saudi Arabia, we ensure appropriate safeguards are in place to protect it in accordance with personal data transfer regulations.",
      ],
    },
    {
      heading: "11. Changes to This Policy",
      items: [
        "We may update this policy from time to time. Any changes will be posted on this page along with the date of the last update. We recommend reviewing this policy periodically.",
      ],
    },
    {
      heading: "12. Contact Us",
      intro: "If you have any questions or requests regarding your data or your rights under this policy, you can reach us at:",
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
