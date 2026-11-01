import React from 'react';
import ArticleCard from './ArticleCard.jsx';

const ChannelNewsSection = ({ title = 'أخبار القناة', articles = [], limit = 4 }) => {
  const items = Array.isArray(articles) ? articles.slice(0, limit) : [];

  return (
    <section className="articles-section channel-news">
      <div className="container">
        <h2 className="section-title">
          <span className="title-bar"></span> {title}
        </h2>
        <div className="grid article-grid">
          {items.length === 0 ? (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center' }}>لا توجد مقالات</div>
          ) : (
            items.map((article, idx) => (
              <ArticleCard key={article.id || article.slug || idx} article={article} index={idx} />
            ))
          )}
        </div>
      </div>
    </section>
  );
};

export default ChannelNewsSection;

