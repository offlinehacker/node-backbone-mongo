var mongoose = require('mongoose'),

TodoSchema = new mongoose.Schema({
  title: { 'type': String, 'default': 'empty todo...' },
  order: { 'type': Number },
  done: { 'type': Boolean, 'default': false },
  user: { 'type': String }
});

module.exports = mongoose.model('Todo', TodoSchema);
