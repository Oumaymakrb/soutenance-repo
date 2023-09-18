const mongoose = require("mongoose");
const request = require("supertest");
const app = require('./app.js');


describe('Backend API', function () {
  this.timeout(5000);

  it('should establish a successful database connection', function (done) {
    mongoose
      .connect('mongodb+srv://admin:admin@cluster0.ltqy7qz.mongodb.net/test2?retryWrites=true&w=majority', {
        useNewUrlParser: true,
        useUnifiedTopology: true,
        useCreateIndex: true,
      })
      .then(() => {
        console.log('Database connection successful');
        done();
      })
      .catch((error) => {
        console.error('Database connection error:', error);
        done(error);
      });
  });


});





