resource "null_resource" "test" {
  triggers = {
    test = "value"
  }
}

resource "random_string" "test" {
  length = 8
}