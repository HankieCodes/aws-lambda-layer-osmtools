# aws-lambda-layer-osmtools

OpenStreetMap C++ tools available as an AWS Lambda Layer!

Run [Open Source Routing Machine](https://github.com/Project-OSRM/osrm-backend),
[Osmium](https://github.com/osmcode/osmium-tool), and [Tilemaker](https://github.com/systemed/tilemaker) in AWS Lambda
with precompiled C++ binaries ready to run on Amazon Linux 2023 (used by most Lambda runtimes).

## Usage

1. Open the [Releases](https://github.com/hnryjms/aws-lambda-layer-osmtools/releases) page and find the latest release.
2. Copy the corresponding `Layer ARN` for your AWS Region.
   1. All tools require the `-base` layer.
   1. Then combine individual tools as additional layers.
3. In `AWS Console > Lambda > (function) > Code > Layers`, paste this `Layer ARN`.
4. Save your function :)

| Layer | CLI Tools | Packages |
| ----- | --------------- | -- |
| `-base` | N/A  | N/A |
| `-osrm` | <ul><li>`osrm-components`</li><li>`osrm-contract`</li><li>`osrm-customize`</li><li>`osrm-datastore`</li><li>`osrm-extract`</li><li>`osrm-partition`</li><li>`osrm-routed`</li></ul> | <ul><li>NodeJS: `@project-osrm/osrm`</li></ul> |
| `-osmium` | <ul><li>`osmium`</li></ul> | None |
| `-tilemaker` | <ul><li>`tilemaker`</li></ul> | None |

You can confirm your app is ready with an example handler like:

### NodeJS:

Ensure `@project-osrm/osrm` is marked as [`external`](https://esbuild.github.io/api/#external) in your bundling tools.

```js
import OSRM from "@project-osrm/osrm";
import ChildProcess from "node:child_process";

export const handler = async (event) => {
  console.log(OSRM.version);
  ChildProcess.execSync("osmium --version", { stdio: "inherit" });
  ChildProcess.execSync("osrm-customize --version", { stdio: "inherit" });
  ChildProcess.execSync("tilemaker --help", { stdio: "inherit" });


  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda!'),
  };
  return response;
};
```

## To Do

- [ ] Add other runtime support (mainly CLI-only option)

## Support

This project is a part of my larger work on [Skyway.run](https://skyway.run), an indoor navigation app. If you find
`aws-lambda-layer-osmtools` useful on your project, let me know and I can list you here.

Contributors or sponsors very welcome :)
