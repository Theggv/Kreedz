module.exports = {
  initialize: () => {
    require('./tasks/build.tasks.js');
    require('./tasks/pack.tasks.js');
  }
};
