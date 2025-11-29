// let jobsPageRan = false;

// export function initJobsPage() {
//   const sankeyEl = document.getElementById("sankey");
//   const appsList = document.getElementById("applications");

//   // If neither widget is present, do nothing
//   if (!sankeyEl && !appsList) return;

//   // Prevent double work on the same render, but allow future renders
//   // (Turbo restores will call us again)
//   if (jobsPageRan) {
//     // still re-run if elements exist but are empty
//     if (!appsList || appsList.dataset.filled === "1") return;
//   }
//   jobsPageRan = true;

//   async function safeJSON(url) {
//     const resp = await fetch(url, { headers: { Accept: "application/json" } });
//     const ct = resp.headers.get("content-type") || "";
//     if (!ct.includes("application/json")) {
//       console.warn(`[jobs_page] ${url} returned non-JSON (likely redirect/login).`);
//       return null;
//     }
//     return resp.json();
//   }

//   // Sankey
//   if (sankeyEl) {
//     safeJSON("/applications/stats.json")
//       .then((data) => {
//         if (!data) return;
//         const link = {
//           source: data.links.map((l) => l.source),
//           target: data.links.map((l) => l.target),
//           value: data.links.map((l) => l.value),
//         };
//         const trace = { type: "sankey", node: { label: data.nodes }, link };
//         Plotly.react(sankeyEl, [trace], { margin: { l: 10, r: 10, t: 10, b: 10 } });
//       })
//       .catch((err) => console.error("[jobs_page] sankey error:", err));
//   }

//   // Applications list (with one retry)
//   const fillApps = async (attempt = 1) => {
//     if (!appsList) return;
//     try {
//       const rows = await safeJSON("/applications.json");
//       if (!rows) {
//         console.warn("[jobs_page] /applications.json not JSON; skip render.");
//         return;
//       }
//       // If something wiped the list after we filled, allow re-fill later
//       appsList.dataset.filled = "1";
//       appsList.innerHTML = rows
//         .map(
//           (r) => `
//         <li data-company="${r.company}">
//           <span class="company">${r.company}</span>
//           <span class="stage">${r.status}</span>
//         </li>`
//         )
//         .join("");
//     } catch (e) {
//       if (attempt === 1) {
//         // transient race: element not yet in DOM or fetch hiccup — try once more
//         setTimeout(() => fillApps(2), 150);
//       } else {
//         console.error("[jobs_page] list error:", e);
//       }
//     }
//   };

//   fillApps();
// }


// let jobsPageRan = false;

// export function initJobsPage() {
//   const sankeyEl = document.getElementById("sankey");
//   const appsList = document.getElementById("applications");

//   // 如果 dashboard 表格存在，用来填充日期和数量
//   const appsTableBody = document.getElementById("apps-body");
//   const countLabel    = document.getElementById("countLabel");

//   // 如果两个 widget 都不存在，直接返回
//   if (!sankeyEl && !appsList && !appsTableBody) return;

//   // 防止同一轮渲染里重复跑
//   if (jobsPageRan) {
//     if (!appsList || appsList.dataset.filled === "1") return;
//   }
//   jobsPageRan = true;

//   async function safeJSON(url) {
//     const resp = await fetch(url, { headers: { Accept: "application/json" } });
//     const ct = resp.headers.get("content-type") || "";
//     if (!ct.includes("application/json")) {
//       console.warn(`[jobs_page] ${url} returned non-JSON (likely redirect/login).`);
//       return null;
//     }
//     return resp.json();
//   }

//   // 把 /applications.json 里的日期同步到表格第二列“Applied on”
//   function syncTableDates(rows) {
//     if (!appsTableBody) return;
//     const trs = Array.from(appsTableBody.querySelectorAll("tr"));
//     if (!trs.length) return;

//     rows.forEach((r, idx) => {
//       const tr = trs[idx];
//       if (!tr) return;

//       const appliedOn =
//         r.applied_on || (r.created_at ? r.created_at.slice(0, 10) : "");

//       // 当前表头是：Company | Applied on | Job posting | Status | Actions
//       const tds = tr.querySelectorAll("td");
//       if (tds.length >= 2) {
//         tds[1].textContent = appliedOn || "—";
//       }
//     });

//     if (countLabel) {
//       countLabel.textContent = `${rows.length} items`;
//     }
//   }

//   // Sankey
//   if (sankeyEl) {
//     safeJSON("/applications/stats.json")
//       .then((data) => {
//         if (!data) return;
//         const link = {
//           source: data.links.map((l) => l.source),
//           target: data.links.map((l) => l.target),
//           value: data.links.map((l) => l.value),
//         };
//         const trace = { type: "sankey", node: { label: data.nodes }, link };
//         Plotly.react(sankeyEl, [trace], {
//           margin: { l: 10, r: 10, t: 10, b: 10 },
//         });
//       })
//       .catch((err) => console.error("[jobs_page] sankey error:", err));
//   }

