require('package-script').spawn([
  {
    command: "npm",
    args: ["install", "-g", "nodemon"]
  },
  {
    command: "npm",
    args: ["install", "-g", "elm"]
  }
]);