package example

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	deploy "cloud.google.com/go/deploy/apiv1"
	"cloud.google.com/go/deploy/apiv1/deploypb"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
)

// init registers the cloudDeployInteractions function as an event listener
// for cloud events with the name "cloudDeployInteractions".
func init() {
	functions.CloudEvent("cloudDeployInteractions", cloudDeployInteractions)
}

// PubSubMessage defines the structure for the Pub/Sub message data payload.
type PubSubMessage struct {
	Data []byte `json:"data"`
}

// MessagePublishedData represents the message structure when received from Pub/Sub.
type MessagePublishedData struct {
	Message PubSubMessage
}

// DeployCommand represents the deployment command types with their corresponding
// Cloud Deploy request data structures.
type DeployCommand struct {
	Commmand       string                         `json:"command"`               // Command type: CreateRelease, CreateRollout, or ApproveRollout
	CreateRelease  deploypb.CreateReleaseRequest  `json:"createReleaseRequest"`  // Data required to create a release
	CreateRollout  deploypb.CreateRolloutRequest  `json:"createRolloutRequest"`  // Data required to create a rollout
	ApproveRollout deploypb.ApproveRolloutRequest `json:"approveRolloutRequest"` // Data required to approve a rollout
}

// cloudDeployInteractions is the main function that handles cloud events and
// processes deployment commands based on incoming Pub/Sub messages.
func cloudDeployInteractions(ctx context.Context, e event.Event) error {
	log.Printf("Deploy trigger function invoked")

	// Parse the Pub/Sub message into MessagePublishedData structure
	var msg MessagePublishedData
	if err := e.DataAs(&msg); err != nil {
		return fmt.Errorf("event.DataAs: %w", err)
	}

	// Unmarshal the Pub/Sub message data into the DeployCommand structure
	log.Printf("Converting Byte to Struct Object")
	var c DeployCommand
	if err := json.Unmarshal(msg.Message.Data, &c); err != nil {
		log.Printf("Failed to unmarshal to command, assuming bad command")
		return nil // Returning nil acknowledges the message, preventing reprocessing
	}

	// Create a new Cloud Deploy client to interact with Cloud Deploy services
	deployClient, err := deploy.NewCloudDeployClient(ctx)
	if err != nil {
		return fmt.Errorf("error creating Cloud Deploy client: %v", err)
	}
	defer deployClient.Close() // Ensure client is closed after function completes

	// Process the command based on its type (CreateRelease, CreateRollout, or ApproveRollout)
	switch c.Commmand {
	case "CreateRelease":
		if err := cdCreateRelease(ctx, *deployClient, &c.CreateRelease); err != nil {
			_ = fmt.Errorf("create release failed: %v", err)
			return nil
		}
	case "CreateRollout":
		if err := cdCreateRollout(ctx, *deployClient, &c.CreateRollout); err != nil {
			_ = fmt.Errorf("create rollout failed: %v", err)
			return nil
		}
	case "ApproveRollout":
		if err := cdApproveRollout(ctx, *deployClient, &c.ApproveRollout); err != nil {
			_ = fmt.Errorf("approve rollout failed: %v", err)
			return nil
		}
	}
	return nil
}

// cdCreateRelease sends a request to Google Cloud Deploy to create a new release
func cdCreateRelease(ctx context.Context, d deploy.CloudDeployClient, c *deploypb.CreateReleaseRequest) error {
	// Initiate the release creation operation
	releaseOp, err := d.CreateRelease(ctx, c)
	if err != nil {
		return fmt.Errorf("error creating release request: %v", err)
	}
	log.Printf("Created release operation: %s", releaseOp.Name())

	// Wait for the release operation to complete and check for errors
	_, err = releaseOp.Wait(ctx)
	if err != nil {
		return fmt.Errorf("error on release operation: %v", err)
	}
	log.Printf("Create Release Operation Completed")
	return nil
}

// cdCreateRollout sends a request to Google Cloud Deploy to create a rollout for a release
func cdCreateRollout(ctx context.Context, d deploy.CloudDeployClient, c *deploypb.CreateRolloutRequest) error {
	// Initiate the rollout creation operation
	rollout, err := d.CreateRollout(ctx, c)
	if err != nil {
		return fmt.Errorf("error creating rollout request: %v", err)
	}
	log.Printf("Created Rollout Request: %v", rollout.Name())

	// Wait for the rollout operation to complete and check for errors
	_, err = rollout.Wait(ctx)
	if err != nil {
		return fmt.Errorf("error on rollout operation: %v", err)
	}
	log.Printf("Create Rollout Operation Completed")
	return nil
}

// cdApproveRollout sends a request to Google Cloud Deploy to approve an existing rollout
func cdApproveRollout(ctx context.Context, d deploy.CloudDeployClient, c *deploypb.ApproveRolloutRequest) error {
	// Approve the rollout using the Cloud Deploy client
	_, err := d.ApproveRollout(ctx, c)
	if err != nil {
		return fmt.Errorf("error approving rollout request operation: %v", err)
	}
	log.Printf("Approved Rollout")
	return nil
}
