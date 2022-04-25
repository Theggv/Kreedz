const path = require('path');
const fs = require('fs');
const gulp = require('gulp');
const zip = require('gulp-zip');
const file = require('gulp-file');
const merge2 = require('merge2');

const package = require('./package.json');

const WORK_DIR = process.cwd();
const DIST_DIR = path.join(WORK_DIR, './dist');
const BUILD_DIR = path.join(DIST_DIR, 'bundles');

if (!fs.existsSync(DIST_DIR)) {
  throw new Error('Build ReAPI project before packing');
}

const resolveArchiveName = (suffix) =>
  `${package.name}-${package.version.replace(/\./g, '')}-${suffix}.zip`;

const FILES = {
  bundleArchive: resolveArchiveName('bundle'),
  addonsArchive: resolveArchiveName('addons'),
  resourcesArchive: resolveArchiveName('resources'),
};

const BUNDLE_FILES = [
  { name: FILES.addonsArchive },
  { name: FILES.resourcesArchive },
];

gulp.task('pack:bundles', () => {
  const dirPatterns = {
    all: DIST_DIR + '/**',
    addons: DIST_DIR + '/addons{,/**}',
  };

  return merge2([
    gulp.src([dirPatterns.addons]).pipe(zip(FILES.addonsArchive)),
    gulp
      .src([dirPatterns.all, '!' + dirPatterns.addons])
      .pipe(zip(FILES.resourcesArchive)),
  ]).pipe(gulp.dest(BUILD_DIR));
});

gulp.task('pack:full', () => {
  const bundleFiles = BUNDLE_FILES.map((file) =>
    path.join(BUILD_DIR, file.name)
  );

  return gulp
    .src(bundleFiles)
    .pipe(zip(FILES.bundleArchive))
    .pipe(gulp.dest(BUILD_DIR));
});

gulp.task('default', gulp.series('pack:bundles', 'pack:full'));
