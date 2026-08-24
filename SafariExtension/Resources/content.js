(() => {
  if (globalThis.__careerPilotInstalled) return;
  globalThis.__careerPilotInstalled = true;

  const clean = (value, limit = 200) =>
    String(value ?? "").replace(/\s+/g, " ").trim().slice(0, limit);

  const labelFor = (element) => {
    const explicit = element.id
      ? document.querySelector(`label[for="${CSS.escape(element.id)}"]`)
      : null;
    const wrapping = element.closest("label");
    return clean(
      explicit?.innerText ||
      wrapping?.innerText ||
      element.getAttribute("aria-label") ||
      element.placeholder ||
      element.name
    );
  };

  const referenceFor = (element, index) =>
    clean(
      element.id ||
      element.name ||
      element.getAttribute("data-testid") ||
      `career-pilot-field-${index}`
    );

  const describeFields = () =>
    Array.from(document.querySelectorAll("input, textarea, select"))
      .filter((element) => element.type !== "hidden")
      .slice(0, 250)
      .map((element, index) => ({
        reference: referenceFor(element, index),
        label: labelFor(element),
        name: clean(element.name),
        type: clean(element.type || element.tagName.toLowerCase()),
        autocomplete: clean(element.autocomplete),
        required: Boolean(element.required),
        disabled: Boolean(element.disabled)
      }));

  const capturePage = () => ({
    url: location.href,
    title: clean(document.title, 500),
    capturedAt: new Date().toISOString(),
    text: clean(document.body?.innerText, 50000),
    fields: describeFields()
  });

  browser.runtime.onMessage.addListener((message) => {
    if (message?.type === "CAPTURE_PAGE") {
      return Promise.resolve(capturePage());
    }
    return false;
  });
})();
