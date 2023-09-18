const mongoose = require("mongoose");
try {
  mongoose.connect(process.env.DATA, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useCreateIndex: true,
  });
  console.log("Database Connected Successfully");
} catch (err) {
  console.log("Database Not Connected");
}
export default connectDB;