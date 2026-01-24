package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

const defaultHost = "localhost:8080"

type Client struct {
	baseURL string
	http    *http.Client
}

type Config struct {
	Host       string
	HTTPClient *http.Client
}

func New(config Config) *Client {
	httpClient := config.HTTPClient
	if httpClient == nil {
		httpClient = &http.Client{}
	}
	host := strings.TrimSpace(config.Host)
	if host == "" {
		host = defaultHost
	}
	baseURL := "http://" + strings.TrimRight(host, "/")
	return &Client{
		baseURL: baseURL,
		http:    httpClient,
	}
}

// PressAndReleaseModifiers matches the `modifiers` object in the HTTP API.
// It applies to `Type: "keyboard"` requests (consumer events ignore modifiers).
type PressAndReleaseModifiers struct {
	LeftCtrl   bool `json:"left_ctrl,omitempty"`   // ⌃ Ctrl
	LeftShift  bool `json:"left_shift,omitempty"`  // ⇧ Shift
	LeftAlt    bool `json:"left_alt,omitempty"`    // ⌥ Option
	LeftGUI    bool `json:"left_gui,omitempty"`    // ⌘ Command
	RightCtrl  bool `json:"right_ctrl,omitempty"`  // ⌃ Ctrl
	RightShift bool `json:"right_shift,omitempty"` // ⇧ Shift
	RightAlt   bool `json:"right_alt,omitempty"`   // ⌥ Option
	RightGUI   bool `json:"right_gui,omitempty"`   // ⌘ Command
	AppleFn    bool `json:"apple_fn,omitempty"`    // Fn/Globe
}

// PressAndReleaseRequest matches the `POST /pressandrelease` request body.
//
// See the shared serial protocol docs (also includes code references and examples):
// https://github.com/2opremio/PicoUSBKeyBridge#serial-protocol
type PressAndReleaseRequest struct {
	// Type selects the HID usage page used by Code.
	// Supported values:
	//   - "keyboard": USB HID Keyboard/Keypad usage page
	//   - "consumer": USB HID Consumer Page (0x0C)
	//
	// If omitted/empty, the server defaults it to "keyboard".
	Type string `json:"type,omitempty"`

	// Code is the HID usage for the selected Type.
	//
	// For Type "keyboard", Code is an 8-bit USB HID keycode (stored in a uint16 for convenience).
	// Code=0 is allowed only for modifier-only keyboard events.
	//
	// For Type "consumer", Code is a 16-bit Consumer Page (0x0C) usage (e.g. 0x00CD Play/Pause).
	Code      uint16                    `json:"code"`
	Modifiers *PressAndReleaseModifiers `json:"modifiers,omitempty"`
}

func (c *Client) SendPressAndRelease(ctx context.Context, req PressAndReleaseRequest) error {
	payload, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("marshal pressandrelease: %w", err)
	}
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/pressandrelease", bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("build pressandrelease request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	resp, err := c.http.Do(httpReq)
	if err != nil {
		return fmt.Errorf("send pressandrelease request: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return fmt.Errorf("pressandrelease request failed: %s (%s)", resp.Status, string(body))
	}
	return nil
}
