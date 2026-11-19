import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import './styles/global.css';

import "./index.css"; // Global CSS
import "./styles/darkTheme.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
