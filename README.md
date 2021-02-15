![Alt Text](./images/demo.gif)
### Halloween Mod for Counter-Strike 1.6
__Version:__ 6.3.0

### What is Halloween Mod?
Halloween mod is a powerful Halloween-themed core for your server with completely new game modes, NPCs, bosses, spells, cosmetics, and more.

### Download latest:
- [Releases](./releases)

### Documentation
- [Index](./doc/pages/index.md)

### Special Thanks:
- [Credits](./CREDITS.md)

### Deployment
- Clone repository.
- Extract compiler executable and includes to _"compiler"_ folder of project.
- Extract RoundControl module to _"thirdparty/round-control"_ folder of project (example: _"thirdparty/round-control/addons"_).
- Extract ReAPI module to _"thirdparty/reapi"_ folder of project (example: _"thirdparty/reapi/addons"_).
- Install dependencies `npm i`

#### Customize builder
Use `config.user.js` file (Generated automatically on dependencies install)

#### Build project

```bash
npm run build
```

#### Watch project

```bash
npm run watch
```

#### Create bundle

```bash
npm run pack
```
