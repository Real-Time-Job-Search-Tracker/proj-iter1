// ---------- utils ----------
async function getJSON(url, opts = {}) {
  const res = await fetch(url, opts);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}
const $ = (sel) => document.querySelector(sel);
const byId = (id) => document.getElementById(id);
const meta = (name) =>
  document.querySelector(`meta[name="${name}"]`)?.getAttribute("content") || "";

let ALL_APPS = [];
let statusFilter = "all";
let monthFilter = "all";

// ---------- create: submit with status ----------
async function hookForm() {
  const form = document.querySelector("#pasteForm");
  if (!form) return;
  if (form._boundSubmit) return;
  form._boundSubmit = true;

  const urlI = byId("jobUrl");
  const coI = byId("jobCompany");
  const tiI = byId("jobTitle");
  const stI = byId("jobStatus");

  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    const submitBtn = form.querySelector('[type="submit"]');
    const url = (urlI?.value || "").trim();
    if (!url) return;

    const payload = { url };
    if (coI && coI.value.trim()) payload.company = coI.value.trim();
    if (tiI && tiI.value.trim()) payload.title = tiI.value.trim();
    if (stI && stI.value) payload.status = stI.value;

    try {
      if (submitBtn) submitBtn.disabled = true;

      const res = await fetch("/applications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": meta("csrf-token"),
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const txt = await res.text();
        console.error("POST /applications failed:", res.status, txt);
        alert(`POST /applications failed: ${res.status}`);
        return;
      }

      await loadApps();
      await loadSankey();

      if (urlI) urlI.value = "";
      if (coI) coI.value = "";
      if (tiI) tiI.value = "";
      if (stI) stI.value = "Applied";
    } catch (err) {
      console.error("[hookForm] submit failed:", err);
      alert("Submit failed, see console");
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  });
}

// ---------- toolbar (filters + bulk delete) ----------
function bindToolbar() {
  const statusSel = byId("filterStatus") || byId("statusFilter");
  if (statusSel && !statusSel._bound) {
    statusSel._bound = true;
    statusSel.addEventListener("change", () => {
      statusFilter = statusSel.value || "all";
      renderFilteredApps();
    });
  }

  const monthSel = byId("filterMonth") || byId("monthFilter");
  if (monthSel && !monthSel._bound) {
    monthSel._bound = true;
    monthSel.addEventListener("change", () => {
      monthFilter = monthSel.value || "all";
      renderFilteredApps();
    });
  }

  const bulkDeleteBtn = byId("bulkDeleteBtn");
  if (bulkDeleteBtn && !bulkDeleteBtn._bound) {
    bulkDeleteBtn._bound = true;
    bulkDeleteBtn.addEventListener("click", handleBulkDelete);
  }
}

// ---------- bulk delete ----------
async function handleBulkDelete() {
  const checkboxes = document.querySelectorAll(
    '.row-select:checked, input.row-check[type="checkbox"]:checked'
  );

  const ids = Array.from(checkboxes)
    .map((cb) => cb.dataset.id)
    .filter(Boolean);

  if (!ids.length) {
    return;
  }

  const ok = window.confirm(
    ids.length === 1
      ? "Delete this application?"
      : `Delete ${ids.length} selected applications?`
  );
  if (!ok) return;

  await Promise.all(
    ids.map((id) =>
      fetch(`/applications/${id}`, {
        method: "DELETE",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": meta("csrf-token"),
        },
      }).catch((e) => console.error("delete failed for id", id, e))
    )
  );

  await loadApps();
  await loadSankey();
}

