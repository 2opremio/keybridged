# keybridged

keybridged is a Go HTTP daemon that sends key events to hardware bridges over UART or USB CDC.
It is the companion backend for bridge firmwares:
- [PicoUSBKeyBridge](https://github.com/2opremio/PicoUSBKeyBridge#serial-protocol) (UART -> USB HID keyboard)
- [NordicBTKeyBridge](https://github.com/2opremio/NordicBTKeyBridge) (USB CDC -> BLE HID keyboard)

If you’re deciding which bridge to use:
- **Need a wired USB keyboard** presented to the target host → PicoUSBKeyBridge
- **Need a Bluetooth LE keyboard** presented to the target host → NordicBTKeyBridge

## What it does

- Keeps a persistent connection to the bridge’s **serial transport** (USB CDC or a USB-to-UART adapter).
- Retries forever and logs device output to stdout.
- Exposes a small HTTP API for sending key events.

## Build and run

```
go run github.com/2opremio/keybridged/cmd@latest
```

macOS deployment:

```
./scripts/deploy_macos.sh
```

Flags:

- `-host` (default: `localhost`)
- `-port` (default: `8080`)
- `-send-timeout` (default: `2`) seconds to wait when queueing an event
- `-vid` (default: `0x1915`) USB VID for the **serial transport device**
- `-pid` (default: `0x520F`) USB PID for the **serial transport device**

Note: these flags do **not** refer to the HID keyboard identity (USB HID VID/PID or BLE PnP ID). They are only used to locate the serial device that `keybridged` talks to.

Examples:

- NordicBTKeyBridge (nRF52840 USB CDC, default):

```
./keybridged -vid 0x1915 -pid 0x520F
```

- PicoUSBKeyBridge using an FT232 USB-to-UART adapter (example hardware):

```
./keybridged -vid 0x0403 -pid 0x6001
```

## HTTP API

`POST /pressandrelease` sends a single event (press + release). If `type` is
omitted, it defaults to `keyboard`.

Request body:

```
{
  "type": <string> ("keyboard"|"consumer"),
  "code": <uint16>,
  "modifiers": {
    "left_ctrl": <bool>,
    "left_shift": <bool>,
    "left_alt": <bool>,
    "left_gui": <bool>,
    "right_ctrl": <bool>,
    "right_shift": <bool>,
    "right_alt": <bool>,
    "right_gui": <bool>,
    "apple_fn": <bool>
  }
}
```

- `type`:
  - `"keyboard"`: standard key presses (letters, numbers, modifiers, function keys).
  - `"consumer"`: media/system controls (volume, play/pause, keyboard layout toggle).
- `code` is a HID usage ID. See the on-wire details and code references in the serial protocol docs: [PicoUSBKeyBridge#serial-protocol](https://github.com/2opremio/PicoUSBKeyBridge#serial-protocol).
  - `keyboard`: USB HID Keyboard/Keypad keycode (8-bit; the JSON field is `uint16` for convenience). `code: 0` means "modifier-only" (no key pressed).
  - `consumer`: USB HID Consumer Page (0x0C) usage (16-bit).
- Keyboard modifiers (optional, macOS symbols/Apple names):
  - `left_ctrl` (⌃ Ctrl), `left_shift` (⇧ Shift), `left_alt` (⌥ Option), `left_gui` (⌘ Command)
  - `right_ctrl` (⌃ Ctrl), `right_shift` (⇧ Shift), `right_alt` (⌥ Option), `right_gui` (⌘ Command)
  - `apple_fn` (Fn) sets the Apple Fn bit in the keyboard report

If there’s demand, we can add a WebSocket API for more efficient key-event streaming than one HTTP request per key, and for real-time device log streaming.

### Examples

Send letter `A` (`a` (HID code 4) + `Shift`):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":4,"modifiers":{"left_shift":true}}'
```

Hide/show iPad keyboard (AL Keyboard Layout / consumer usage 0x01AE):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"consumer","code":430}'
```

Play/Pause (consumer usage 0x00CD):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"consumer","code":205}'
```

Send only Apple Fn (modifier-only, no key):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":0,"modifiers":{"apple_fn":true}}'
```

## Client library

There is a small Go client in `client/` for calling the HTTP API.

```go
package main

import "github.com/2opremio/keybridged/client"

kbClient := client.New(client.Config{
	Host: "localhost:8080",
})
err := kbClient.SendPressAndRelease(ctx, client.PressAndReleaseRequest{
	Type: "keyboard",
	Code: 0x04,
	Modifiers: &client.PressAndReleaseModifiers{
		LeftShift: true,
	},
}) // A with Shift
```

## Serial protocol details

Serial protocol documentation lives in [PicoUSBKeyBridge#serial-protocol](https://github.com/2opremio/PicoUSBKeyBridge#serial-protocol).
