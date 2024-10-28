let lastMessageData = {}; // Store last fetched messages to compare updates

    // Function to update the messages on the webpage
    function updateMessages() {
      fetch('/messages')
        .then(response => response.json())
        .then(data => {
          const subscriptionMap = {
            'build_notifications_subscription': 'build_notifications_subscription',
            'deploy-commands-subscription': 'deploy-commands-subscription',
            'clouddeploy-operations-subscription': 'clouddeploy-operations-subscription',
            'clouddeploy-approvals-subscription': 'clouddeploy-approvals-subscription'
          };

          // Loop through each subscription and update its content
          for (const subscriptionName in subscriptionMap) {
            const messages = data[subscriptionName] || [];
            const messageContainer = document.getElementById(subscriptionMap[subscriptionName]);

            // Only update if there are new messages
            if (!lastMessageData[subscriptionName] || lastMessageData[subscriptionName].length !== messages.length) {
              messageContainer.innerHTML = ''; // Clear previous messages

              // Add new messages with pretty-printed JSON
              messages.forEach(message => {
                const messageDiv = document.createElement('div');
                messageDiv.className = 'message';
                messageDiv.textContent = JSON.stringify({
                  id: message.id,
                  data: message.data,
                  attributes: message.attributes
                }, null, 2); // Prettify JSON with indentation
                messageContainer.appendChild(messageDiv);
              });
            }
          }

          // Save the latest message data to compare on the next refresh
          lastMessageData = data;
        });
    }

    // Function to clear all messages (both frontend and backend)
    function clearMessages() {
      fetch('/clear-messages', {
        method: 'POST'
      })
      .then(response => {
        if (response.ok) {
          lastMessageData = {}; // Clear the frontend message data
          updateMessages(); // Update the frontend to show empty message boxes
        }
      })
      .catch(error => console.error('Error clearing messages:', error));
    }

    /*function updateMessages() {
        fetch('/messages')
          .then(response => response.json())
          .then(data => {
            // Clear previous messages from each box
            document.getElementById('clouddeploy-approvals-subscription').innerHTML = '';
            document.getElementById('deploy-commands-subscription').innerHTML = '';
            document.getElementById('clouddeploy-operations-subscription').innerHTML = '';
            document.getElementById('build_notifications_subscription').innerHTML = '';
      
            // Update each subscription box with the respective messages
            if (data.clouddeploy_approvals_subscription) {
              const approvalsMessages = data.clouddeploy_approvals_subscription;
              const approvalsBox = document.getElementById('clouddeploy-approvals-subscription');
              approvalsMessages.forEach(message => {
                approvalsBox.innerHTML += `<p>${JSON.stringify(message, null, 2)}</p>`;
              });
            }
      
            if (data.deploy_commands_subscription) {
              const deployMessages = data.deploy_commands_subscription;
              const deployBox = document.getElementById('deploy-commands-subscription');
              deployMessages.forEach(message => {
                deployBox.innerHTML += `<p>${JSON.stringify(message, null, 2)}</p>`;
              });
            }
      
            if (data.clouddeploy_operations_subscription) {
              const operationsMessages = data.clouddeploy_operations_subscription;
              const operationsBox = document.getElementById('clouddeploy-operations-subscription');
              operationsMessages.forEach(message => {
                operationsBox.innerHTML += `<p>${JSON.stringify(message, null, 2)}</p>`;
              });
            }
      
            if (data.build_notifications_subscription) {
              const buildMessages = data.build_notifications_subscription;
              const buildBox = document.getElementById('build_notifications_subscription');
              buildMessages.forEach(message => {
                buildBox.innerHTML += `<p>${JSON.stringify(message, null, 2)}</p>`;
              });
            }
          });
      }*/

  function sendMessage() {
    const messageInput = document.getElementById('message-input');
    let message = messageInput.value; 
    // Clean up the message
    message = message.trim(); // Remove leading and trailing whitespace
    message = message.replace(/\n/g, ''); // Remove newline characters
    

    // Send the message to the backend
    fetch('/send-message', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: message
    })
    .then(response => {
      if (response.ok) {
        messageInput.value = ''; // Clear the input after sending
        updateMessages(); // Optionally refresh messages after sending
      } else {
        console.error('Failed to send message');
      }
    })
    .catch(error => console.error('Error:', error));
  }

    // Automatically update messages every 3 seconds
    setInterval(updateMessages, 3000);