//   // Applications list (with one retry)
//   const fillApps = async (attempt = 1) => {
//     if (!appsList && !appsTableBody) return;
//     try {
//       const rows = await safeJSON("/applications.json");
//       if (!rows) {
//         console.warn("[jobs_page] /applications.json not JSON; skip render.");
//         return;
//       }

//       // 填原来的 <ul id="applications">
//       if (appsList) {
//         appsList.dataset.filled = "1";
//         appsList.innerHTML = rows
//           .map(
//             (r) => `
//         <li data-company="${r.company}">
//           <span class="company">${r.company}</span>
//           <span class="stage">${r.status}</span>
//         </li>`
//           )
//           .join("");
//       }

//       // 额外：同步日期到表格的 “Applied on” 列（不改 Actions/下拉框）
//       syncTableDates(rows);
//     } catch (e) {
//       if (attempt === 1) {
//         setTimeout(() => fillApps(2), 150);
//       } else {
//         console.error("[jobs_page] list error:", e);
//       }
//     }
//   };

//   fillApps();
// }


// app/javascript/jobs_page.js  （或你当前这个文件的路径）

let jobsPageRan = false;

/**
 * 批量删除选中的行
 * - 会找所有 .row-select:checked
 * - 对每个 id 调用 DELETE /applications/:id
 * - 成功后直接 reload 一下页面（最简单也最稳）
 */
function handleBulkDelete() {
  const selected = Array.from(
    document.querySelectorAll(".row-select:checked")
  );

  if (!selected.length) {
    alert("No rows selected");
    return;
  }

  if (!confirm(`Delete ${selected.length} selected item(s)?`)) {
    return;
  }

  const ids = selected.map((cb) => cb.dataset.id);
  console.log("[bulk delete] deleting ids:", ids);

  Promise.all(
    ids.map((id) =>
      fetch(`/applications/${id}`, {
        method: "DELETE",
        headers: { Accept: "application/json" },
      }).then((r) => {
        if (!r.ok && r.status !== 204) {
          throw new Error(`Delete failed for ${id}`);
        }
      })
    )
  )
    .then(() => {
      // 最简单：整页刷新，列表和 Sankey 都会重新加载
      window.location.reload();
    })
    .catch((e) => {
      console.error("[bulk delete] failed:", e);
      alert("Bulk delete failed (see console for details)");
    });
}

// 如果你想在别处用，也可以挂到 window 上（可选）
window.handleBulkDelete = handleBulkDelete;

export function initJobsPage() {
  const sankeyEl = document.getElementById("sankey");
  const appsList = document.getElementById("applications");

  // dashboard 表格
  const appsTableBody = document.getElementById("apps-body");
  const countLabel    = document.getElementById("countLabel");
  const bulkDeleteBtn = document.getElementById("bulkDeleteBtn");

  // ⭐ 在这里绑定 Delete selected 按钮
  if (bulkDeleteBtn) {
    bulkDeleteBtn.addEventListener("click", handleBulkDelete);
  }

  // 如果三个 widget 都不存在，直接返回
  if (!sankeyEl && !appsList && !appsTableBody) return;

  // 防止同一轮渲染里重复跑
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

  // 把 /applications.json 里的日期同步到表格第二列“Applied on”
  function syncTableDates(rows) {
    if (!appsTableBody) return;
    const trs = Array.from(appsTableBody.querySelectorAll("tr"));
    if (!trs.length) return;

    rows.forEach((r, idx) => {
      const tr = trs[idx];
      if (!tr) return;

      const appliedOn =
        r.applied_on || (r.created_at ? r.created_at.slice(0, 10) : "");

      // 当前表头是：Company | Applied on | Job posting | Status | Actions
      const tds = tr.querySelectorAll("td");
      if (tds.length >= 2) {
        tds[1].textContent = appliedOn || "—";
      }
    });

    if (countLabel) {
      countLabel.textContent = `${rows.length} items`;
    }
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
        Plotly.react(sankeyEl, [trace], {
          margin: { l: 10, r: 10, t: 10, b: 10 },
        });
      })
      .catch((err) => console.error("[jobs_page] sankey error:", err));
  }

  // Applications list (with one retry)
  const fillApps = async (attempt = 1) => {
    if (!appsList && !appsTableBody) return;
    try {
      const rows = await safeJSON("/applications.json");
      if (!rows) {
        console.warn("[jobs_page] /applications.json not JSON; skip render.");
        return;
      }

      // 填原来的 <ul id="applications">
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

      // 同步日期到表格的 “Applied on” 列
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