// ---------- index table: data + filters + rendering ----------
async function loadApps() {
  const tbody = byId("apps-body") || $("#appsTable tbody");
  if (!tbody) return;

  if (!tbody._boundHandlers) {
    tbody._boundHandlers = true;

    tbody.addEventListener("change", async (e) => {
      const sel = e.target.closest("select.status-select");
      if (!sel) return;

      const id = sel.dataset.id;
      const status = sel.value;
      if (!id || !status) return;

      try {
        await fetch(`/applications/${id}`, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            "X-CSRF-Token": meta("csrf-token"),
          },
          body: JSON.stringify({ status }),
        });
        await loadApps();
        await loadSankey();
      } catch (err) {
        console.error("[status update] failed:", err);
      }
    });
  }

  try {
    const dataRaw = await getJSON("/applications", {
      headers: { Accept: "application/json" },
    });
    ALL_APPS = Array.isArray(dataRaw)
      ? dataRaw
      : dataRaw?.applications ?? [];

    populateMonthFilter(ALL_APPS);
    renderFilteredApps();
  } catch (err) {
    console.error("[loadApps] failed:", err);
    const count = byId("countLabel");
    if (count) count.textContent = "";
    tbody.innerHTML =
      '<tr><td colspan="6" class="muted">Failed to load applications</td></tr>';
  }
}

function populateMonthFilter(rows) {
  const monthSel = byId("filterMonth") || byId("monthFilter");
  if (!monthSel) return;

  const prevValue = monthSel.value || "all";
  const months = new Set();

  rows.forEach((app) => {
    const d = app.applied_on || (app.created_at && app.created_at.slice(0, 10));
    if (!d) return;
    months.add(d.slice(0, 7));
  });

  const sorted = Array.from(months).sort();

  monthSel.innerHTML = "";
  const optAll = document.createElement("option");
  optAll.value = "all";
  optAll.textContent = "All months";
  monthSel.appendChild(optAll);

  sorted.forEach((m) => {
    const o = document.createElement("option");
    o.value = m;
    o.textContent = m;
    monthSel.appendChild(o);
  });

  if (prevValue !== "all" && sorted.includes(prevValue)) {
    monthSel.value = prevValue;
    monthFilter = prevValue;
  } else {
    monthSel.value = "all";
    monthFilter = "all";
  }
}

function getFilteredApps() {
  return ALL_APPS.filter((app) => {
    const status = app.status || "Applied";
    const statusOk =
      statusFilter === "all" ||
      status.toLowerCase() === statusFilter.toLowerCase();

    const d = app.applied_on || (app.created_at && app.created_at.slice(0, 10));
    const ym = d ? d.slice(0, 7) : null;
    const monthOk = monthFilter === "all" || ym === monthFilter;

    return statusOk && monthOk;
  });
}

