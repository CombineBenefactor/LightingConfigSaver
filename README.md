# LightingConfigSaver

A lightweight Roblox Studio plugin that allows you to save and restore lighting configurations with ease.

LightingConfigSaver makes it easy to experiment with different lighting setups without losing your previous configurations. Save your current Lighting properties into a configuration object and load them again whenever you need them.

## Features

- **Save Lighting Configurations** – Save your current Lighting settings into a Configuration instance.
- **Load Lighting Configurations** – Restore previously saved lighting settings with a single click.
- **Multiple Configurations** – Store multiple lighting configurations within the same place.
- **Automatic Naming** – Saved configurations are automatically named.
- **Undo Support** – Saving and loading configurations creates ChangeHistory waypoints, allowing you to undo changes.
- **Selection Validation** – Prevents loading invalid objects or multiple configurations simultaneously.
- **Visual Feedback** – Displays notifications when an invalid selection is made.

## Installation

1. Download `LightingConfigSaver.rbxmx` from the [Releases](https://github.com/CombineBenefactor/LightingConfigSaver/releases) section.
2. Open Roblox Studio.
3. Navigate to the **Plugins** tab.
4. Click **Plugins Folder** to open your local Roblox Studio plugins directory.
5. Move or copy `LightingConfigSaver.rbxmx` into the opened folder.
6. Restart Roblox Studio.

After restarting Studio, the plugin should appear in the Plugins toolbar under **Lighting Saver**.

## Usage

### Saving a Lighting Configuration

1. Open your Roblox Studio project.
2. Configure the Lighting service to your desired settings.
3. Navigate to the **Plugins** tab.
4. Under **Lighting Saver**, click **Save Lighting**.

The plugin will automatically:
- Create a new `Configuration` instance inside `Lighting`.
- Store the current Lighting properties as attributes on that instance.
- Assign an automatically generated name (`OldLightingConfig`, `OldLightingConfig1`, etc.).
- Select the newly created configuration in Explorer.

Your configuration is now saved within your place.

### Loading a Lighting Configuration

1. Open the **Explorer** window.
2. Expand the `Lighting` service.
3. Locate the configuration you want to load.
4. Select exactly one configuration object.
5. Navigate to **Plugins** → **Lighting Saver**.
6. Click **Load Lighting**.

The plugin will validate the selected object and restore its saved properties to the Lighting service.

If the selection is invalid, a notification will explain the issue.

### Managing Multiple Configurations

You can save as many configurations as you need.

All saved configurations are stored as `Configuration` instances directly under the `Lighting` service.

For example:

```text
Lighting
├── OldLightingConfig
├── OldLightingConfig1
├── OldLightingConfig2
└── OldLightingConfig3
```

You can rename, duplicate, or delete these instances directly through Explorer.

**Important:** Configurations are stored inside your place, not externally. Make sure to save or publish your place to preserve them.

## Supported Properties

LightingConfigSaver currently saves and restores the following properties:

| Property | Description |
|---|---|
| `Ambient` | Ambient lighting color |
| `Brightness` | Overall lighting brightness |
| `ColorShift_Bottom` | Bottom color shift |
| `ColorShift_Top` | Top color shift |
| `EnvironmentDiffuseScale` | Environmental diffuse contribution |
| `EnvironmentSpecularScale` | Environmental specular contribution |
| `ExposureCompensation` | Exposure adjustment |
| `FogColor` | Fog color |
| `FogEnd` | Distance at which fog reaches full opacity |
| `FogStart` | Distance at which fog begins |
| `GeographicLatitude` | Geographic latitude used for sun positioning |
| `GlobalShadows` | Enables or disables global shadows |
| `LightingStyle` | Lighting technology/style |
| `OutdoorAmbient` | Outdoor ambient lighting color |
| `ShadowSoftness` | Shadow softness |
| `TimeOfDay` | Time of day |
| `ClockTime` | Numerical time of day |
| `PrioritizeLightingQuality` | Prioritizes lighting quality |

## Important Notes

- Only the properties listed above are saved. Other Lighting properties and child instances, such as Atmosphere, Sky, BloomEffect, and ColorCorrectionEffect, are not included.
- Loading a configuration overwrites the corresponding properties in the current Lighting service.
- You must select exactly one configuration to load.
- Configuration objects must retain their saved attributes to be considered valid.
- Changes can be undone using Roblox Studio's undo functionality.

## Source Code

The complete plugin source code is available here:

[View LightingConfigSaver source](https://github.com/CombineBenefactor/LightingConfigSaver/blob/main/source.lua)
