const gulp = require('gulp');
const watch = require('gulp-watch');
const sma = require('gulp-sma');
const flatten = require('gulp-flatten');

const resolveTaskName = (task, name) => `${task}:${name}`;

module.exports = (name, options) => {
	if (typeof options === 'function') {
		options = options();
	}

	const gulpMethod = options.watch === true ? watch : gulp.src;
	const gulpOptions =
		options.watch === true
			? { ignoreInitial: !!options.ignoreInitial }
			: undefined;

	const resolvedTasks = [];

	if (
		!options.tasks ||
		options.tasks.plugins !== false ||
		options.tasks.src !== false
	) {
		const taskName = resolveTaskName(name, 'plugins');

		gulp.task(taskName, () => {
			let pluginTask = gulpMethod('./src/scripts/**/*.sma', gulpOptions);

			if (!options.tasks || options.tasks.plugins !== false) {
				pluginTask = pluginTask.pipe(sma(options.smaConfig));
			}

			if (!options.tasks || options.tasks.src !== false) {
				pluginTask = pluginTask
					.pipe(flatten())
					.pipe(gulp.dest(options.dest.scriptsDir));
			}

			return pluginTask;
		});

		resolvedTasks.push(taskName);
	}

	if (!options.tasks || options.tasks.src !== false) {
		const taskName = resolveTaskName(name, 'include');

		gulp.task(taskName, () => {
			return gulpMethod('./src/include/*.inc', gulpOptions).pipe(
				gulp.dest(options.dest.includeDir)
			);
		});

		resolvedTasks.push(taskName);

		gulp.task(taskName, () => {
			return gulpMethod('./src/include/kreedz/*.inc', gulpOptions).pipe(
				gulp.dest(options.dest.includeDir + '/kreedz')
			);
		});

		resolvedTasks.push(taskName);
	}

	if (!options.tasks || options.tasks.assets !== false) {
		const taskName = resolveTaskName(name, 'assets');

		gulp.task(taskName, () => {
			return gulpMethod('./assets/**/*', gulpOptions).pipe(
				gulp.dest(options.dest.dir)
			);
		});

		resolvedTasks.push(taskName);
	}

	gulp.task(name, gulp.parallel(...resolvedTasks));
};