function renderFilteredApps() {
  const tbody = byId("apps-body") || $("#appsTable tbody");
  const count = byId("countLabel");
  if (!tbody) return;

  const apps = getFilteredApps();
  tbody.innerHTML = "";

  if (!apps.length) {
    tbody.innerHTML =
      '<tr><td colspan="6" class="muted">No applications yet</td></tr>';
    if (count) count.textContent = "0 items";
    return;
  }

  apps.forEach((row) => {
    const appliedOn =
      row.applied_on || (row.created_at ? row.created_at.slice(0, 10) : "");

    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>
        <input
          type="checkbox"
          class="row-check"
          data-id="${row.id}"
        />
      </td>
      <td>${row.company ?? ""}</td>
      <td>${appliedOn || "—"}</td>
      <td>
        ${
          row.url
            ? `<a href="${row.url}" target="_blank" rel="noopener noreferrer" class="table-link-btn">View job</a>`
            : "—"
        }
      </td>
      <td>
        <span class="status-pill ${statusClass(row.status || "Applied")}">
          ${row.status || "Applied"}
        </span>
      </td>
      <td style="text-align:right;">
        ${buildStatusSelectHTML(row.id, row.status || "Applied")}
      </td>
    `;
    tbody.appendChild(tr);
  });

  if (count) {
    const n = apps.length;
    count.textContent = n === 1 ? "1 item" : `${n} items`;
  }
}

function statusClass(status) {
  const s = (status || "").toLowerCase();
  if (s.includes("offer")) return "status-offer";
  if (s.includes("declin") || s.includes("reject")) return "status-declined";
  if (s.includes("ghost")) return "status-ghosted";
  if (s.includes("interview") || s.startsWith("round")) return "status-interview";
  if (s.includes("accept")) return "status-accepted";
  return "status-applied";
}

function buildStatusSelectHTML(id, current) {
  const options = [
    "Applied",
    "Round1",
    "Round2",
    "Interview",
    "Offer",
    "Accepted",
    "Declined",
    "Ghosted",
  ];
  const optsHTML = options
    .map((opt) => {
      const selected =
        (current || "").toLowerCase() === opt.toLowerCase() ? "selected" : "";
      return `<option value="${opt}" ${selected}>${opt}</option>`;
    })
    .join("");
  return `<select class="status-select" data-id="${id}">${optsHTML}</select>`;
}

// ---------- reveal ----------
function enableReveal() {
  const els = document.querySelectorAll(".reveal");
  if (!els.length) return;

  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add("show");
          io.unobserve(e.target);
        }
      });
    },
    { threshold: 0.15 }
  );

  els.forEach((el) => io.observe(el));
}

// ---------- sankey ----------
const SANKEY_NODE_COLORS = {
  Applications: "#3b82f6",
  Applied: "#4b73eb",
  Round1: "#a855f7",
  Round2: "#de13d7",
  Interview: "#f97316",
  Offer: "#f6cc0fff",
  Accepted: "#1dd360ff",
  Declined: "#e51818ff",
  Ghosted: "#6b7280",
};

async function loadSankey() {
  try {
    const el = document.getElementById("sankey");
    if (!el || !window.Plotly) return;

    const res = await fetch("/applications/stats", {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) throw new Error("stats failed");
    const data = await res.json();

    if (Array.isArray(data.links)) {
      const src = [],
        tgt = [],
        val = [];
      data.links.forEach((l) => {
        src.push(l.source);
        tgt.push(l.target);
        val.push(l.value);
      });
      data.links = { source: src, target: tgt, value: val };
    }

    const nodes = data.nodes || [];
    const links = data.links || {};
    const src = links.source || [];
    const tgt = links.target || [];
    const val = links.value || [];

    const total = val.reduce((a, b) => a + (+b || 0), 0);
    if (!nodes.length || !src.length || !tgt.length || !val.length || total === 0) {
      el.innerHTML =
        '<div style="height:280px;display:flex;align-items:center;justify-content:center;color:#697386">No transitions yet</div>';
      return;
    }

    const nodeColors = nodes.map(
      (name) => SANKEY_NODE_COLORS[name] || "#9ca3af"
    );

    const plotData = [
      {
        type: "sankey",
        orientation: "h",
        arrangement: "snap",
        node: {
          label: nodes,
          color: nodeColors,
          pad: 18,
          thickness: 18,
          line: { color: "rgba(230,232,236,0.7)", width: 1 },
        },
        link: {
          source: src,
          target: tgt,
          value: val,
          color: "rgba(30,30,40,0.18)",
          hovertemplate: "%{value} flow(s)<extra></extra>",
        },
      },
    ];

    const layout = {
      paper_bgcolor: "rgba(0,0,0,0)",
      plot_bgcolor: "rgba(0,0,0,0)",
      margin: { l: 12, r: 12, t: 10, b: 10 },
      font: {
        family:
          "Manrope, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial",
        size: 13,
        color: "#12141a",
      },
      height: 420,
    };

    await Plotly.react(el, plotData, layout, { displayModeBar: false });
    Plotly.Plots.resize(el);

    if (!loadSankey._boundResize) {
      loadSankey._boundResize = true;
      window.addEventListener("resize", () => {
        const el2 = byId("sankey");
        if (el2 && window.Plotly) window.Plotly.Plots.resize(el2);
      });
    }
  } catch (e) {
    console.error(e);
    const el = document.getElementById("sankey");
    if (el) {
      el.innerHTML =
        '<div style="height:280px;display:flex;align-items:center;justify-content:center;color:#697386">Failed to render</div>';
    }
  }
}

// ---------- boot ----------
function boot() {
  hookForm();
  bindToolbar();
  loadApps();
  loadSankey();
  enableReveal();
}

document.addEventListener("turbo:load", boot);
document.addEventListener("turbo:render", boot);
document.addEventListener("DOMContentLoaded", boot);

Object.assign(window, { loadApps, loadSankey, boot });
