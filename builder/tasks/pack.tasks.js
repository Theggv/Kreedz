const resolveThirdparty = require('../resolvers/thirdparty.resolver');

const generateReadme = require('../generators/bundle-readme.generator');

const config = require('../resolvers/user-config.resolver');
const constants = require('../constants');

const path = require('path');
const fs = require('fs');

const gulp = require('gulp');
const zip = require('gulp-zip');
const file = require('gulp-file');
const merge2 = require('merge2');

const package = require(
    path.join(process.cwd(), 'package.json')
);

const resolveArchiveName = (sufix) => `hwn-${package.version.replace(/\./g, '')}-${sufix}.zip`;
const resolveBundledDir = (name) => path.join(config.build.bundles.destDir, name);

gulp.task('pack:alliedmods', () => {
    const build = config.build.vanilla || config.build.reapi;

    if (!build) {
        throw new Error('Building config not found!');
    }

    const distDir = build.destDir;

    if (!fs.existsSync(distDir)) {
        throw new Error('Build project before packing');
    }

    const buildDir = resolveBundledDir('alliedmods');

    return merge2(
        gulp.src([
            distDir + '/**',
            '!' + distDir + '/addons{,/**}',
        ])
            .pipe(zip(resolveArchiveName('resources')))
            .pipe(gulp.dest(buildDir)),
        gulp.src([
            distDir + '/addons{,/**}',
            '!' + distDir + '/addons/amxmodx/plugins{,/**}',
            '!' + distDir + '/addons/amxmodx/modules{,/**}',
        ])
            .pipe(zip(resolveArchiveName('addons')))
            .pipe(gulp.dest(buildDir))
    )
});

gulp.task('pack:full', () => {
    const build = config.build.vanilla || config.build.reapi;

    if (!build) {
        throw new Error('Building config not found!');
    }

    const buildDir = resolveBundledDir('full');

    const archiveNames = {
        resources: resolveArchiveName('resources'),
        addons: resolveArchiveName('addons'),
        reapiAddons: resolveArchiveName('addons-reapi'),
        bundle: resolveArchiveName('bundle')
    };

    const tasks = [];

    if (config.build.vanilla) {
        const vanillaDistDir = config.build.vanilla.destDir;

        if (!fs.existsSync(vanillaDistDir)) {
            throw new Error('Build project before packing');
        }

        tasks.push(
            gulp.src([
                vanillaDistDir + '/addons{,/**}',
                resolveThirdparty(constants.roundControlDir) + '/**'
            ])
                .pipe(zip(archiveNames.addons))
                .pipe(gulp.dest(buildDir))
        );
    }

    if (config.build.reapi) {
        const reapiDistDir = config.build.reapi.destDir;

        if (!fs.existsSync(reapiDistDir)) {
            throw new Error('Build ReAPI project before packing');
        }

        tasks.push(
            gulp.src([
                reapiDistDir + '/addons{,/**}'
            ])
                .pipe(zip(archiveNames.reapiAddons))
                .pipe(gulp.dest(buildDir))
        );
    }

    return merge2(
        [
            ...tasks,

            gulp.src([
                build.destDir + '/**',
                '!' + build.destDir + '/addons{,/**}',
            ])
                .pipe(zip(archiveNames.resources))
                .pipe(gulp.dest(buildDir)),

            file('README.TXT', generateReadme(archiveNames), {src: true})
                .pipe(gulp.dest(buildDir))
        ]
    )
        .pipe(zip(archiveNames.bundle))
        .pipe(gulp.dest(buildDir));
});

gulp.task('pack:sdk', () => {
    const buildDir = resolveBundledDir('sdk');
    const sdkArchiveName = resolveArchiveName('sdk');

    return gulp.src([
        config.sdk.dir + '/**'
    ])
        .pipe(zip(sdkArchiveName))
        .pipe(gulp.dest(buildDir));
});

gulp.task('pack', gulp.series('pack:full', 'pack:alliedmods', 'pack:sdk'));
