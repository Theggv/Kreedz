const ARCHIVE_NAME_MAXLEN = 32;
const JOIN_STR = '\r\n';
const INDENT = '    ';

const INSTALLATION_TEXT = 'Extract addons and resources to cstrike folder';

const ARCHIVES_DESCRIPTION = {
  addons: 'addons for vanilla server',
  reapiAddons: 'addons for ReAPI',
  resources: 'resources'
};

function getFilesList(prefix, archiveNames) {
  return Object.keys(ARCHIVES_DESCRIPTION).map(key => {
    if (!archiveNames[key]) {
      return;
    }

    const spaces = ' '.repeat(ARCHIVE_NAME_MAXLEN - archiveNames[key].length);

    return `${prefix}${archiveNames[key]}${spaces} - ${ARCHIVES_DESCRIPTION[key]}`
  }).filter(str => !!str).join(JOIN_STR);
}

module.exports = (archiveNames) => [
  '[INSTALLATION]',
  `${INDENT}${INSTALLATION_TEXT}`,
  '',
  '[FILES]',
  getFilesList(INDENT, archiveNames)
].join(JOIN_STR);
