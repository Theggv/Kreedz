const fs = require('fs');
const path = require('path');

const configFilename = path.join(__dirname, '../config.js');
const userConfigFilename = path.join(process.cwd(), 'config.user.js');

const resolvedConfig = {};

if (fs.existsSync(userConfigFilename)) {
    const config = require(configFilename);
    const userConfig = require(userConfigFilename);

    if (config.version !== userConfig.version) {
        console.warn('The version of your config is differs from the version of builder config! Try to merge.');
        Object.assign(resolvedConfig, config, userConfig);
    } else {
        Object.assign(resolvedConfig, require(userConfigFilename));
    }
} else {
    fs.writeFileSync(userConfigFilename, fs.readFileSync(configFilename));
    Object.assign(resolvedConfig, require(userConfigFilename));
}

module.exports = resolvedConfig;
