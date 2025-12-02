let jobsPageRan = false;

export function initJobsPage() {
  const sankeyEl = document.getElementById("sankey");
  const appsList = document.getElementById("applications");

  const appsTableBody = document.getElementById("apps-body");
  const countLabel    = document.getElementById("countLabel");

  if (!sankeyEl && !appsList && !appsTableBody) return;

  if (jobsPageRan) {
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

  function syncTableDates(rows) {
    if (!appsTableBody) return;
    const trs = Array.from(appsTableBody.querySelectorAll("tr"));
    if (!trs.length) return;

    rows.forEach((r, idx) => {
      const tr = trs[idx];
      if (!tr) return;

      const appliedOn =
        r.applied_on || (r.created_at ? r.created_at.slice(0, 10) : "");

      const tds = tr.querySelectorAll("td");
      if (tds.length >= 2) {
        tds[1].textContent = appliedOn || "—";
      }
    });

    if (countLabel) {
      countLabel.textContent = `${rows.length} items`;
    }
  }

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
        Plotly.react(sankeyEl, [trace], {
          margin: { l: 10, r: 10, t: 10, b: 10 },
        });
      })
      .catch((err) => console.error("[jobs_page] sankey error:", err));
  }

  const fillApps = async (attempt = 1) => {
    if (!appsList && !appsTableBody) return;
    try {
      const rows = await safeJSON("/applications.json");
      if (!rows) {
        console.warn("[jobs_page] /applications.json not JSON; skip render.");
        return;
      }

      if (appsList) {
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
      }

      syncTableDates(rows);
    } catch (e) {
      if (attempt === 1) {
        setTimeout(() => fillApps(2), 150);
      } else {
        console.error("[jobs_page] list error:", e);
      }
    }
  };

  fillApps();
}
