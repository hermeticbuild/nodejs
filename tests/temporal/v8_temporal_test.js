if (typeof Temporal !== "object") {
  throw new Error("Temporal is not available");
}

const epoch = Temporal.Instant.fromEpochMilliseconds(0);
if (epoch.toString() !== "1970-01-01T00:00:00Z") {
  throw new Error(`unexpected Temporal.Instant value: ${epoch}`);
}
