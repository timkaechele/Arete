document.addEventListener('DOMContentLoaded', function() {
  var configurationForm = document.getElementById('configuration-form');
  var testConfigurationButton = document.getElementById("test-configuration-button");
  var baseUrlInput = document.getElementById("url-input");
  var tokenInput = document.getElementById("token-input");
  var outputUrlContent = document.getElementById("url-output");
  var processingDisplay = document.getElementById("processing");
  var successDisplay = document.getElementById("success-output");
  var errorDisplay = document.getElementById("error");

  configurationForm.addEventListener("submit", function(event) {
    errorDisplay.classList.add('hidden');
    successDisplay.classList.add('hidden');
    processingDisplay.classList.add('hidden');
    baseUrlInput.classList.remove('input-error');
    tokenInput.classList.remove('input-error');

    event.preventDefault();
    var url;
    try {
      url = new URL(baseUrlInput.value);
    } catch (e) {
      baseUrlInput.classList.add('input-error');
      return
    }

    var calendarUrl = new URL('/calendar.ics', window.location.href);
    var calendarUrlParams = calendarUrl.searchParams;
    calendarUrlParams.append('protocol', url.protocol.slice(0, -1));
    calendarUrlParams.append('url', url.hostname);
    calendarUrlParams.append('token', tokenInput.value);

    processingDisplay.classList.remove('hidden');
    window.scrollBy({ top: processingDisplay.offsetTop, left: 0, behavior: "smooth" });

    fetch(calendarUrl.href).then(function(response) {
      processingDisplay.classList.add('hidden');
      if (!response.ok) {
        baseUrlInput.classList.add('input-error');
        tokenInput.classList.add('input-error');
        errorDisplay.classList.remove('hidden');
      } else {
        successDisplay.classList.remove('hidden');
        baseUrlInput.classList.remove('input-error');
        tokenInput.classList.remove('input-error');
        outputUrlContent.innerHTML = calendarUrl.href;
      }
    })
  })
})


