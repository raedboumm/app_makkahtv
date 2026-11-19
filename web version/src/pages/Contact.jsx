import React, { useCallback, useEffect, useRef, useState } from 'react';
import '../styles/contact.css'; // Assuming we'll create this
import { useNavigate } from 'react-router-dom';
import { fetchCaptcha, sendContactMessage } from '../services/siteConfig';

const REDIRECT_SECONDS = 5;

const Contact = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    nom: '',
    prenom: '',
    adresse: '',
    telephone: '',
    sujet: '',
    message: ''
  });

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const [status, setStatus] = useState({ state: 'idle', text: '' });

  // CAPTCHA: each image works for one send only, so a new one is loaded
  // after every attempt (right or wrong).
  const [captcha, setCaptcha] = useState({ token: '', image: '', loading: true, error: '' });
  const [captchaAnswer, setCaptchaAnswer] = useState('');
  const captchaInputRef = useRef(null);

  const loadCaptcha = useCallback(async () => {
    setCaptcha((c) => ({ ...c, loading: true, error: '' }));
    setCaptchaAnswer('');
    try {
      const { token, image } = await fetchCaptcha();
      setCaptcha({ token, image, loading: false, error: '' });
    } catch (err) {
      setCaptcha({ token: '', image: '', loading: false, error: err.message });
    }
  }, []);

  useEffect(() => {
    loadCaptcha();
  }, [loadCaptcha]);

  // Sent to the back office, where it shows up in the "رسائل الموقع" table.
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (status.state === 'sending') return;
    if (!captchaAnswer.trim()) {
      setStatus({ state: 'error', text: 'أدخل رمز التحقق الظاهر في الصورة' });
      captchaInputRef.current?.focus();
      return;
    }
    setStatus({ state: 'sending', text: '' });
    try {
      await sendContactMessage({
        name: formData.nom,
        email: formData.adresse,
        phone: formData.telephone,
        subject: formData.sujet,
        message: formData.message,
        website: e.target.website?.value || '',
        captchaToken: captcha.token,
        captchaAnswer,
      });
      setFormData({ nom: '', prenom: '', adresse: '', telephone: '', sujet: '', message: '' });
      setStatus({ state: 'ok', text: '' });
    } catch (err) {
      setStatus({ state: 'error', text: err.message });
      captchaInputRef.current?.focus();
      loadCaptcha();
    }
  };

  // After a successful send: replace the form with a clear confirmation (so
  // the visitor doesn't send it again), count down, then go to the homepage.
  const sent = status.state === 'ok';
  const [secondsLeft, setSecondsLeft] = useState(REDIRECT_SECONDS);
  const successRef = useRef(null);

  useEffect(() => {
    if (!sent) return;
    setSecondsLeft(REDIRECT_SECONDS);
    window.scrollTo({ top: 0, behavior: 'smooth' });
    successRef.current?.focus();
    const tick = setInterval(() => setSecondsLeft((s) => Math.max(0, s - 1)), 1000);
    const go = setTimeout(() => navigate('/'), REDIRECT_SECONDS * 1000);
    return () => {
      clearInterval(tick);
      clearTimeout(go);
    };
  }, [sent, navigate]);

  if (sent) {
    return (
      <div className="contact-wrapper">
        <div className="container">
          <div className="contact-success" role="status" aria-live="polite" tabIndex={-1} ref={successRef}>
            <div className="contact-success-icon" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
            </div>
            <h2>تم إرسال رسالتك بنجاح</h2>
            <p>شكراً لتواصلك مع قناة مكة. وصلتنا رسالتك وسنرد عليك في أقرب وقت عبر البريد الإلكتروني.</p>
            <p className="contact-success-note">لا داعي لإرسال الرسالة مرة أخرى.</p>
            <p className="contact-success-countdown">
              سيتم تحويلك إلى الصفحة الرئيسية خلال <strong>{secondsLeft}</strong> {secondsLeft === 1 ? 'ثانية' : 'ثوانٍ'}
            </p>
            <div className="contact-success-bar" aria-hidden="true">
              <span style={{ animationDuration: `${REDIRECT_SECONDS}s` }} />
            </div>
            <button type="button" className="submit-btn contact-success-btn" onClick={() => navigate('/')}>
              العودة إلى الصفحة الرئيسية الآن
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="contact-wrapper">
      <div className="container">
        <h1>تواصل معنا</h1>
        <form onSubmit={handleSubmit} className="contact-form">

          <div className="col-md-6">
          <div className="form-group">
            <label htmlFor="nom">الاسم</label>
            <input
              type="text"
              id="nom"
              name="nom"
              value={formData.nom}
              onChange={handleChange}
              required
            />
          </div>
         
          <div className="form-group">
            <label htmlFor="adresse">البريد الإلكتروني</label>
            <input
              type="text"
              id="adresse"
              name="adresse"
              value={formData.adresse}
              onChange={handleChange}
              required
            />
          </div>
          </div>

          <div className="col-md-6">
          <div className="form-group">
            <label htmlFor="telephone">الهاتف</label>
            <input
              type="tel"
              id="telephone"
              name="telephone"
              value={formData.telephone}
              onChange={handleChange}
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="sujet">الموضوع</label>
            <input
              type="text"
              id="sujet"
              name="sujet"
              value={formData.sujet}
              onChange={handleChange}
              required
            />
          </div>
           </div> <div className="col-md-12">
          <div className="form-group">
            <label htmlFor="message">الرسالة</label>
            <textarea
              id="message"
              name="message"
              value={formData.message}
              onChange={handleChange}
              required
            ></textarea>
          </div> 
          {/* Honeypot: hidden from people, bots fill it and get ignored */}
          <input
            type="text"
            name="website"
            tabIndex={-1}
            autoComplete="off"
            aria-hidden="true"
            style={{ position: 'absolute', left: '-9999px', width: 1, height: 1, opacity: 0 }}
          />
          <div className="form-group captcha-group">
            <label htmlFor="captcha">رمز التحقق</label>
            <div className="captcha-row">
              <div className="captcha-image" aria-live="polite">
                {captcha.loading ? (
                  <span className="captcha-placeholder">جاري التحميل…</span>
                ) : captcha.error ? (
                  <span className="captcha-placeholder captcha-error">{captcha.error}</span>
                ) : (
                  <img src={captcha.image} alt="رمز التحقق: اكتب الأرقام الظاهرة" width="190" height="60" draggable="false" />
                )}
              </div>
              <button
                type="button"
                className="captcha-refresh"
                onClick={loadCaptcha}
                disabled={captcha.loading}
                aria-label="رمز جديد"
                title="رمز جديد"
              >
                ↻
              </button>
              <input
                ref={captchaInputRef}
                type="text"
                id="captcha"
                name="captcha"
                inputMode="numeric"
                autoComplete="off"
                maxLength={8}
                placeholder="اكتب الأرقام"
                value={captchaAnswer}
                onChange={(e) => setCaptchaAnswer(e.target.value)}
                required
              />
            </div>
          </div>
          {status.text && (
            <p
              role="status"
              style={{ margin: '0 0 12px', color: status.state === 'error' ? '#b42318' : '#0f6b4f', fontWeight: 500 }}
            >
              {status.text}
            </p>
          )}
          <button type="submit" className="submit-btn" disabled={status.state === 'sending' || !captcha.token}>
            {status.state === 'sending' ? 'جاري الإرسال…' : 'إرسال'}
          </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Contact;