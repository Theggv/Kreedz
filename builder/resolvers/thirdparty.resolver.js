const fs = require('fs');
const path = require('path');

const config = require('./user-config.resolver');
const constants = require('../constants');

const resolveThirdparty = (relativepPath) =>
	path.join(config.thirdparty.dir, relativepPath);

const compilerRelative = path.relative(process.cwd(), config.compiler.dir);

if (!fs.existsSync(config.compiler.executable)) {
	throw new Error(
		`extract amxxpc compiler to "${compilerRelative}" directory`
	);
}

module.exports = resolveThirdparty;
