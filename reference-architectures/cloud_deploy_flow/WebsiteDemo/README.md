# Pub/Sub Local Demo

This project is a simple demonstration of a Pub/Sub system using Google Cloud
Pub/Sub and a basic Express.js server. It is designed to visually understand how
messages are sent to and from Pub/Sub queues. The code provided is primarily for
demonstration purposes and is not intended for production use.

## Features

*   **Real-time Message Display**: Messages from various Pub/Sub subscriptions
      are fetched and displayed in a web interface.
*   **Clear Messages**: Users can clear all displayed messages from the UI.
*   **Send Messages**: Users can send messages to the Pub/Sub topic via the
      input area.

## Project Structure

*   **public/index.html**: The main HTML file that provides the structure for
      the web interface.
*   **public/script.js**: Contains JavaScript logic for fetching messages,
      sending new messages, and clearing messages.
*   **public/styles.css**: Contains styling for the web interface to ensure a
      clean and responsive layout.
*   **index.js**: The main server file that handles Pub/Sub operations and
      serves static files.

## Installation

1.  Install the required dependencies:

      npm install

2.  Set your Google Cloud project ID and subscription names in the `index.js` file.

3.  Start the server:

      node index.js

4.  Open your web browser and go to `http://localhost:8080` to access the demo.

## Usage

*   **Sending Messages**: Enter a message in the textarea and click "Submit" to
      send it to the Pub/Sub topic.
*   **Viewing Messages**: The messages received from the Pub/Sub subscriptions
      will be displayed in their respective boxes.
*   **Clearing Messages**: Click the "Clear" button to remove all messages from
      the display.

## Disclaimer

This code is intended for educational and demonstration purposes only. It may
not be suitable for production environments due to lack of error handling,
security considerations, and scalability.
