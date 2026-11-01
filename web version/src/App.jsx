import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

import Header from "./components/Header";
import Footer from "./components/Footer";
import ScrollToTop from "./components/ScrollToTop";
import BackToTop from "./components/BackToTop";
import { LiveStreamProvider } from "./context/LiveStream";

// ✅ Pages
import Home from "./pages/Home";
import News from "./pages/News";
import Videos from "./pages/Videos";
import Live from "./pages/Live";
import Programs from "./pages/Programs";
import Hajj from "./pages/Hajj";
import Daily from "./pages/Daily";
import ProgramsLibrary from "./pages/ProgramsLibrary";
import ArticleDetail from './pages/ArticleDetail';
import ProgramDetail from './pages/ProgramDetail';
import Contact from './pages/Contact';
import PrivacyPolicy from './pages/PrivacyPolicy';

const App = () => {
  return (
    <Router>
      <LiveStreamProvider>
        <div className="app">
          <ScrollToTop />
          <Header />

          <main className="app-content">
            <BackToTop />

            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/news" element={<News />} />
              <Route path="/news/:id" element={<ArticleDetail />} />
              <Route path="/programs/:id" element={<ProgramDetail />} />
              <Route path="/videos" element={<Videos />} />
              <Route path="/library" element={<ProgramsLibrary />} />
              <Route path="/live" element={<Live />} />
              <Route path="/programs" element={<Programs />} />
              <Route path="/hajj" element={<Hajj />} />
              <Route path="/daily" element={<Daily />} />
              <Route path="/contact" element={<Contact />} />
              <Route path="/privacy" element={<PrivacyPolicy />} />

              {/* ✅ Invalid routes fall back to homepage */}
              <Route path="*" element={<Home />} />
            </Routes>
          </main>

          <Footer />
        </div>
      </LiveStreamProvider>
    </Router>
  );
};

export default App;
