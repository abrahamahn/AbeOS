🔥 AbeOS Performance Profiles (Final 4 Modes)

Each mode controls:

GPU Mode (Hybrid / Ultimate / Eco)

CPU Power Limits (PPT/EDC/TDC)

Fan Curve

Audio Routing

Display/Refresh Rate

NVIDIA Control Panel (optional profiles)

Background Services

Latency Mode / Scheduler Priority

System Color/Effects

Power Plan

OBS / DAW / IDE optimization

Memory compression, standby management

G-Helper ACPI toggles

1️⃣ Streamer Mode

Goal: Stable 1080p60 (or 1440p) streaming + gameplay + zero stutters.

GPU:

Ultimate (dGPU-only)

MUX enabled (if available)

Prefer max GPU power

CPU:

Balanced (not max) to avoid thermal spikes

PPT reduced slightly to stabilize temps

Fans:

Performance (medium-high)

Keep GPU under 75°C for encoder stability

Audio:

Create “STREAM MIX” via Voicemeeter or Windows routing

Prioritize OBS audio chain

Enable low-buffer monitoring

OBS Specific:

NVENC encoder profile: P5 or P6

Look-ahead OFF

Psycho-visual tuning ON

Max pre-rendered frames lowered to 1

Display:

144Hz/165Hz to reduce input latency

Disable VRR during stream (VRR causes capture flicker)

Services Disabled:

Windows GameDVR

Xbox Game Bar

Background indexing

Ideal Use:
Streaming Valorant / Elden Ring / Fortnite while keeping stream clean.

2️⃣ Music Production Mode

Goal: Minimum audio latency & zero crackles, even with 100 tracks in Ableton/FL Studio.

GPU:

Hybrid Mode (GPU isn’t important for DAWs)

Keep dGPU idle to reduce DPC latency

CPU:

Sustained & stable

PPT lowered (to reduce spikes)

C-states limited (to reduce latency issues)

Turbo Boost partially disabled (optional)

Fans:

Silent or Standard (DAWs don’t need cooling spikes)

Audio:

ASIO device priority

Disable all spatial audio

Disable all enhancements

Prioritize audio processes in MMCSS (ASIO Guard)

System tweaks:

Disable WiFi power saving

Disable Windows Scheduled Tasks that wake CPU

Core Isolation OFF

Windows USB Power Mgmt OFF (for MIDI controllers)

Display:

60Hz or 120Hz (depending on crackles)

Ideal Use:
FL Studio / Ableton / Recording vocals / Guitar Rig / Kontakt / Omnisphere.

3️⃣ Gaming Mode

Goal: Maximum FPS with quiet fans, and reduced CPU heat for comfortable gaming.

GPU:

Ultimate Mode (dGPU-only)

Allow full GPU clocking

CPU:

Limit PPT to reduce fan noise

Restrict CPU boosting to avoid thermal throttling

Keep temperatures under 85°C

Fans:

Quiet or Medium (custom fan curve)

Audio:

Use WASAPI (low CPU)

Disable Virtual Audio routing

Display:

Max refresh rate (165Hz)

VRR ON (gaming)

NVIDIA tweaks:

Low Latency Mode ON

Max pre-rendered frames: 1

Prefer maximum performance (or Optimal)

Disable background recording

Services disabled:

OneDrive

Windows Update

Defender real-time scanning (optional gaming-only toggle)

Ideal Use:
Elden Ring / Cyberpunk / RDR2 / Witcher 3 / Valorant / Apex.

4️⃣ Work Mode

Goal: Battery health + quiet fans + fast coding environment + stable performance.

GPU:

Eco Mode (iGPU-only) → huge battery gain

dGPU fully off

CPU:

Balanced power plan

Limit PPT for lower heat

Enable all C-states (for efficiency)

Fans:

Quiet mode

Display:

Bright screen allowed (you prefer that)

60Hz refresh to save battery

Memory & OS:

Enable Memory Compression

Enable Standby Cache trimming

Disable Game Bar

Disable Xbox Services

Disable heavy background tasks (Photos indexing, Widgets, Telemetry)

Developer Tools Optimized:

Node/Python env prioritized

Docker GPU passthrough OFF

WSL2 in low-power mode

VSCode tweaks:

GPU acceleration OFF

Editor smooth scrolling ON

Animations reduced

Ideal Use:
Coding in VS Code, Docker microservices, debugging, browsing, running AI models locally (optional hybrid).
