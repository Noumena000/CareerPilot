const status = document.querySelector("#status");
const checkButton = document.querySelector("#check");
const captureButton = document.querySelector("#capture");

async function run(button, task) {
  button.disabled = true;
  try {
    await task();
  } catch (error) {
    status.textContent = error?.message || "CareerPilot could not complete the request.";
  } finally {
    button.disabled = false;
  }
}

checkButton.addEventListener("click", () => run(checkButton, async () => {
  status.textContent = "Checking native bridge…";
  const response = await browser.runtime.sendMessage({ type: "PING_NATIVE" });
  status.textContent = response?.ok
    ? "Safari bridge verified. OpenClaw is not configured yet."
    : "Native bridge did not verify.";
}));

captureButton.addEventListener("click", () => run(captureButton, async () => {
  status.textContent = "Reading the active page…";
  const result = await browser.runtime.sendMessage({ type: "CAPTURE_ACTIVE_PAGE" });
  const count = result?.capture?.fields?.length ?? 0;
  status.textContent = `Captured “${result?.capture?.title || "Untitled page"}” with ${count} visible fields. Nothing was filled or submitted.`;
}));
