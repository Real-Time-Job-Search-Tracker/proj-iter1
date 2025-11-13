let jobsPageRan = false;

export function initJobsPage() {
  const sankeyEl = document.getElementById("sankey");
  const appsList = document.getElementById("applications");

  // If neither widget is present, do nothing
  if (!sankeyEl && !appsList) return;

  // Prevent double work on the same render, but allow future renders
  // (Turbo restores will call us again)
  if (jobsPageRan) {
    // still re-run if elements exist but are empty
    if (!appsList || appsList.dataset.filled === "1") return;
  }
  jobsPageRan = true;

  async function safeJSON(url) {
    const resp = await fetch(url, { headers: { Accept: "application/json" } });
    const ct = resp.headers.get("content-type") || "";
    if (!ct.includes("application/json")) {
      console.warn(`[jobs_page] ${url} returned non-JSON (likely redirect/login).`);
      return null;
    }
    return resp.json();
  }

  // Sankey
  if (sankeyEl) {
    safeJSON("/applications/stats.json")
      .then((data) => {
        if (!data) return;
        const link = {
          source: data.links.map((l) => l.source),
          target: data.links.map((l) => l.target),
          value: data.links.map((l) => l.value),
        };
        const trace = { type: "sankey", node: { label: data.nodes }, link };
        Plotly.react(sankeyEl, [trace], { margin: { l: 10, r: 10, t: 10, b: 10 } });
      })
      .catch((err) => console.error("[jobs_page] sankey error:", err));
  }

  // Applications list (with one retry)
  const fillApps = async (attempt = 1) => {
    if (!appsList) return;
    try {
      const rows = await safeJSON("/applications.json");
      if (!rows) {
        console.warn("[jobs_page] /applications.json not JSON; skip render.");
        return;
      }
      // If something wiped the list after we filled, allow re-fill later
      appsList.dataset.filled = "1";
      appsList.innerHTML = rows
        .map(
          (r) => `
        <li data-company="${r.company}">
          <span class="company">${r.company}</span>
          <span class="stage">${r.status}</span>
        </li>`
        )
        .join("");
    } catch (e) {
      if (attempt === 1) {
        // transient race: element not yet in DOM or fetch hiccup — try once more
        setTimeout(() => fillApps(2), 150);
      } else {
        console.error("[jobs_page] list error:", e);
      }
    }
  };

  fillApps();
}
