# keybridged

keybridged is a Go HTTP daemon that sends key events to hardware bridges over UART or USB CDC.
It is the companion backend for bridges like https://github.com/2opremio/PicoUSBKeyBridge
and https://github.com/2opremio/NordicBTKeyBridge.

## What it does

- Keeps a persistent connection to the USB-to-UART adapter.
- Retries forever and logs device output to stdout.
- Exposes a small HTTP API for sending key events.

## Build and run

```
go run ./cmd/keybridged
```

macOS deployment:

```
./scripts/deploy_macos.sh
```

Flags:

- `-host` (default: `localhost`)
- `-port` (default: `8080`)
- `-send-timeout` (default: `2`) seconds to wait when queueing an event
- `-vid` (default: `0x1915`) USB VID for the serial adapter
- `-pid` (default: `0x521F`) USB PID for the serial adapter

If you are using a different bridge firmware (or a non-default USB descriptor),
pass `-vid`/`-pid` explicitly. Example (FT232 default):

```
./keybridged -vid 0x0403 -pid 0x6001
```

## HTTP API

`POST /pressandrelease` sends a single event (press + release). If `type` is
omitted, it defaults to `keyboard`.

Request body:

```
{
  "type": <string> ("keyboard"|"consumer"|"vendor"),
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
  - `"vendor"`: device-specific usages (depends on host support).
- `code` is a HID Usage ID for `keyboard`, or a 16-bit usage for `consumer`/`vendor`.
  For `keyboard`, `code: 0` means "modifier-only" (no key pressed).
- Keyboard modifiers (optional, macOS symbols/Apple names):
  - `left_ctrl` (Ctrl), `left_shift` (Shift), `left_alt`/Option, `left_gui`/Command
  - `right_ctrl`, `right_shift`, `right_alt`/Option, `right_gui`/Command
  - `apple_fn` sets the Apple Fn bit in the keyboard report

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

Vendor usage example (0x0001):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"vendor","code":1}'
```

Send only Apple Fn (modifier-only, no key):

```
curl -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":0,"modifiers":{"apple_fn":true}}'
```

## Client library

There is a small Go client in `client/` for calling the HTTP API.

```
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

Serial protocol documentation lives in https://github.com/2opremio/PicoUSBKeyBridge.
