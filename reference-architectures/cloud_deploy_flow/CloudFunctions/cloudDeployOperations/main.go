package example

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"cloud.google.com/go/deploy/apiv1/deploypb"
	"cloud.google.com/go/pubsub"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/codingconcepts/env"
	"google.golang.org/api/option"
)

// Config struct for environment variables; contains details necessary for deployment.
type config struct {
	// ProjectId and Location might be auto-detectable in some cases but are set here as required environment variables.
	ProjectId   string `env:"PROJECTID" required:"true"`
	Location    string `env:"LOCATION" required:"true"`
	SendTopicID string `env:"SENDTOPICID" required:"true"`
}

// PubsubMessage represents the structure for a Pub/Sub message.
type PubsubMessage struct {
	Data        []byte         `json:"data"`        // Payload of the message.
	Attributes  OperationsData `json:"attributes"`  // Metadata attributes for the message.
	MessageID   string         `json:"messageId"`   // Server-generated message ID.
	PublishTime time.Time      `json:"publishTime"` // Timestamp for when the message was published.
	OrderingKey string         `json:"orderingKey"` // Ordering key for message ordering.
}

// Message wraps the PubsubMessage structure in the JSON object expected by the Cloud Run Function.
type Message struct {
	Message PubsubMessage `json:"message"`
}

// OperationsData holds metadata about the deployment operation, such as action and resource type.
type OperationsData struct {
	Action             string `json:"Action"`
	Resource           string `json:"Resource"`
	ResourceType       string `json:"ResourceType"`
	Location           string `json:"Location"`
	DeliveryPipelineId string `json:"DeliveryPipelineId"`
	ProjectNumber      string `json:"ProjectNumber"`
	ReleaseId          string `json:"ReleaseId"`
	RolloutId          string `json:"RolloutId"`
}

// CommandMessage struct defines commands that are sent to Pub/Sub, including deployment actions.
type CommandMessage struct {
	Commmand      string                        `json:"command"`
	CreateRollout deploypb.CreateRolloutRequest `json:"createRolloutRequest"`
}

var c config

// init initializes the function and loads environment variables into the config struct.
func init() {
	functions.CloudEvent("cloudDeployOperations", cloudDeployOperations)

	// Load environment variables into the config struct using the env package.
	if err := env.Set(&c); err != nil {
		_ = fmt.Errorf("error getting env: %s", err)
	}
}

// cloudDeployOperations is triggered by a CloudEvent to process deployment events and initiate rollouts.
func cloudDeployOperations(ctx context.Context, e event.Event) error {
	log.Printf("Deploy Operations function invoked")

	// Parse event data into Message struct
	var msg Message
	err := json.Unmarshal(e.Data(), &msg)
	if err != nil {
		// Acknowledge the message by returning nil, even if it’s bad, to prevent reprocessing.
		_ = fmt.Errorf("errored unmarshalling data: %v", err)
		return nil
	}

	// Extract attributes from the message for validation and processing.
	var a = msg.Message.Attributes

	// Check if the message indicates a successful release event for further processing.
	if a.ResourceType == "Release" && a.Action == "Succeed" {
		log.Printf("Creating Rollout and sending to pubsub")

		// Define a rollout command message with details from OperationsData.
		var command = CommandMessage{
			Commmand: "CreateRollout",
			CreateRollout: deploypb.CreateRolloutRequest{
				Parent:    a.Resource,  // The deployment resource to associate with this rollout
				RolloutId: a.ReleaseId, // The ID of the release
				Rollout: &deploypb.Rollout{
					// TODO: TargetId should ideally come from the Pub/Sub message rather than hardcoded.
					TargetId: "random-date-service",
				},
			},
		}

		// Send the command to Pub/Sub and log any errors that occur.
		err = sendCommandPubSub(ctx, &command)
		if err != nil {
			_ = fmt.Errorf("failed to send pubsub command: %v", err)
			// Acknowledge the message even if there's a failure to prevent repeated processing.
			return nil
		}
		log.Printf("Deployment triggered successfully")
	}
	return nil
}

// sendCommandPubSub publishes a CommandMessage to a specified Pub/Sub topic to trigger further actions.
func sendCommandPubSub(ctx context.Context, m *CommandMessage) error {
	// Create a new Pub/Sub client to publish messages.
	client, err := pubsub.NewClient(ctx,
		c.ProjectId,
		option.WithUserAgent("cloud-solutions/platform-engineering-cloud-deploy-pipeline-code-v1"),
	)
	if err != nil {
		return fmt.Errorf("pubsub.NewClient: %v", err)
	}
	defer client.Close() // Ensure client is closed when done

	// Define the topic for message publication based on environment configuration.
	t := client.Topic(c.SendTopicID)

	// Marshal the CommandMessage into JSON format for the Pub/Sub message data payload.
	jsonData, err := json.Marshal(m)
	if err != nil {
		return fmt.Errorf("json.Marshal: %v", err)
	}

	log.Printf("Sending message to PubSub")
	// Publish the JSON data as a Pub/Sub message and wait for the message ID.
	result := t.Publish(ctx, &pubsub.Message{
		Data: jsonData, // Serialized JSON command message
	})

	// Block until the result returns the server-generated ID for the published message.
	id, err := result.Get(ctx)
	log.Printf("ID: %s, err: %v", id, err)
	if err != nil {
		fmt.Printf("Get: %v", err)
		return nil
	}

	log.Printf("Published a message; msg ID: %v\n", id)
	return nil
}
