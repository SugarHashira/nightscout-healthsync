# NightscoutHealthSync

**Sync your Nightscout diabetes data to Apple Health**

An iOS app that bridges the gap between your Nightscout instance and Apple Health, bringing all your diabetes data (glucose, insulin, carbs) together with your other health metrics.

## The Ecosystem

Before diving into setup, here's the full picture of how your diabetes data flows:

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TANDEM t:slim X2                                  │
│                         (Insulin Pump + Control-IQ)                         │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            TANDEM MOBILE APP                                │
│                      (Remote bolusing & data upload)                        │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        t:connect WEB SERVICE                                │
│                   (Tandem's cloud - yourdata.t:connect.com)                 │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NIGHTSCOUT                                        │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │  Pulls data from t:connect (via other projects listed below)    │     │
│    │  Provides REST API for apps to consume                          │     │
│    │  Web UI for glucose visualization                               │     │
│    │  Pushover, IFTTT, and other integrations                        │     │
│    └─────────────────────────────────────────────────────────────────┘     │
│                              Hosted on: Fly.io                              │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NIGHTSCOUNTHEALTHSYNC                              │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │  Fetches treatments (insulin, carbs) from Nightscout           │     │
│    │  Fetches glucose entries from Nightscout                       │     │
│    │  Syncs everything to Apple Health via HealthKit               │     │
│    └─────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            APPLE HEALTH                                     │
│     Now you can see all your data in one place and use other apps!         │
│     Glucose + Insulin + Carbs + Sleep (Oura) + Activity + Heart Health     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Related Projects

Here's everything needed to get this working:

### 1. Nightscout (nightscout.github.io)

**What it does:** Open-source diabetes data visualization platform
- Hosts your CGM data, insulin deliveries, and treatments
- Provides a REST API for external apps
- Web dashboard for viewing trends

**Website:** https://nightscout.github.io/
**GitHub:** https://github.com/nightscout/cgm-remote-monitor

### 2. Getting t:slim X2 Data to Nightscout

There are several approaches:

#### Option A: Tidepool
- Upload pump data to Tidepool, then Nightscout can pull from there
- https://tidepool.org

#### Option B: t:connect integration
- Check the Nightscout documentation for "Tandem" or "t:connect" setup
- Some users have created custom integrations for this

#### Option C: xDrip+ (for CGM data)
- If using Dexcom, xDrip+ can upload directly to Nightscout
- https://github.com/NightscoutFoundation/xDrip

### 3. Hosting

#### Fly.io (Recommended - Used in this setup)
- Fast, reliable, Docker-based hosting
- Free tier available
- Setup guide: https://nightscout.github.io/nightscout/fly/

#### Heroku (Alternative)
- Classic choice for Nightscout
- Note: Free tier was discontinued in late 2022
- Setup guide: https://nightscout.github.io/nightscout/heroku/

### 4. Dexcom CGM Integration

If you're using a Dexcom CGM:
- **Dexcom Follow** - Share data with Nightscout
- **xDrip+** - Open-source Android app that uploads to Nightscout
- **Spike** - iOS app alternative (limited availability)

## Prerequisites

Before using NightscoutHealthSync:

1. ✅ **A Nightscout instance** deployed and accessible
2. ✅ **Your t:slim X2 data** flowing into Nightscout
3. ✅ **Nightscout REST API enabled** (setting: `API_SECRET`)
4. ✅ **iOS 16+ device** (iPhone or iPad)
5. ✅ **Apple Health** app installed

## Setup

### 1. Configure Nightscout API

In your Nightscout settings (environment variables), ensure:

```
API_SECRET=your_secret_here
ENABLE=api
```

### 2. Install the App

```bash
# Clone the repository
git clone https://github.com/yourusername/nightscout-healthsync.git

# Open in Xcode
open NightscoutHealthSync.xcodeproj

# Build and run on your device
```

### 3. Configure the App

1. Open the app
2. Go to **Settings** (gear icon)
3. Enter your **Nightscout URL** (e.g., `https://your-nightscout.fly.dev`)
4. Enter your **API Secret**
5. Tap **Test Connection** to verify
6. Tap **Request HealthKit Authorization**
7. Choose what to sync:
   - Glucose Readings
   - Insulin Deliveries
   - Carbohydrates

### 4. Start Syncing

- Tap **Sync Now** to manually trigger a sync
- Enable **Auto-sync in background** for automatic periodic syncs

## Features

- **Selective Sync** - Choose which data types to sync
- **Deduplication** - Won't sync the same data twice
- **Background Sync** - Automatic syncing at intervals you choose (5 min to 2 hours)
- **Sync Logs** - See exactly what was synced and when
- **mg/dL or mmol/L** - Support for both glucose units

## What Gets Synced

| Data Type | HealthKit Type |
|-----------|---------------|
| Glucose | Blood Glucose |
| Insulin (Bolus) | Insulin Delivery (Bolus) |
| Insulin (Basal) | Insulin Delivery (Basal) |
| Carbs | Dietary Carbohydrates |

## Troubleshooting

### "Connection failed"
- Verify your Nightscout URL is correct
- Ensure your API secret matches exactly
- Check that your Nightscout instance is running

### "HealthKit authorization denied"
- Go to iOS Settings > Privacy & Security > Health > NightscoutHealthSync
- Allow access to Health data

### Data not appearing in Apple Health
- Check that you granted write permissions for each data type
- Verify sync completed successfully (check Sync Logs)

## Future Plans

- Apple Watch app for quick sync status
- Watch complications for glucose display
- Correlate diabetes data with sleep/activity from Oura Ring
- Home screen widgets

## Tech Stack

- **SwiftUI** - Modern declarative UI
- **HealthKit** - Apple Health integration
- **Swift Concurrency** - async/await and actors
- **iOS 16+** - Minimum deployment target

## Disclaimer

This app is for informational purposes. Always consult with your healthcare provider about diabetes management decisions. The developer is not responsible for any medical decisions made based on data from this app.

## License

MIT License - See LICENSE file for details
