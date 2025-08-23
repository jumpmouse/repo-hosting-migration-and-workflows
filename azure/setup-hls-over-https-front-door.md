---
description: Configure HTTPS delivery for HLS video via Azure Front Door, then point API to use it
---

# Objective
Serve video assets (HLS .m3u8) over HTTPS without changing origin VM by placing Azure Front Door in front of the Flussonic server and updating the API configuration to output the new HTTPS host.

# Prerequisites
- You can access Azure Portal with permissions to create Front Door and edit App Service configuration.
- The origin VM (Flussonic) is reachable on HTTP port 80 at land-of-tales.westeurope.cloudapp.azure.com.
- App Service (API) already has:
  - FlussonicSettings:VideoPathPublic = <confirmed value>
  - FlussonicSettings:VideoPathPrivate = <confirmed value>

# Terms used below
- FRONT_DOOR_PROFILE: A new Front Door profile you’ll create (e.g., `lot-media-fd`).
- FRONT_DOOR_ENDPOINT: The generated endpoint host, e.g., `lot-media-fd.azurefd.net`.
- ORIGIN_HOST: `land-of-tales.westeurope.cloudapp.azure.com`.
- FE_ORIGIN: Your frontend site origin (scheme + host, e.g., `https://app.example.com`). Use `*` only for initial testing.

# Steps

1) Create Front Door profile and endpoint
- Azure Portal → search "Front Door and CDN profiles" → Create.
- SKU: Standard Microsoft.
- Profile name: FRONT_DOOR_PROFILE (e.g., `lot-media-fd`).
- Frontend endpoint name: same base (you’ll get `https://FRONT_DOOR_ENDPOINT`).
- Review + Create → Create.

2) Origin group (use default or create one)
- Open the profile → Origin groups.
- If `default-origin-group` exists, use it. Otherwise click + Add origin group and create `flussonicgroup` (letters/numbers only).
- Health probe: Protocol = HTTP, Path = `/`, Interval = 30s (defaults OK).
- Save.

3) Add Origin (the Flussonic VM)
- In the same profile → Origin groups → open your origin group → + Add an origin.
- Origin type: Custom.
- Origin host name: ORIGIN_HOST (`land-of-tales.westeurope.cloudapp.azure.com`).
- Origin host header: same as host name.
- HTTP port: 80.
- HTTPS port: 443 (UI requires a value even if we won’t use HTTPS to origin).
- Status: Enable this origin (checked). Priority/Weight defaults are fine.
- Save. Wait ~30–60s and confirm origin health is Healthy.

4) Create Route for all content
- Profile → Routes → + Add route (or Edit the existing one).
- Frontend domain: select `FRONT_DOOR_ENDPOINT`.
- Patterns to match: `/*`.
- Origin group: your origin group (default-origin-group or flussonicgroup).
- Accepted protocols (client): enable HTTPS; if HTTP is enabled, turn on "Redirect HTTP to HTTPS".
- Forwarding protocol (to origin): HTTP only.
- Caching: Off (can tune later).
- Save.

5) Add CORS headers at the edge (Rules Engine)
- Profile → Rule sets → + Add. Names must use only letters/numbers (e.g., `corshls`).
- Open the rule set and create rules in this order (lower number = higher priority):
  1. Rule `allowUatWeb`
     - Condition: Request header → Name `Origin` → Operator `Equals` → Value `https://lot-uat3-web.azurewebsites.net`.
     - Action: Response header → Overwrite `Access-Control-Allow-Origin` = `https://lot-uat3-web.azurewebsites.net`.
  2. Rule `allowProdRoot`
     - Condition: Origin Equals `https://landoftales.com`.
     - Action: Overwrite `Access-Control-Allow-Origin` = `https://landoftales.com`.
  3. Rule `allowProdWww`
     - Condition: Origin Equals `https://www.landoftales.com`.
     - Action: Overwrite `Access-Control-Allow-Origin` = `https://www.landoftales.com`.
  4. Rule `addcors` (base headers applied to all)
     - No conditions.
     - Actions (Response header, Operator Overwrite):
       - `Access-Control-Allow-Methods` = `GET, HEAD, OPTIONS`.
       - `Access-Control-Allow-Headers` = `*`.
       - `Access-Control-Expose-Headers` = `*`.
       - `Access-Control-Max-Age` = `86400`.
       - Optional: `Vary` = `Origin`.
- Important: In the Rule sets list, click "Associate a route" and select your endpoint and route, then Save. Wait ~3–5 minutes for propagation.

6) Test the Front Door endpoint
- Build a test URL by replacing only the host with `FRONT_DOOR_ENDPOINT`:
  - `https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8`
- From your Mac terminal (replace placeholders):
  - /bin/zsh -i -c 'curl -Iv https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8'
  - Preflight test (CORS):
    - /bin/zsh -i -c 'curl -i -X OPTIONS -H "Origin: https://lot-uat3-web.azurewebsites.net" -H "Access-Control-Request-Method: GET" https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8'
- Expect: `HTTP/2 200` (or 206) and the CORS headers present including the correct `Access-Control-Allow-Origin`.

7) Point the API to use Front Door
- Azure Portal → App Services → open your API (e.g., `lot-uat3-api`).
- Configuration → Application settings → Add/Update:
  - Key: `FlussonicSettings:BaseUrl`
  - Value: `https://FRONT_DOOR_ENDPOINT`
- Ensure the path keys exist (do not change):
  - `FlussonicSettings:VideoPathPublic` (e.g., `uat3_public`)
  - `FlussonicSettings:VideoPathPrivate` (e.g., `uat3_private`)
- Save (App Service will restart).
 - Notes:
   - `LoT.Logic/Mappings/FileProfile.cs` composes `FileDto.StreamUrl` using these keys.
   - App Service Application settings override values in `appsettings.json` at runtime.
   - Optional (local dev): Set `FlussonicSettings:BaseUrl` in `LoT.Api/appsettings.Development.json` to test Front Door locally.

8) Verify API responses
- Call an API that returns assets (FileDto). Verify `streamUrl` host is now `FRONT_DOOR_ENDPOINT` and uses HTTPS.
- Open the `streamUrl` in a browser and/or in your video player.

9) Verify in the browser (end-to-end)
- Load the frontend over HTTPS.
- DevTools → Network → confirm the m3u8/segment requests go to `FRONT_DOOR_ENDPOINT` via HTTPS, and there are no mixed-content errors.

10) Optional hardening (after success)
- Limit NSG inbound to Front Door origin IPs only (Azure publishes lists; apply with care).
- Turn on caching for segments under `/.../*.ts` paths if appropriate.
- Replace `*` in `Access-Control-Allow-Origin` with the exact FE origin if you used `*` during testing.

# Troubleshooting
- 403 or 404 via Front Door: check Origin host header matches ORIGIN_HOST and that origin path exists.
- CORS shows `access-control-allow-origin: https://` only: ensure you created per-origin rules with the correct `Origin Equals` value and that the rule set is associated to the route.
- Rule set changes have no effect: verify you clicked "Associate a route" after saving the rule set.
- Manifest issues: If `.m3u8` contains absolute `http://` URLs, configure Flussonic to emit relative or https links.

# Quick Test Commands (replace placeholders)
- /bin/zsh -i -c 'curl -Iv https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8'
- /bin/zsh -i -c 'curl -i -X OPTIONS -H "Origin: https://lot-uat3-web.azurewebsites.net" -H "Access-Control-Request-Method: GET" https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8'
- /bin/zsh -i -c 'curl -s https://FRONT_DOOR_ENDPOINT/<VideoPathPublic>/<fileName>/index.m3u8 | head -n 20'
