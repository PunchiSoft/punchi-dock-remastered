group "default" {
  targets = ["debian13-test"]
}

group "test" {
  targets = ["debian13-test"]
}

target "debian13-test" {
  context    = "."
  dockerfile = "containers/debian13/Dockerfile"
  target     = "artifact"
  output     = ["type=local,dest=dist/docker/debian13"]
}
