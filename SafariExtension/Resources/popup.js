const status = document.querySelector("#status");
const checkButton = document.querySelector("#check");
const captureButton = document.querySelector("#capture");
const askButton = document.querySelector("#ask");
const question = document.querySelector("#question");
const answer = document.querySelector("#answer");

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
    ? "Optional Safari bridge verified."
    : "Native bridge did not verify.";
}));

captureButton.addEventListener("click", () => run(captureButton, async () => {
  status.textContent = "Reading the active page…";
  const result = await browser.runtime.sendMessage({ type: "CAPTURE_ACTIVE_PAGE" });
  const count = result?.capture?.fields?.length ?? 0;
  status.textContent = `Captured “${result?.capture?.title || "Untitled page"}” with ${count} visible fields. Nothing was filled or submitted.`;
}));

askButton.addEventListener("click", () => run(askButton, async () => {
  const prompt = question.value.trim();
  if (!prompt) {
    status.textContent = "Ask a question about the active application first.";
    return;
  }
  status.textContent = "Reading the active page and drafting on-device…";
  answer.hidden = true;
  const result = await browser.runtime.sendMessage({ type: "ASK_ACTIVE_PAGE", prompt });
  const text = result?.native?.response || result?.native?.error || "CareerPilot did not return a draft.";
  answer.textContent = text;
  answer.hidden = false;
  status.textContent = `Context captured from “${result?.capture?.title || "the active page"}”. Review the draft before using it.`;
}));
