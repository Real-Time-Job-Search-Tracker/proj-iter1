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

// ---------- create: submit with status ----------
function hookForm() {
  const form = document.querySelector("#pasteForm");
  if (!form) return;

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

      await fetch("/applications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": meta("csrf-token"),
        },
        body: JSON.stringify(payload),
      });

      if (urlI) urlI.value = "";
      if (coI) coI.value = "";
      if (tiI) tiI.value = "";
      if (stI) stI.value = "Applied";

      await loadApps();
      await loadSankey();
    } catch (err) {
      console.error("[hookForm] submit failed:", err);
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  });
}

// ---------- index table ----------
async function loadApps() {
  const tbody = $("#appsTable tbody");
  const count = byId("countLabel");
  if (!tbody) return;

  if (!tbody._boundClick) {
    tbody._boundClick = true;
    tbody.addEventListener("click", async (e) => {
      const btn = e.target.closest("button[data-id]");
      if (!btn) return;

      btn.disabled = true;
      try {
        const id = btn.dataset.id;
        const status = btn.dataset.next;
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
        console.error("[loadApps] update failed:", err);
      } finally {
        btn.disabled = false;
      }
    });
  }

  try {
    const dataRaw = await getJSON("/applications", {
      headers: { Accept: "application/json" },
    });

    const apps = Array.isArray(dataRaw) ? dataRaw : (dataRaw?.applications ?? []);

    tbody.innerHTML = "";

    if (!apps.length) {
      tbody.innerHTML =
        '<tr><td colspan="4" class="muted">No applications yet</td></tr>';
      if (count) count.textContent = "0 items";
      return;
    }

    for (const row of apps) {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${row.company ?? ""}</td>
        <td><a href="${row.url}" target="_blank" rel="noopener noreferrer">${row.url}</a></td>
        <td>${row.status ?? ""}</td>
        <td style="text-align:right;">
          <button class="btn" data-id="${row.id}" data-next="Interview">Mark Interview</button>
          <button class="btn" data-id="${row.id}" data-next="Offer">Mark Offer</button>
          <button class="btn" data-id="${row.id}" data-next="Accepted">Accept</button>
          <button class="btn" data-id="${row.id}" data-next="Declined">Decline</button>
        </td>`;
      tbody.appendChild(tr);
    }
    if (count) count.textContent = `${apps.length} items`;
  } catch (err) {
    console.error("[loadApps] failed:", err);
    tbody.innerHTML =
      '<tr><td colspan="4" class="muted">Failed to load applications</td></tr>';
    if (count) count.textContent = "";
  }
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
      const src = [], tgt = [], val = [];
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

    const nodeColors = [
      "#6f8cfb",
      "#87d4a6",
      "#b59dff",
      "#9aa5b1",
      "#7e8792",
      "#a98e86",
    ].slice(0, nodes.length);

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
  if (window.__jobtrackerBooted) return;
  window.__jobtrackerBooted = true;

  hookForm();
  loadApps();
  loadSankey();
  enableReveal();
}

document.addEventListener("turbo:load", boot);
document.addEventListener("DOMContentLoaded", boot);
Object.assign(window, { loadApps, loadSankey, boot });