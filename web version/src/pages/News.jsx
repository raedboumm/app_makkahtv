import React, { useEffect, useState } from "react";
import ArticleCard from "../components/ArticleCard";
import "../styles/news.css";
import staticArticles from '../data/staticArticles';

const NewsPage = () => {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState(null);


  useEffect(() => {
    loadArticles();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const loadArticles = async () => {
    setLoading(true);
    // Simulate loading delay
    setTimeout(() => {
      const itemsPerPage = 12;
      const startIndex = (page - 1) * itemsPerPage;
      const endIndex = startIndex + itemsPerPage;
      const paginatedArticles = staticArticles.slice(startIndex, endIndex);

      setArticles(paginatedArticles);
      setPagination({
        page: page,
        limit: itemsPerPage,
        totalPages: Math.ceil(staticArticles.length / itemsPerPage),
        total: staticArticles.length
      });
      setLoading(false);
    }, 300);
  };

  if (loading) {
    return (
      <div className="loading-screen">
        <i className="fas fa-spinner fa-spin"></i>
      </div>
    );
  }

  return (
    <div className="news-page">
      <div className="container">
        <h1 className="news-title">
          <i className="fas fa-newspaper"></i> أخبار
        </h1>

        <div className="news-grid">
          {articles.map((article) => (
            <ArticleCard key={article.id} article={article} />
          ))}
        </div>

        {/* ✅ Pagination */}
        {pagination && pagination.totalPages > 1 && (
          <div className="pagination">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              السابق
            </button>
            <span>
              صفحة {page} من {pagination.totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
              disabled={page === pagination.totalPages}
            >
              التالي
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default NewsPage;
