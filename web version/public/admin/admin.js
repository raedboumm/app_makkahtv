(() => {
  const TOKEN_KEY = "makkah_admin_token";
  const EMAIL_KEY = "makkah_admin_email";
  const $ = (sel) => document.querySelector(sel);

  let token = "";
  let adminEmail = "";
  try {
    token = sessionStorage.getItem(TOKEN_KEY) || "";
    adminEmail = sessionStorage.getItem(EMAIL_KEY) || "";
  } catch {}

  let config = null;
  let messages = [];

  // ---------------------------------------------------------- api

  // All calls go to the PHP API: /api/index.php?action=...
  const API = "/api/index.php";

  async function api(query, { method = "GET", body } = {}) {
    const res = await fetch(`${API}?${query}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { "X-Auth-Token": token } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => null);
    if (data === null) throw new Error("الخادم لا يستجيب بشكل صحيح (تأكد من رفع مجلد api ومن أن PHP يعمل)");
    if (res.status === 401 && query !== "action=login") {
      logout();
      throw new Error("انتهت الجلسة، سجّل الدخول مجدداً");
    }
    if (!res.ok) throw new Error(data.error || `خطأ ${res.status}`);
    return data;
  }

  // ---------------------------------------------------------- helpers

  function el(tag, attrs = {}, ...children) {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (v == null || v === false) continue;
      if (k === "class") node.className = v;
      else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
      else node.setAttribute(k, v === true ? "" : v);
    }
    for (const c of children.flat()) {
      if (c == null || c === false) continue;
      node.append(c instanceof Node ? c : document.createTextNode(String(c)));
    }
    return node;
  }

  const fmtDate = (iso) => {
    if (!iso) return "—";
    const d = new Date(iso);
    return d.toLocaleString("ar", { dateStyle: "medium", timeStyle: "short" });
  };

  const mask = (key) => {
    if (!key) return "— غير محدد —";
    if (key.length <= 8) return "••••••••";
    return `${key.slice(0, 4)}••••••••${key.slice(-4)}`;
  };

  const statusPill = (on) =>
    el("span", { class: `pill ${on ? "pill-on" : "pill-off"}` }, on ? "مفعّل" : "متوقف");

  let toastTimer;
  function toast(text, isError = false) {
    const t = $("#toast");
    t.textContent = text;
    t.className = `toast${isError ? " err" : ""}`;
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => (t.hidden = true), 3000);
  }

  // ---------------------------------------------------------- auth

  function showLogin() {
    $("#app-view").hidden = true;
    $("#login-view").hidden = false;
  }

  function logout() {
    token = "";
    try { sessionStorage.removeItem(TOKEN_KEY); sessionStorage.removeItem(EMAIL_KEY); } catch {}
    showLogin();
  }

  $("#login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const err = $("#login-error");
    const btn = $("#login-btn");
    err.hidden = true;
    const email = e.target.email.value.trim();
    const password = e.target.password.value;
    if (!email || !password) {
      err.textContent = "أدخل البريد الإلكتروني وكلمة المرور";
      err.hidden = false;
      return;
    }
    btn.disabled = true;
    btn.textContent = "جاري الدخول…";
    try {
      const data = await api("action=login", { method: "POST", body: { email, password } });
      token = data.token;
      adminEmail = data.email || email;
      try {
        sessionStorage.setItem(TOKEN_KEY, token);
        sessionStorage.setItem(EMAIL_KEY, adminEmail);
      } catch {}
      e.target.reset();
      start();
    } catch (ex) {
      err.textContent = ex.message;
      err.hidden = false;
    } finally {
      btn.disabled = false;
      btn.textContent = "تسجيل الدخول";
    }
  });

  $("#logout").addEventListener("click", logout);

  $("#pass-toggle").addEventListener("click", (e) => {
    const input = $("#login-form").password;
    const show = input.type === "password";
    input.type = show ? "text" : "password";
    e.currentTarget.textContent = show ? "إخفاء" : "إظهار";
  });

  // ---------------------------------------------------------- tabs

  document.querySelectorAll(".nav-item").forEach((btn) =>
    btn.addEventListener("click", () => {
      const tab = btn.dataset.tab;
      document.querySelectorAll(".nav-item").forEach((b) => b.classList.toggle("active", b === btn));
      document.querySelectorAll("section.tab").forEach((s) => (s.hidden = s.dataset.tab !== tab));
      if (tab === "messages") loadMessages();
    })
  );

  // ---------------------------------------------------------- config tables

  const SECTIONS = {
    live: {
      title: "تعديل البث المباشر",
      fields: [
        { name: "label", label: "الاسم" },
        { name: "streamUrl", label: "رابط البث (m3u8)", ltr: true, type: "url", hint: "مثال: https://…/playlist.m3u8" },
      ],
    },
    library: {
      title: "تعديل مكتبة البرامج",
      fields: [
        { name: "label", label: "الاسم" },
        { name: "apiKey", label: "مفتاح YouTube API", ltr: true, secret: true },
        { name: "playlistId", label: "معرّف قائمة الرفع (Playlist ID)", ltr: true, hint: "يبدأ عادة بـ UU" },
      ],
    },
    playlists: {
      title: "تعديل قوائم التشغيل",
      fields: [
        { name: "label", label: "الاسم" },
        { name: "apiKey", label: "مفتاح YouTube API", ltr: true, secret: true },
        { name: "channelId", label: "معرّف القناة (Channel ID)", ltr: true, hint: "يبدأ عادة بـ UC" },
      ],
    },
  };

  function renderConfig() {
    const { live, library, playlists } = config;

    $("#live-body").replaceChildren(
      el("tr", {},
        el("td", { class: "nowrap name-cell" }, el("strong", {}, live.label)),
        el("td", {}, el("span", { class: "mono code-box" }, live.streamUrl || "—")),
        el("td", {}, statusPill(live.active)),
        el("td", { class: "nowrap muted" }, fmtDate(live.updatedAt)),
        el("td", { class: "actions" },
          el("button", { class: "btn btn-sm btn-primary", onclick: () => openEdit("live") }, "تعديل"),
          live.streamUrl && el("a", { class: "btn btn-sm", href: live.streamUrl, target: "_blank", rel: "noopener" }, "فتح الرابط")
        )
      )
    );

    const ytRow = (section, item, idField) => {
      const keyCell = el("span", { class: "mono code-box" }, mask(item.apiKey));
      let shown = false;
      return el("tr", {},
        el("td", { class: "nowrap name-cell" }, el("strong", {}, item.label)),
        el("td", { class: "nowrap" },
          keyCell,
          item.apiKey && el("button", {
            class: "link-btn small",
            style: "margin-inline-start:8px",
            onclick: (e) => {
              shown = !shown;
              keyCell.textContent = shown ? item.apiKey : mask(item.apiKey);
              e.currentTarget.textContent = shown ? "إخفاء" : "إظهار";
            },
          }, "إظهار")
        ),
        el("td", {}, el("span", { class: "mono code-box" }, item[idField] || "—")),
        el("td", {}, statusPill(item.active)),
        el("td", { class: "nowrap muted" }, fmtDate(item.updatedAt)),
        el("td", { class: "actions" },
          el("button", { class: "btn btn-sm btn-primary", onclick: () => openEdit(section) }, "تعديل"),
          el("button", { class: "btn btn-sm", onclick: (e) => testYoutube(section, e.currentTarget) }, "اختبار")
        )
      );
    };

    $("#library-body").replaceChildren(ytRow("library", library, "playlistId"));
    $("#playlists-body").replaceChildren(ytRow("playlists", playlists, "channelId"));
  }

  // Calls YouTube directly from the browser to check the key + id work.
  async function testYoutube(section, btn) {
    const item = config[section];
    if (!item.apiKey) return toast("أضف مفتاح API أولاً", true);
    const url =
      section === "library"
        ? `https://www.googleapis.com/youtube/v3/playlistItems?part=id&maxResults=1&playlistId=${encodeURIComponent(item.playlistId)}&key=${encodeURIComponent(item.apiKey)}`
        : `https://www.googleapis.com/youtube/v3/playlists?part=id&maxResults=1&channelId=${encodeURIComponent(item.channelId)}&key=${encodeURIComponent(item.apiKey)}`;
    btn.disabled = true;
    try {
      const res = await fetch(url);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error?.message || `HTTP ${res.status}`);
      toast(`✓ يعمل — ${data.pageInfo?.totalResults ?? 0} عنصر`);
    } catch (e) {
      toast(`فشل الاختبار: ${e.message}`, true);
    } finally {
      btn.disabled = false;
    }
  }

  // ---------------------------------------------------------- edit dialog

  let editing = null;
  const editDialog = $("#edit-dialog");

  function openEdit(section) {
    editing = section;
    const def = SECTIONS[section];
    const item = config[section];
    $("#edit-title").textContent = def.title;
    $("#edit-error").hidden = true;
    $("#edit-fields").replaceChildren(
      ...def.fields.map((f) =>
        el("label", { class: "field" },
          el("span", {}, f.label),
          el("input", {
            name: f.name,
            type: f.secret ? "password" : f.type || "text",
            class: f.ltr ? "ltr mono-input" : null,
            value: item[f.name] || "",
            autocomplete: "off",
            spellcheck: "false",
          }),
          f.hint && el("span", { class: "hint" }, f.hint)
        )
      )
    );
    editDialog.querySelector('[name="active"]').checked = !!item.active;
    editDialog.showModal();
  }

  $("#edit-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const form = e.target;
    const body = { active: form.active.checked };
    SECTIONS[editing].fields.forEach((f) => (body[f.name] = form[f.name].value.trim()));
    try {
      config[editing] = await api(`action=save_config&section=${editing}`, { method: "POST", body });
      renderConfig();
      editDialog.close();
      toast("تم الحفظ");
    } catch (ex) {
      $("#edit-error").textContent = ex.message;
      $("#edit-error").hidden = false;
    }
  });

  document.querySelectorAll("[data-close]").forEach((b) =>
    b.addEventListener("click", () => b.closest("dialog").close())
  );

  // ---------------------------------------------------------- messages

  async function loadMessages() {
    try {
      messages = await api("action=messages");
      renderMessages();
    } catch (e) {
      toast(e.message, true);
    }
  }

  function updateBadge() {
    const unread = messages.filter((m) => !m.read).length;
    const today = new Date().toDateString();
    $("#stat-total").textContent = messages.length;
    $("#stat-unread").textContent = unread;
    $("#stat-today").textContent = messages.filter((m) => new Date(m.createdAt).toDateString() === today).length;
    const b = $("#unread-badge");
    b.textContent = unread;
    b.hidden = unread === 0;
  }

  function renderMessages() {
    updateBadge();
    const q = $("#msg-search").value.trim().toLowerCase();
    const filter = $("#msg-filter").value;
    const list = messages.filter((m) => {
      if (filter === "unread" && m.read) return false;
      if (filter === "read" && !m.read) return false;
      if (!q) return true;
      return [m.name, m.email, m.subject, m.phone, m.message].some((v) => (v || "").toLowerCase().includes(q));
    });

    if (list.length === 0) {
      $("#messages-body").replaceChildren(
        el("tr", {}, el("td", { colspan: 8, class: "empty" }, messages.length ? "لا توجد نتائج" : "لا توجد رسائل بعد"))
      );
      return;
    }

    $("#messages-body").replaceChildren(
      ...list.map((m) =>
        el("tr", { class: m.read ? null : "unread" },
          el("td", { class: "nowrap muted" }, fmtDate(m.createdAt)),
          el("td", { class: "nowrap msg-name" }, m.name),
          el("td", {}, el("a", { class: "mono", href: `mailto:${m.email}` }, m.email)),
          el("td", {}, el("span", { class: "mono" }, m.phone || "—")),
          el("td", {}, m.subject || "—"),
          el("td", { class: "preview", title: m.message }, el("button", { class: "link-btn", onclick: () => openMessage(m) }, m.message)),
          el("td", {}, el("span", { class: `pill ${m.read ? "pill-read" : "pill-new"}` }, m.read ? "مقروءة" : "جديدة")),
          el("td", { class: "actions" },
            el("button", { class: "btn btn-sm btn-primary", onclick: () => openMessage(m) }, "عرض"),
            el("button", { class: "btn btn-sm", onclick: () => setRead(m, !m.read) }, m.read ? "تعليم كجديدة" : "تعليم كمقروءة"),
            el("button", { class: "btn btn-sm btn-danger", onclick: () => removeMessage(m) }, "حذف")
          )
        )
      )
    );
  }

  async function setRead(m, read) {
    try {
      const updated = await api(`action=mark_read&id=${encodeURIComponent(m.id)}`, { method: "POST", body: { read } });
      Object.assign(m, updated);
      renderMessages();
    } catch (e) {
      toast(e.message, true);
    }
  }

  async function removeMessage(m) {
    if (!confirm(`حذف رسالة «${m.name}»؟`)) return;
    try {
      await api(`action=delete_message&id=${encodeURIComponent(m.id)}`, { method: "POST" });
      messages = messages.filter((x) => x.id !== m.id);
      renderMessages();
      toast("تم الحذف");
    } catch (e) {
      toast(e.message, true);
    }
  }

  function openMessage(m) {
    $("#msg-subject").textContent = m.subject || "(بدون موضوع)";
    $("#msg-name").textContent = m.name;
    $("#msg-email").textContent = m.email;
    $("#msg-phone").textContent = m.phone || "—";
    $("#msg-date").textContent = fmtDate(m.createdAt);
    $("#msg-text").textContent = m.message;
    $("#msg-reply").href = `mailto:${m.email}?subject=${encodeURIComponent("رد: " + (m.subject || ""))}`;
    $("#msg-dialog").showModal();
    if (!m.read) setRead(m, true);
  }

  $("#msg-search").addEventListener("input", renderMessages);
  $("#msg-filter").addEventListener("change", renderMessages);
  $("#msg-refresh").addEventListener("click", loadMessages);

  // ---------------------------------------------------------- boot

  async function start() {
    try {
      config = await api("action=admin_config");
      $("#login-view").hidden = true;
      $("#app-view").hidden = false;
      $("#user-email").textContent = adminEmail;
      $("#user-email").title = adminEmail;
      $("#user-avatar").textContent = (adminEmail[0] || "م").toUpperCase();
      renderConfig();
      loadMessages();
    } catch {
      showLogin();
    }
  }

  if (token) start();
  else showLogin();
})();
