resource "null_resource" "test" {
  triggers = {
    test = "value"
  }
}