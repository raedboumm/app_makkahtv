import React, { useState } from 'react';
import '../styles/contact.css'; // Assuming we'll create this

const Contact = () => {
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

  const handleSubmit = (e) => {
    e.preventDefault();
    // For now, just log the data. In a real app, send to backend.
    console.log('Form submitted:', formData);
    alert('تم إرسال الرسالة بنجاح!'); // Success message in Arabic
  };

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
          <button type="submit" className="submit-btn">إرسال</button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Contact;