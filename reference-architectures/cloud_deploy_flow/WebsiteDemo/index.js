require('dotenv').config();

const {PubSub} = require('@google-cloud/pubsub');
const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;
const topicName = process.env.TOPIC_NAME || 'clouddeploy-approvals';

// Replace with your actual project ID and subscription names
const projectId = process.env.PROJECT_ID;
const subscriptionNames = [
  process.env.BUILD_NOTIFICATIONS_SUB || 'build_notifications_subscription',
  process.env.DEPLOY_COMMANDS_SUB || 'deploy-commands-subscription',
  process.env.CD_OPERATIONS_SUB || 'clouddeploy-operations-subscription',
  process.env.CD_APPROVALS_SUB || 'clouddeploy-approvals-subscription',
];
const timeout = 60;

const pubsubClient = new PubSub({projectId});

// Store messages per subscription
let messages = {};
subscriptionNames.forEach(name => {
  messages[name] = [];
});

// Function to pull messages from each subscription
async function pullMessages(pubSubClient, subscriptionName) {
  const subscription = pubSubClient.subscription(subscriptionName);

  const messageHandler = (message) => {
    console.log(`Received message ${message.id}:`);
    console.log(`\tData: ${message.data}`);
    console.log(`\tAttributes: ${JSON.stringify(message.attributes)}`);

    if (messages[subscriptionName]) {
        messages[subscriptionName].push({
        id: message.id,
        data: message.data.toString(),
        attributes: message.attributes,
      });
    }

    message.ack();
  };

  subscription.on('message', messageHandler);

  setTimeout(() => {
    subscription.removeListener('message', messageHandler);
  }, timeout * 1000);
}

// Main function to pull messages and serve static files
async function main() {
  setInterval(async () => {
    for (const subscriptionName of subscriptionNames) {
      await pullMessages(pubsubClient, subscriptionName);
    }
  }, 5000);

  app.use(express.static(path.join(__dirname, 'public')));
  app.use(express.json());
  app.use(express.urlencoded({extended: true})); // For parsing application/x-www-form-urlencoded

  // API endpoint to send messages to the frontend
  app.get('/messages', (req, res) => {
    res.json(messages);
  });

  // Endpoint to clear all messages
  app.post('/clear-messages', (req, res) => {
    // Clear the messages from all subscriptions
    for (const subscriptionName in messages) {
      messages[subscriptionName] = [];
    }
    console.log('All messages cleared.');
    res.sendStatus(200); // Respond with success
  });

  app.post('/send-message', async (req, res) => {
    console.log(`Req Body: ${JSON.stringify(req.body, null, 2)}`);
    try {
      const {data, attributes} = req.body;
      console.log(`Data: ${data}, Attributes: ${JSON.stringify(attributes)}`);

      const topic = pubsubClient.topic(topicName);

      // Create the message object with optional attributes
      const dataBuf = Buffer.from('{}'); // Convert data to Buffer

      // Publish the message to the Pub/Sub topic
      const messageId = await topic.publish(dataBuf, attributes);

      console.log(`Message sent with ID: ${messageId}`);

      // Send a success response
      res.status(200).send('Message published.');
    } catch (error) {
      console.error('Error publishing message:', error);

      // Send an error response
      res.status(500).send('Failed to publish message.');
    }
  });

  app.listen(port, () => {
    console.log(`Server is listening on port ${port}`);
  });
}

main().catch(console.error);
