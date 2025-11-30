// ---------- small helpers ----------
const byId = (id) => document.getElementById(id);

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

// ---------- sankey only ----------
const SANKEY_NODE_COLORS = {
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
    const el = byId("sankey");
    if (!el || !window.Plotly) return;

    const res = await fetch("/applications/stats", {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) throw new Error("stats failed");
    const data = await res.json();

    if (Array.isArray(data.links)) {
      const src = [];
      const tgt = [];
      const val = [];
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
        arrangement: "fixed",
        node: {
          label: nodes,
          color: nodeColors,
          pad: 20,
          thickness: 20,
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
      margin: { l: 100, r: 30, t: 30, b: 30 },
      font: {
        family:
          "Manrope, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial",
        size: 13,
        color: "#12141a",
      },
      height: 450,
      autosize: true,
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
    console.error("[loadSankey] failed:", e);
    const el = byId("sankey");
    if (el) {
      el.innerHTML =
        '<div style="height:280px;display:flex;align-items:center;justify-content:center;color:#697386">Failed to render</div>';
    }
  }
}

function bootSankey() {
  if (byId("sankey")) {
    loadSankey();
  }
  enableReveal();
}

document.addEventListener("turbo:load", bootSankey);
document.addEventListener("turbo:render", bootSankey);
document.addEventListener("DOMContentLoaded", bootSankey);


Object.assign(window, { loadSankey });
