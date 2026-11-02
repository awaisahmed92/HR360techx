/* GA4. Paste the measurement ID from Analytics. Leave the placeholder and this file does nothing. */
(function () {
  var measurementId = "G-XXXXXXXX";
  if (!/^G-[A-Z0-9]+$/.test(measurementId) || measurementId === "G-XXXXXXXX") return;

  var script = document.createElement("script");
  script.async = true;
  script.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(measurementId);
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  function gtag() { window.dataLayer.push(arguments); }
  window.gtag = gtag;
  gtag("js", new Date());
  gtag("config", measurementId);
})();
