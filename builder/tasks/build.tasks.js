const path = require('path');

const gulp = require('gulp');

const resolveThirdparty = require('../resolvers/thirdparty.resolver');
const config = require('../resolvers/user-config.resolver');

const buildTaskFactory = require('../factories/build-task.factory');

const constants = require('../constants');

const resolveDestConfig = (destDir) => ({
	dir: destDir,
	includeDir: path.join(destDir, 'addons/amxmodx/scripting/include'),
	pluginsDir: path.join(destDir, 'addons/amxmodx/plugins'),
	scriptsDir: path.join(destDir, 'addons/amxmodx/scripting'),
});

const buildTasks = [];
const watchTasks = [];

// ReAPI server

if (config.build.reapi) {
	const reapiDestConfig = resolveDestConfig(config.build.reapi.destDir);
	const reapiSmaConfig = {
		compiler: config.compiler.executable,
		dest: reapiDestConfig.pluginsDir,
		includeDir: [
			resolveThirdparty(
				`${constants.reapiDir}/addons/amxmodx/scripting/include`
			),
			config.project.includeDir,
		],
	};

	buildTaskFactory('watch:reapi', {
		smaConfig: Object.assign({}, reapiSmaConfig, { ignoreError: true }),
		dest: reapiDestConfig,
		watch: true,
		ignoreInitial: true,
	});

	buildTaskFactory('build:reapi', {
		smaConfig: reapiSmaConfig,
		dest: reapiDestConfig,
	});

	buildTasks.push('build:reapi');
	watchTasks.push('build:reapi');
	watchTasks.push('watch:reapi');
}

// final tasks

gulp.task('build', gulp.series(...buildTasks));
gulp.task('watch', gulp.parallel(...watchTasks));
