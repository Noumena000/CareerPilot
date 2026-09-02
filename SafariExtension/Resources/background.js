const NATIVE_APP_ID = "com.noumena.CareerPilot.Extension";

async function activeTab() {
  const tabs = await browser.tabs.query({ active: true, currentWindow: true });
  if (!tabs.length || !tabs[0].id) {
    throw new Error("No active Safari tab is available.");
  }
  return tabs[0];
}

browser.runtime.onMessage.addListener(async (message) => {
  if (message?.type === "PING_NATIVE") {
    return browser.runtime.sendNativeMessage(NATIVE_APP_ID, { type: "PING" });
  }

  if (message?.type === "CAPTURE_ACTIVE_PAGE") {
    const tab = await activeTab();
    await browser.scripting.executeScript({
      target: { tabId: tab.id },
      files: ["content.js"]
    });
    const capture = await browser.tabs.sendMessage(tab.id, { type: "CAPTURE_PAGE" });
    const native = await browser.runtime.sendNativeMessage(NATIVE_APP_ID, {
      type: "PAGE_CAPTURE",
      capture
    });
    return { capture, native };
  }

  if (message?.type === "ASK_ACTIVE_PAGE") {
    const tab = await activeTab();
    await browser.scripting.executeScript({
      target: { tabId: tab.id },
      files: ["content.js"]
    });
    const capture = await browser.tabs.sendMessage(tab.id, { type: "CAPTURE_PAGE" });
    const native = await browser.runtime.sendNativeMessage(NATIVE_APP_ID, {
      type: "CHAT_REQUEST",
      prompt: message.prompt,
      capture
    });
    return { capture, native };
  }

  throw new Error("Unsupported CareerPilot message.");
});
