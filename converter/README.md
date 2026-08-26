# Phun configuration converter

This is a dependency-free, browser-only converter for the Lua-table configuration files produced by the Phun mods. It does not upload or execute user files.

## GitHub Pages deployment

1. Commit and push the `converter/index.html` folder to the repository's default branch.
2. On GitHub, open **Settings > Pages**.
3. Under **Build and deployment**, choose **Deploy from a branch**.
4. Select the default branch and the `/ (root)` folder, then save.
5. Open the Pages URL followed by `/converter/`.

For the PhunZones repository, the URL should be:

`https://phunzoider.github.io/PhunZones/converter/`

GitHub may take a minute or two to publish the first deployment.

## Testing locally

Open `index.html` directly in a browser, or serve the repository folder with any static web server. No build step or dependency installation is required.

## User migration instructions

1. Back up the existing `.txt` configuration files.
2. Open the converter URL.
3. Select or drag each old configuration file into the **Convert files** area.
4. Download the resulting `.json` file.
5. Place the JSON file where the updated mod's instructions specify.
6. Keep the original `.txt` files until the new configuration has been verified.

The parser intentionally accepts data tables only. It rejects functions, calls, assignments, and expressions. Configurations containing arbitrary Lua logic need to be migrated manually or converted once using the older game/mod version.
