package example

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"

	deploy "cloud.google.com/go/deploy/apiv1"
	"cloud.google.com/go/deploy/apiv1/deploypb"
	"cloud.google.com/go/pubsub"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/codingconcepts/env"
	"google.golang.org/api/option"
)

// Config struct for storing environment variables
type config struct {
	// Project and pipeline configurations
	ProjectId   string `env:"PROJECTID" required:"true"`
	Location    string `env:"LOCATION" required:"true"`
	Pipeline    string `env:"PIPELINE" required:"true"`
	TriggerID   string `env:"TRIGGER" required:"true"`
	SendTopicID string `env:"SENDTOPICID" required:"true"`
}

// Global configuration variable
var c config

// Initializes environment variables and registers the deployTrigger function
func init() {
	// Register CloudEvent function with a name for deployment
	functions.CloudEvent("deployTrigger", deployTrigger)
	// Load environment variables into config struct
	if err := env.Set(&c); err != nil {
		_ = fmt.Errorf("error getting env: %s", err)
	}
}

// Structs for parsing Pub/Sub messages
type PubSubMessage struct {
	Data []byte `json:"data"`
}

type MessagePublishedData struct {
	Message PubSubMessage
}

// CommandMessage struct defines the message sent to Pub/Sub
type CommandMessage struct {
	Commmand      string                        `json:"command"`
	CreateRelease deploypb.CreateReleaseRequest `json:"createReleaseRequest"`
}

// Main deployTrigger function is called upon a Pub/Sub trigger
func deployTrigger(ctx context.Context, e event.Event) error {
	log.Printf("Deploy trigger function invoked")

	// Parse the Pub/Sub message data into MessagePublishedData struct
	var msg MessagePublishedData
	if err := e.DataAs(&msg); err != nil {
		return fmt.Errorf("event.DataAs: %w", err)
	}

	// Unmarshal CloudBuild data into BuildMessage struct
	log.Printf("Converting Byte to Struct Object")
	var buildNotification BuildMessage
	if err := json.Unmarshal(msg.Message.Data, &buildNotification); err != nil {
		return fmt.Errorf("error parsing JIRA notification: %v", err)
	}

	// Check for specific build criteria (trigger ID and status)
	log.Printf("Checking if proper build")
	if buildNotification.BuildTriggerID != c.TriggerID || buildNotification.Status != "SUCCESS" {
		log.Printf("Build trigger ID or status does not match, returning early")
		// Return nil to indicate successful processing without further actions
		return nil
	}

	// Extract relevant image information from the build notification
	log.Printf("Pulling relevant image")
	image := buildNotification.Artifacts.Images[0]
	log.Printf("Received Image from Cloud Build: %s", image)

	// Create a Cloud Deploy client for further interactions
	deployClient, err := deploy.NewCloudDeployClient(ctx,
		option.WithUserAgent("cloud-solutions/platform-engineering-cloud-deploy-pipeline-code-v1"),
	)
	if err != nil {
		return fmt.Errorf("error creating Cloud Deploy client: %v", err)
	}
	defer deployClient.Close()

	// Construct the name of the delivery pipeline from environment variables
	pipelineName := fmt.Sprintf("projects/%s/locations/%s/deliveryPipelines/%s", c.ProjectId, c.Location, c.Pipeline)
	// Retrieve the delivery pipeline information
	pipeline, err := deployClient.GetDeliveryPipeline(ctx, &deploypb.GetDeliveryPipelineRequest{
		Name: pipelineName,
	})
	if err != nil {
		return fmt.Errorf("error getting delivery pipeline: %v", err)
	}

	// Generate a unique release ID with a random suffix
	randomID, err := generateRandomID(6) // Generate a random ID of 6 bytes (12 hex characters)
	if err != nil {
		log.Fatalf("Error generating random ID: %v", err)
	}
	releaseID := fmt.Sprintf("release-%s", randomID) // Set the release ID

	// Define a new release request with the image and pipeline details
	var command = CommandMessage{
		Commmand: "CreateRelease",
		CreateRelease: deploypb.CreateReleaseRequest{
			Parent:    pipeline.Name,
			ReleaseId: releaseID,
			Release: &deploypb.Release{
				// Configure the release with image details
				BuildArtifacts: []*deploypb.BuildArtifact{
					{
						Tag:   image,   // Set the container image
						Image: "pizza", // Placeholder for substitution in run.yaml
					},
				},
				// Skaffold config details for deployment
				SkaffoldConfigUri: fmt.Sprintf("%s/%s.tar.gz",
					buildNotification.Substitutions.DeployGCS,
					buildNotification.Substitutions.CommitSha,
				),
				SkaffoldConfigPath: "skaffold.yaml", // Path to Skaffold config file
			},
		},
	}

	// Send the command message to Pub/Sub for deployment
	err = sendCommandPubSub(ctx, &command)
	if err != nil {
		return fmt.Errorf("failed to send pubsub command: %v", err)
	}
	log.Printf("Deployment triggered successfully")
	return nil
}

// generateRandomID creates a random hexadecimal ID of specified length
func generateRandomID(length int) (string, error) {
	// Create a byte slice of specified length
	bytes := make([]byte, length)
	// Fill the byte slice with random data
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	// Return the hexadecimal representation of random bytes
	return hex.EncodeToString(bytes), nil
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