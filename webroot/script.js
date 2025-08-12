let refreshing = false;
let lastData = {
  algorithm: "Unknown",
  size: "Unknown",
  used: "Unknown",
  ratio: "Unknown"
};
let fetchFailCount = 0; // Consecutive failure count

async function refreshZram() {
  if (refreshing) return;
  refreshing = true;

  try {
    const res = await fetch("tmp/status.json?ts=" + Date.now());
    if (!res.ok) throw new Error("Status file does not exist or server error");
    const json = await res.json();

    // If data is abnormal/missing, consider it a failure
    if (!json || !json.algorithm || !json.size || !json.used || !json.ratio) throw new Error("Status data incomplete");

    // Display data, clear error message
    setStatus(json.algorithm, autoUnit(json.size), autoUnit(json.used), json.ratio, false, "");
    lastData = {
      algorithm: json.algorithm,
      size: autoUnit(json.size),
      used: autoUnit(json.used),
      ratio: json.ratio
    };
    fetchFailCount = 0;
  } catch (e) {
    fetchFailCount++;
    // Only show full error on first load
    if (fetchFailCount === 1 && !lastData.hasOwnProperty("loadedOnce")) {
      setStatus("Error", "Error", "Error", "Error", false, "Failed to get status: " + e.message);
    } else if (fetchFailCount >= 3) {
      // Show full error after 3 consecutive failures
      setStatus("Error", "Error", "Error", "Error", false, "Failed to read status multiple times: " + e.message);
    } else {
      // Maintain current data on failure, show top alert
      setStatus(lastData.algorithm, lastData.size, lastData.used, lastData.ratio, false, "Failed to read status (network or write delay), retrying automatically...");
    }
  }
  lastData.loadedOnce = true;
  refreshing = false;
}

function autoUnit(str) {
  if (!str) return "";
  let n = parseInt(str, 10);
  if (isNaN(n)) return str;
  if (n > 1024 * 1024) return (n / 1024 / 1024).toFixed(2) + " GB";
  if (n > 1024) return (n / 1024).toFixed(2) + " MB";
  return n + " KB";
}

function setStatus(algo, size, used, ratio, skeleton, tip) {
  ["algo", "size", "used", "ratio"].forEach((id, i) => {
    const el = document.getElementById(id);
    el.classList.remove("skeleton");
    if (skeleton) el.classList.add("skeleton");
    if ([algo, size, used, ratio][i] !== null)
      el.innerText = [algo, size, used, ratio][i];
  });
  // Error tip
  let tipEl = document.getElementById("errtip");
  if (!tipEl) {
    tipEl = document.createElement("div");
    tipEl.id = "errtip";
    tipEl.style = "color:#d00;text-align:center;margin-top:8px;";
    document.getElementById("zram-status").appendChild(tipEl);
  }
  tipEl.innerText = tip || "";
}

window.addEventListener("DOMContentLoaded", () => {
  // Show skeleton screen initially
  setStatus("Loading...", "Loading...", "Loading...", "Loading...", true, "");
  refreshZram();
  setInterval(refreshZram, 1000);
  document.getElementById("refresh-btn")?.addEventListener("click", (e) => {
    if (refreshing) e.preventDefault();
    else refreshZram();
  });
});
