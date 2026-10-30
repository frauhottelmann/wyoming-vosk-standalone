# Wyoming Vosk Standalone
A standalone container for [vosk](https://alphacephei.com/vosk/) using the [wyoming protocol](https://github.com/rhasspy/wyoming). Inspired by [this hass.io addon](https://github.com/rhasspy/hassio-addons/tree/master/vosk).

Images are available for `linux/amd64` and `linux/arm64` (e.g. Raspberry Pi 4/5 with a 64-bit OS).

# Prerequisites
* docker
* docker compose (or another way of starting the container)

# Usage
* download docker compose file
````
wget https://raw.githubusercontent.com/frauhottelmann/wyoming-vosk-standalone/master/docker-compose.yaml
````
* optional: adapt `docker-compose.yaml` to your use-case
* run the container:
````
docker compose up -d
````
A directory called `vosk` will be created in the current folder. Inside that folder are the volumes specified in `docker-compose.yaml`

## Image tags
* `1.5.0`: exact wyoming-vosk version
* `1.5` / `1`: latest image of that minor/major version
* `latest`: most recent release
* `edge`: latest commit on `master` (may be unstable)
* `sha-<commit>`: a specific commit on `master`

## Environment variables
| Variable | Default | Description |
| --- | --- | --- |
| `PRELOAD_LANGUAGE` | `en` | Default language; its model is loaded at startup (and downloaded into `/data` if missing) |
| `CORRECT_SENTENCES` | `0.0` | Score cutoff for correcting transcripts towards the sentences in `sentences/` (0 = strict, higher = less strict) |
| `LIMIT_SENTENCES` | `false` | Only sentences from `sentences/<lang>.yaml` can be recognized |
| `ALLOW_UNKNOWN` | `false` | Return an empty transcript when unknown words are spoken |
| `DEBUG_LOGGING` | `false` | Log debug messages |
| `MODEL_URL` | | URL of a Vosk model zip for `PRELOAD_LANGUAGE`. Downloaded and unpacked into `models/<language>` on first start (see below) |
| `PUID` / `PGID` | `1000` | User and group the server runs as. `data` and `sentences` are handed over to this user at startup |

Boolean variables accept `true`/`false`, `1`/`0`, `yes`/`no` and `on`/`off` (case-insensitive).

The container drops root privileges at startup. Alternatively you can start it directly as an unprivileged user with `user: "1000:1000"` in `docker-compose.yaml`; then the mounted `data` and `sentences` folders must be writable for that user.

## Healthcheck
The image has a built-in healthcheck that sends a Wyoming `describe` request to port `10300` and expects an `info` answer. `docker ps` shows the container as `healthy` once the model is loaded.

# Using it in Home Assistant
* Settings->Integrations->Add Integration: Add the wyoming protocol and add the IP of wherever you are running `Wyoming Vosk Standalone`. The port is `10300`.

# Using a specific model
Other Vosk-Models can be found [here](https://alphacephei.com/vosk/models). Let's say you want to use `vosk-model-de-0.21`, a german model (de).

## Automatically
Set the language and the model URL in `docker-compose.yaml`:
````
      - PRELOAD_LANGUAGE=de
      - MODEL_URL=https://alphacephei.com/vosk/models/vosk-model-de-0.21.zip
````
On the first start the model is downloaded and unpacked into `vosk/models/de`. If that folder already exists, nothing is downloaded. To switch to another model, delete the folder and restart the container. Large models can take a while to download; until the server is up, `docker ps` shows the container as `unhealthy`.

## Manually
* change into the models directory:
````
cd vosk/models
````
* Download the model:
````
wget https://alphacephei.com/vosk/models/vosk-model-de-0.21.zip
````
* Unzip
````
unzip vosk-model-de-0.21.zip
````
* vosk uses the foldername to determine the language:
````
mv vosk-model-de-0.21 de
````
* optional: delete the zip:
````
rm vosk-model-de-0.21.zip
````

# Building locally
````
docker build -t wyoming-vosk-standalone .
````
The wyoming-vosk version can be changed with `--build-arg WYOMING_VOSK_VERSION=<version>`.

# License
MIT, like [wyoming-vosk](https://github.com/rhasspy/wyoming-vosk). See [LICENSE](LICENSE).

# Note
Pull requests and ideas/feature requests are always welcome!
