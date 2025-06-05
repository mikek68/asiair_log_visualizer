window.logMessagesButtonClick = function(element) {
  const className = element.dataset.class;
  const id = element.dataset.id;
  const url = `/logs/fetch_log_messages?class_name=${className}&id=${id}`; // Corrected URL construction

  // Remove any existing modal
  const existingModal = document.getElementById('logMessagesModal');
  if (existingModal) {
    const modal = bootstrap.Modal.getInstance(existingModal);
    if (modal) {
      modal.hide();
    }
    existingModal.remove();
  }

  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(logMessages => {
      if (logMessages.error) {
        console.error('Error loading log messages:', logMessages.error);
        alert(`Error loading log messages: ${logMessages.error}`);
        return;
      }

      // Create modal structure
      const modalElement = document.createElement('div');
      modalElement.classList.add('modal', 'fade');
      modalElement.id = 'logMessagesModal';
      modalElement.tabIndex = -1;
      modalElement.setAttribute('aria-labelledby', 'logMessagesModalLabel');
      modalElement.setAttribute('aria-hidden', 'true');

      modalElement.innerHTML = `
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="logMessagesModalLabel">${className} Logs (ID: ${id})</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <table class="table">
                <thead>
                  <tr>
                    <th scope="col">Log Time</th>
                    <th scope="col">Message</th>
                  </tr>
                </thead>
                <tbody>
                  ${logMessages.map(log => `
                    <tr>
                      <td>${new Date(log.time).toLocaleString()}</td>
                      <td>${log.message}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
          </div>
        </div>
      `;

      document.body.appendChild(modalElement);

      const modal = new bootstrap.Modal(modalElement);
      modal.show();
    })
    .catch(error => {
      console.error('Error loading log messages:', error);
      alert('Error loading log messages. See console for details.');
    });
}
