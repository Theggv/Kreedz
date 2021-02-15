const fs = require('fs');
const { version } = require('../package.json');

const includeFilePath = 'src/include/hwn.inc';
const readmeFilePath = 'README.MD';

function updateInclude() {
  const data = fs.readFileSync(includeFilePath, 'utf8');
  const newData = data.replace(/(#define HWN_VERSION \")(.*?)(\")/g, `$1${version}$3`);
  fs.writeFileSync(includeFilePath, newData);
}

function updateReadme() {
  const data = fs.readFileSync(readmeFilePath, 'utf8');
  const newData = data.replace(/(__Version:__\s)(.*?)(\r\n)/g, `$1${version}$3`);
  fs.writeFileSync(readmeFilePath, newData);
}

updateInclude();
updateReadme();
